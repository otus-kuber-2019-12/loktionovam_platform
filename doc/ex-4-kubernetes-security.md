# EX-4 Настройка аккаунтов и прав для них, настройка ограничений и политик безопасности для контейнеров

* [EX-4 Настройка аккаунтов и прав для них, настройка ограничений и политик безопасности для контейнеров](#ex-4-%d0%9d%d0%b0%d1%81%d1%82%d1%80%d0%be%d0%b9%d0%ba%d0%b0-%d0%b0%d0%ba%d0%ba%d0%b0%d1%83%d0%bd%d1%82%d0%be%d0%b2-%d0%b8-%d0%bf%d1%80%d0%b0%d0%b2-%d0%b4%d0%bb%d1%8f-%d0%bd%d0%b8%d1%85-%d0%bd%d0%b0%d1%81%d1%82%d1%80%d0%be%d0%b9%d0%ba%d0%b0-%d0%be%d0%b3%d1%80%d0%b0%d0%bd%d0%b8%d1%87%d0%b5%d0%bd%d0%b8%d0%b9-%d0%b8-%d0%bf%d0%be%d0%bb%d0%b8%d1%82%d0%b8%d0%ba-%d0%b1%d0%b5%d0%b7%d0%be%d0%bf%d0%b0%d1%81%d0%bd%d0%be%d1%81%d1%82%d0%b8-%d0%b4%d0%bb%d1%8f-%d0%ba%d0%be%d0%bd%d1%82%d0%b5%d0%b9%d0%bd%d0%b5%d1%80%d0%be%d0%b2)
  * [EX-4.1 Что было сделано](#ex-41-%d0%a7%d1%82%d0%be-%d0%b1%d1%8b%d0%bb%d0%be-%d1%81%d0%b4%d0%b5%d0%bb%d0%b0%d0%bd%d0%be)
  * [EX-4.2 Как запустить проект](#ex-42-%d0%9a%d0%b0%d0%ba-%d0%b7%d0%b0%d0%bf%d1%83%d1%81%d1%82%d0%b8%d1%82%d1%8c-%d0%bf%d1%80%d0%be%d0%b5%d0%ba%d1%82)
  * [EX-4.3 Как проверить проект](#ex-43-%d0%9a%d0%b0%d0%ba-%d0%bf%d1%80%d0%be%d0%b2%d0%b5%d1%80%d0%b8%d1%82%d1%8c-%d0%bf%d1%80%d0%be%d0%b5%d0%ba%d1%82)
  * [EX-4.4 Как начать пользоваться проектом](#ex-44-%d0%9a%d0%b0%d0%ba-%d0%bd%d0%b0%d1%87%d0%b0%d1%82%d1%8c-%d0%bf%d0%be%d0%bb%d1%8c%d0%b7%d0%be%d0%b2%d0%b0%d1%82%d1%8c%d1%81%d1%8f-%d0%bf%d1%80%d0%be%d0%b5%d0%ba%d1%82%d0%be%d0%bc)

* Основное задание: создать service account bob, дать ему роль admin в рамках всего кластера

  Создать service account dave без доступа к кластеру

* Основное задание: создать prometheus namespace

  Создать Service Account carol в этом Namespace

  Дать всем Service Account в Namespace prometheus возможность делать get, list, watch в отношении Pods всего кластера

* Основное задание: создать dev namespace

  Создать Service Account jane в Namespace dev

  Дать jane роль admin в рамках Namespace dev

  Создать Service Account ken в Namespace dev

  Дать ken роль view в рамках Namespace dev

## EX-4.1 Что было сделано

* Написаны манифесты для создания пользователей **bob** и **dave**
* Написан манифест для связывания кластерной роли **admin** с **bob** service account
* Написан манифест для создания **prometheus namespace**
* Написан манифест для создания **carol service account** в **prometheus namespace**
* Написан манифест для создания кластерной роли **pod-reader**, дающей делать get, list, watch для pods всего кластера
* Написан манифест для связывания кластерной роли **pod-reader** со всеми service accounts из **prometheus namespace**
* Написан манифест для создания **dev namespace**
* Написан манифест для создания **jane service account** в **dev namespace**
* Написан манифест для связывания **jane service account** с ролью admin в **dev namespace**
* Написан манифест для создания **ken service account** в **dev namespace**
* Написан манифест для связывания **ken service account** с ролью view в **dev namespace**
* Написан скрипт проверки `misc/scripts/check_service_account_priviledges.sh`, который выводит привилегии заданного service account для заданного namespace

## EX-4.2 Как запустить проект

* Создать **bob и dave** service accounts, добавить для **bob** роль **admin** в рамках всего кластера

  ```bash
  cat kubernetes-security/task01/*.yaml | kubectl apply -f -
  ```

* Создать **prometheus namespace**, и **carol service account**, который умеет делать get, list, watch для всех pods в кластере

  ```bash
  cat kubernetes-security/task02/*.yaml | kubectl apply -f -
  ```

* Создать **dev namespace**, **jane service account**, с ролью admin в этом namespace, **ken service account**, с ролью view в это namespace

  ```bash
  cat kubernetes-security/task03/*.yaml | kubectl apply -f -
  ```

## EX-4.3 Как проверить проект

* Для проверки **carol service account** команда `kubectl auth can-i...` должна выдавать **yes**

  ```bash
  for VERB in get list watch; do kubectl auth can-i $VERB pods --as system:serviceaccount:prometheus:carol; done
  yes
  yes
  yes
  ```

* Для проверки **jane service account** можно использовать `misc/scripts/check_service_account_priviledges.sh` для dev и default namespaces

  ```bash
  # dev namespace
  misc/scripts/check_service_account_priviledges.sh -n dev -s system:serviceaccount:dev:jane
  system:serviceaccount:dev:jane can create in dev: yes
  system:serviceaccount:dev:jane can delete in dev: yes
  system:serviceaccount:dev:jane can deletecollection in dev: yes
  system:serviceaccount:dev:jane can get in dev: yes
  system:serviceaccount:dev:jane can list in dev: yes
  system:serviceaccount:dev:jane can patch in dev: yes
  system:serviceaccount:dev:jane can update in dev: yes
  system:serviceaccount:dev:jane can watch in dev: yes
  ```

  ```bash
  # in default namespace jane can nothing
  misc/scripts/check_service_account_priviledges.sh -n default -s system:serviceaccount:dev:jane
  system:serviceaccount:dev:jane can create in default: no
  system:serviceaccount:dev:jane can delete in default: no
  system:serviceaccount:dev:jane can deletecollection in default: no
  system:serviceaccount:dev:jane can get in default: no
  system:serviceaccount:dev:jane can list in default: no
  system:serviceaccount:dev:jane can patch in default: no
  system:serviceaccount:dev:jane can update in default: no
  system:serviceaccount:dev:jane can watch in default: no
  ```

* Для проверки **ken service account** можно использовать `misc/scripts/check_service_account_priviledges.sh` для dev и default namespaces

  ```bash
  # in default namespace ken can nothing
  misc/scripts/check_service_account_priviledges.sh -n default -s system:serviceaccount:dev:ken
  system:serviceaccount:dev:ken can create in default: no
  system:serviceaccount:dev:ken can delete in default: no
  system:serviceaccount:dev:ken can deletecollection in default: no
  system:serviceaccount:dev:ken can get in default: no
  system:serviceaccount:dev:ken can list in default: no
  system:serviceaccount:dev:ken can patch in default: no
  system:serviceaccount:dev:ken can update in default: no
  system:serviceaccount:dev:ken can watch in default: no
  ```

  ```bash
  # in dev namespace ken can read-only priviledges
  misc/scripts/check_service_account_priviledges.sh -n dev -s system:serviceaccount:dev:ken
  system:serviceaccount:dev:ken can create in dev: no
  system:serviceaccount:dev:ken can delete in dev: no
  system:serviceaccount:dev:ken can deletecollection in dev: no
  system:serviceaccount:dev:ken can get in dev: yes
  system:serviceaccount:dev:ken can list in dev: yes
  system:serviceaccount:dev:ken can patch in dev: no
  system:serviceaccount:dev:ken can update in dev: no
  system:serviceaccount:dev:ken can watch in dev: yes
  ```

## EX-4.4 Как начать пользоваться проектом

Упражнения для создания **service accounts** синтетические и не предполагают "использование проекта"
