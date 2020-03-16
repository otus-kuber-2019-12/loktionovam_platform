#!/usr/bin/env bash

MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")
kubectl exec -it "${MYSQLPOD}" -- mysql -u root  -potuspassword -e "CREATE TABLE test ( id smallint unsigned not null auto_increment, name varchar(20) not null, constraint pk_example primary key (id) );" otus-database
kubectl exec -it "${MYSQLPOD}" -- mysql -potuspassword  -e "INSERT INTO test ( id, name )VALUES ( null, 'some data' );" otus-database
kubectl exec -it "${MYSQLPOD}" -- mysql -potuspassword -e "INSERT INTO test ( id, name )VALUES ( null, 'some data-2' );" otus-database

kubectl exec -it "${MYSQLPOD}" -- mysql -potuspassword -e "select * from test;" otus-database
