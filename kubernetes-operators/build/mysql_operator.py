"""Mysql operator.
"""

import time
import logging
import yaml
import kopf
import kubernetes
from jinja2 import Environment, FileSystemLoader


def wait_until_job_end(jobname):
    """Wait until k8s batch job ended
    :param jobname: job name
    :type: str
    """
    api = kubernetes.client.BatchV1Api()
    job_finished = False
    jobs = api.list_namespaced_job('default')
    while (not job_finished) and \
            any(job.metadata.name == jobname for job in jobs.items):
        time.sleep(1)
        jobs = api.list_namespaced_job('default')
        for job in jobs.items:
            if job.metadata.name == jobname:
                print(f"job with { jobname }  found,wait untill end")
                if job.status.succeeded == 1:
                    print(f"job with { jobname }  success")
                    job_finished = True


def render_template(filename, vars_dict):
    """Render template from templates directory.
    :param `filename`: path to jinja2 template.
    :type arg: str
    :param `vars_dict`: render configuration dictionary.
    :type arg: dict
    :return: json manifest
    """
    env = Environment(loader=FileSystemLoader('./templates'))
    template = env.get_template(filename)
    yaml_manifest = template.render(vars_dict)
    json_manifest = yaml.load(yaml_manifest)
    return json_manifest


def delete_success_jobs(mysql_instance_name):
    """Delete k8s batch job if it's succeeded
    :param mysql_instance_name: name of mysql instance related to that job
    :type: str
    """
    logging.info("start deletion")
    api = kubernetes.client.BatchV1Api()
    jobs = api.list_namespaced_job('default')
    for job in jobs.items:
        jobname = job.metadata.name
        if jobname in (f"backup-{mysql_instance_name}-job",
                       f"restore-{mysql_instance_name}-job",
                       f"passwd-{mysql_instance_name}-job"):
            if job.status.succeeded == 1:
                logging.info("Find '%s' job, try to delete it", jobname)
                api.delete_namespaced_job(jobname,
                                          'default',
                                          propagation_policy='Background')


@kopf.on.create('otus.homework', 'v1', 'mysqls')
def mysql_on_create(body, spec, **kwargs):
    # pylint: disable=unused-argument,too-many-locals
    # pylint: disable=too-many-statements
    # pylint: disable=fixme
    """Create mysql controller
    """
    # TODO: this method is to big and needs to be splitted into several sub-methods
    name = body['metadata']['name']
    image = body['spec']['image']
    namespace = body['metadata']['namespace']
    # can't find good way to get group, version, plural, so parse apiVersion, selfLink
    group, version = body['apiVersion'].split('/')
    plural = body['metadata']['selfLink'].split('/')[6]
    password = body['spec']['password']
    database = body['spec']['database']
    storage_size = body['spec']['storage_size']
    persistent_volume = render_template(
        'mysql-pv.yml.j2',
        {
            'name': name,
            'storage_size': storage_size
        }
    )

    persistent_volume_claim = render_template(
        'mysql-pvc.yml.j2',
        {
            'name': name,
            'storage_size': storage_size
        }
    )

    service = render_template('mysql-service.yml.j2', {'name': name})

    deployment = render_template(
        'mysql-deployment.yml.j2',
        {
            'name': name,
            'image': image,
            'password': password,
            'database': database
        }
    )

    restore_job = render_template(
        'restore-job.yml.j2',
        {
            'name': name,
            'image': image,
            'password': password,
            'database': database
        }
    )

    kopf.append_owner_reference(persistent_volume, owner=body)
    kopf.append_owner_reference(persistent_volume_claim, owner=body)  # addopt
    kopf.append_owner_reference(service, owner=body)
    kopf.append_owner_reference(deployment, owner=body)

    api = kubernetes.client.CoreV1Api()
    api.create_persistent_volume(persistent_volume)
    api.create_namespaced_persistent_volume_claim(
        'default', persistent_volume_claim)
    api.create_namespaced_service('default', service)
    api = kubernetes.client.AppsV1Api()
    api.create_namespaced_deployment('default', deployment)

    try:
        api = kubernetes.client.BatchV1Api()
        api.create_namespaced_job('default', restore_job)
        status = {
            "status": {
                'kopf': {
                    'message': 'mysql-instance created WITH restore-job'}}}
        logging.info("Restore job executed successfully, so setup '%s' status", status)
    except kubernetes.client.rest.ApiException:
        status = {
            "status": {
                'kopf': {
                    'message': 'mysql-instance created WITHOUT restore-job'}}}
        logging.info("Restore job exception, so setup '%s' status", status)

    try:
        backup_pv = render_template('backup-pv.yml.j2', {'name': name})
        api = kubernetes.client.CoreV1Api()
        print(api.create_persistent_volume(backup_pv))
        api.create_persistent_volume(backup_pv)
    except kubernetes.client.rest.ApiException:
        pass

    try:
        backup_pvc = render_template('backup-pvc.yml.j2', {'name': name})
        api = kubernetes.client.CoreV1Api()
        api.create_namespaced_persistent_volume_claim('default', backup_pvc)
    except kubernetes.client.rest.ApiException:
        pass

    api = kubernetes.client.CustomObjectsApi()
    try:
        crd_status = api.patch_namespaced_custom_object_status(
            group, version, namespace, plural, name, body=status)
        logging.info(crd_status)
    except kubernetes.client.rest.ApiException as error:
        print("Exception when calling CustomObjectsApi->get_namespaced_custom_object: %s\n" % error)


@kopf.on.update('otus.homework', 'v1', 'mysqls')
def update_object_password(body, meta, **kwargs):
    # pylint: disable=unused-argument
    """Update mysqls resources and change password
    """
    name = body['metadata']['name']
    image = body['spec']['image']
    new_password = body['spec']['password']
    database = body['spec']['database']

    delete_success_jobs(name)

    last_handled_configuration = yaml.load(
        meta.get('annotations')['kopf.zalando.org/last-handled-configuration'])
    old_password = last_handled_configuration['spec']['password']

    logging.info("Log password to study purposes only!!!")
    logging.info("Old password: '%s'", old_password)
    logging.info("New password: '%s'", new_password)
    logging.info(database)
    api = kubernetes.client.BatchV1Api()
    passwd_job = render_template('passwd-job.yml.j2', {
        'name': name,
        'image': image,
        'old_password': old_password,
        'new_password': new_password,
        'database': database})

    logging.info(passwd_job)
    api.create_namespaced_job('default', passwd_job)
    wait_until_job_end(f"passwd-{name}-job")
    return {'message': "mysql password changed"}


@kopf.on.delete('otus.homework', 'v1', 'mysqls')
def delete_object_make_backup(body, **kwargs):
    # pylint: disable=unused-argument
    """Delete mysqls resources and create backup
    """
    name = body['metadata']['name']
    image = body['spec']['image']
    password = body['spec']['password']
    database = body['spec']['database']

    delete_success_jobs(name)

    # Cоздаем backup job:
    api = kubernetes.client.BatchV1Api()
    backup_job = render_template('backup-job.yml.j2', {
        'name': name,
        'image': image,
        'password': password,
        'database': database})
    api.create_namespaced_job('default', backup_job)
    wait_until_job_end(f"backup-{name}-job")
    return {'message': "mysql and its children resources deleted"}
