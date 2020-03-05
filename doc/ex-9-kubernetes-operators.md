# EX-9 Custom Resource Definitions. Operators

* [EX-9 Custom Resource Definitions. Operators](#ex-9-custom-resource-definitions-operators)
  * [EX-9.1 Что было сделано](#ex-91-%d0%a7%d1%82%d0%be-%d0%b1%d1%8b%d0%bb%d0%be-%d1%81%d0%b4%d0%b5%d0%bb%d0%b0%d0%bd%d0%be)
  * [EX-9.2 Как запустить проект](#ex-92-%d0%9a%d0%b0%d0%ba-%d0%b7%d0%b0%d0%bf%d1%83%d1%81%d1%82%d0%b8%d1%82%d1%8c-%d0%bf%d1%80%d0%be%d0%b5%d0%ba%d1%82)
  * [EX-9.3 Как проверить проект](#ex-93-%d0%9a%d0%b0%d0%ba-%d0%bf%d1%80%d0%be%d0%b2%d0%b5%d1%80%d0%b8%d1%82%d1%8c-%d0%bf%d1%80%d0%be%d0%b5%d0%ba%d1%82)
  * [EX-9.4 Как начать пользоваться проектом](#ex-94-%d0%9a%d0%b0%d0%ba-%d0%bd%d0%b0%d1%87%d0%b0%d1%82%d1%8c-%d0%bf%d0%be%d0%bb%d1%8c%d0%b7%d0%be%d0%b2%d0%b0%d1%82%d1%8c%d1%81%d1%8f-%d0%bf%d1%80%d0%be%d0%b5%d0%ba%d1%82%d0%be%d0%bc)

## EX-9.1 Что было сделано

* Основное задание: создать и применить CR, CRD для mysql с валидацией схемы
* Основное задание: добавить в CRD обязательные поля
* Основное занятие: mysql оператор, управляющий persistent volume, persistent volume claim, deployment, service
* Основное занятие: деплой mysql оператора
* Задание со(*): смена пароля от mysql, при изменении этого параметра в описании mysql-instance

## EX-9.2 Как запустить проект

```bash
kubectl apply -f kubernetes-operators/deploy/crd.yml
kopf run kubernetes-operators/build/mysql_operator.py
kubectl apply -f kubernetes-operators/deploy/cr.yml
misc/scripts/fill_mysql_instance.sh
```

## EX-9.3 Как проверить проект

* Удалить запущенный проект, а затем заново создать - данные должны будут сохраниться и восстановиться через backup/restore jobs

  ```bash
  # Удаляем запущенный mysql
  delete mysqls.otus.homework mysql-instance

  # Заново создаем
  kubectl apply -f kubernetes-operators/deploy/cr.yml

  # Проверяем, что данные на месте
  export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")
  kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
  mysql: [Warning] Using a password on the command line interface can be insecure.
  +----+-------------+
  | id | name        |
  +----+-------------+
  |  1 | some data   |
  |  2 | some data-2 |
  +----+-------------+
  ```

* Проверить, что backup/restore jobs отработали без ошибок

  ```bash
  kubectl get jobs
  NAME                         COMPLETIONS   DURATION   AGE
  backup-mysql-instance-job    1/1           1s         111s
  restore-mysql-instance-job   1/1           20s        75s
  ```

* (*) Автоматическая смена пароля реализуется в `@kopf.on.update`, аналогично `@kopf.on.delete`, причем старый пароль мы можем узнать из аннотации `kopf.zalando.org/last-handled-configuration`:

  ```bash
  # Меняем пароль с 'otuspassword' на 'newpassword'
  kubectl apply -f kubernetes-operators/deploy/cr-passwd.yml
  ```

  ```bash
  # В логах видим, что событие обработано
  [2020-03-05 23:13:57,381] root                 [INFO    ] Old password: 'otuspassword'
  [2020-03-05 23:13:57,381] root                 [INFO    ] New password: 'newpassword'
  [2020-03-05 23:13:57,381] root                 [INFO    ] otus-database
  [2020-03-05 23:13:57,388] root                 [INFO    ] {'apiVersion': 'batch/v1', 'kind': 'Job', 'metadata': {'namespace': 'default', 'name': 'passwd-mysql-instance-job'}, 'spec': {'template': {'metadata': {'name': 'passwd-mysql-instance-job'}, 'spec': {'restartPolicy': 'OnFailure', 'containers': [{'name': 'passwd-mysql-instance', 'image': 'mysql:5.7', 'imagePullPolicy': 'IfNotPresent', 'command': ['/bin/sh', '-c', 'mysql -u root -h mysql-instance -potuspassword -e "UPDATE mysql.user SET authentication_string=PASSWORD(\'newpassword\') WHERE User=\'root\'; FLUSH PRIVILEGES;";']}]}}}}
  job with passwd-mysql-instance-job  found,wait untill end
  job with passwd-mysql-instance-job  found,wait untill end
  job with passwd-mysql-instance-job  success
  [2020-03-05 23:13:59,445] kopf.objects         [INFO    ] [default/mysql-instance] Handler 'update_object_password' succeeded.
  [2020-03-05 23:13:59,445] kopf.objects         [INFO    ] [default/mysql-instance] All handlers succeeded for update.
  ```

  ```bash
  # Подключаемся с новым паролем
  kubectl exec -ti mysql-instance-6c76bcf945-vngx8 -- mysql -u root -pnewpassword -e 'show databases;'
  mysql: [Warning] Using a password on the command line interface can be insecure.
  +--------------------+
  | Database           |
  +--------------------+
  | information_schema |
  | mysql              |
  | otus-database      |
  | performance_schema |
  | sys                |
  +--------------------+

  ```

## EX-9.4 Как начать пользоваться проектом
