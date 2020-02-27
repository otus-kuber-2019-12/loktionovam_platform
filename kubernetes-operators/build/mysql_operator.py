"""Mysql operator.
"""

import time
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
    print("start deletion")
    api = kubernetes.client.BatchV1Api()
    jobs = api.list_namespaced_job('default')
    for job in jobs.items:
        jobname = job.metadata.name
        if jobname in (f"backup-{mysql_instance_name}-job", f"restore-{mysql_instance_name}-job"):
            if job.status.succeeded == 1:
                api.delete_namespaced_job(jobname,
                                          'default',
                                          propagation_policy='Background')


@kopf.on.create('otus.homework', 'v1', 'mysqls')
def mysql_on_create(body):
    """Create mysql controller
    """
    name = body['metadata']['name']
    image = body['spec']['image']

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
    except kubernetes.client.rest.ApiException:
        pass

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


@kopf.on.delete('otus.homework', 'v1', 'mysqls')
def delete_object_make_backup(body):
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
