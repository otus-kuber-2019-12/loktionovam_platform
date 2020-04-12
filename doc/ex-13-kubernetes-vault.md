# EX-13 K8s + Vault

* [EX-13 K8s + Vault](#ex-13-k8s--vault)
  * [EX-13.1 Что было сделано](#ex-131-%d0%a7%d1%82%d0%be-%d0%b1%d1%8b%d0%bb%d0%be-%d1%81%d0%b4%d0%b5%d0%bb%d0%b0%d0%bd%d0%be)
  * [EX-13.2 Как запустить проект](#ex-132-%d0%9a%d0%b0%d0%ba-%d0%b7%d0%b0%d0%bf%d1%83%d1%81%d1%82%d0%b8%d1%82%d1%8c-%d0%bf%d1%80%d0%be%d0%b5%d0%ba%d1%82)
  * [EX-13.3 Как проверить проект](#ex-133-%d0%9a%d0%b0%d0%ba-%d0%bf%d1%80%d0%be%d0%b2%d0%b5%d1%80%d0%b8%d1%82%d1%8c-%d0%bf%d1%80%d0%be%d0%b5%d0%ba%d1%82)
  * [EX-13.4 Как начать пользоваться проектом](#ex-134-%d0%9a%d0%b0%d0%ba-%d0%bd%d0%b0%d1%87%d0%b0%d1%82%d1%8c-%d0%bf%d0%be%d0%bb%d1%8c%d0%b7%d0%be%d0%b2%d0%b0%d1%82%d1%8c%d1%81%d1%8f-%d0%bf%d1%80%d0%be%d0%b5%d0%ba%d1%82%d0%be%d0%bc)

## EX-13.1 Что было сделано

## EX-13.2 Как запустить проект

* Установить consul, vault

  ```bash
  git clone https://github.com/hashicorp/consul-helm.git
  helm install consul ./consul-helm
  ```

  ```bash
  git clone https://github.com/hashicorp/vault-helm.git
  helm upgrade --install vault ./vault-helm --values vault.values.yaml
  ```

  ```bash
  helm status vault
  NAME: vault
  LAST DEPLOYED: Fri Apr  3 14:27:16 2020
  NAMESPACE: default
  STATUS: deployed
  REVISION: 1
  TEST SUITE: None
  NOTES:
  Thank you for installing HashiCorp Vault!

  Now that you have deployed Vault, you should look over the docs on using
  Vault with Kubernetes available here:

  https://www.vaultproject.io/docs/


  Your release is named vault. To learn more about the release, try:

    $ helm status vault
    $ helm get vault

  ```

* Инициализировать vault и распечатать все 3 инстанса:

  ```bash
  kubectl exec -ti vault-0 -- vault operator init --key-shares=1 --key-threshold=1
  Unseal Key 1: LJSyeNq1bVNZ86E7TlAUAjZg/6gMXMpPmGlYliv/abA=
  Initial Root Token: s.zilTe4vzHF2lWwAlCxkoSaUQ


  ```

  ```bash
  for POD_NUM in 0 1 2; do kubectl exec -it vault-"${POD_NUM}" -- vault operator unseal;done

  kubectl exec -it vault-0 -- vault status
  Key             Value
  ---             -----
  Seal Type       shamir
  Initialized     true
  Sealed          false
  Total Shares    1
  Threshold       1
  Version         1.3.3
  Cluster Name    vault-cluster-dc95adf3
  Cluster ID      db94a27b-810c-e129-82be-fe6367679c50
  HA Enabled      true
  HA Cluster      https://10.244.5.7:8201
  HA Mode         active

  ```

* Залогиниться в vault, вывести список секретов:

  ```bash
  kubectl exec -it vault-0 -- vault login
  Token (will be hidden):
  Success! You are now authenticated. The token information displayed below
  is already stored in the token helper. You do NOT need to run "vault login"
  again. Future Vault requests will automatically use this token.

  Key                  Value
  ---                  -----
  token                s.zilTe4vzHF2lWwAlCxkoSaUQ
  token_accessor       gy3OCxrCvBWCyoReZyzmEQVU
  token_duration       ∞
  token_renewable      false
  token_policies       ["root"]
  identity_policies    []
  policies             ["root"]

  ```

  ```bash
  kubectl exec -it vault-0 -- vault auth list
  Path      Type     Accessor               Description
  ----      ----     --------               -----------
  token/    token    auth_token_e837ff1f    token based credentials
  ```

* Создать секреты:

  ```bash
  kubectl exec -it vault-0 -- vault secrets enable --path=otus kv
  kubectl exec -it vault-0 -- vault secrets list --detailed
  kubectl exec -it vault-0 -- vault kv put otus/otus-ro/config username='otus' password='asajkjkahs'
  kubectl exec -it vault-0 -- vault kv put otus/otus-rw/config username='otus' password='asajkjkahs'

  kubectl exec -it vault-0 -- vault read otus/otus-ro/config
  Key                 Value
  ---                 -----
  refresh_interval    768h
  password            asajkjkahs
  username            otus

  kubectl exec -it vault-0 -- vault kv get otus/otus-rw/config
  ====== Data ======
  Key         Value
  ---         -----
  password    asajkjkahs
  username    otus

  ```

* Включить k8s:

  ```bash
  kubectl exec -ti vault-0 -- vault auth enable kubernetes
  kubectl exec -ti vault-0 -- vault auth list
  Path           Type          Accessor                    Description
  ----           ----          --------                    -----------
  kubernetes/    kubernetes    auth_kubernetes_16edeb05    n/a
  token/         token         auth_token_e837ff1f         token based credentials
  ```

  ```bash
  kubectl apply -f vault-auth-service-account.yml

  ```

  ```bash
  export VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}")
  export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
  export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)
  export CLUSTER_NAME=$(kubectl config current-context)
  export K8S_HOST=$(kubectl config view -o jsonpath="{.clusters[?(@.name==\"$CLUSTER_NAME\")].cluster.server}")

  # Удалить все escape codes, управляющие цветом вывода, например "\x1b[31m" - красный
  sed 's/\x1b\[[0-9;]*m//g'

  # Примечание: у меня эта команда работает некорректно, т.к. в config файле перечислено несколько контекстов
  # и лучше не парсить структурированные файлы (json, xml, yaml и т. д.) с помощью sed/grep/awk
  export K8S_HOST=$(more ~/.kube/config | grep server |awk '/http/ {print $NF}')

  # Это более корректный способ определения адреса k8s
  export CLUSTER_NAME=$(kubectl config current-context)
  export K8S_HOST=$(kubectl config view -o jsonpath="{.clusters[?(@.name==\"$CLUSTER_NAME\")].cluster.server}")

  # но он тоже не будет работать, т.к. если используется minikube/kind, то адрес может быть localhost'ом и pod с vault не сможет подключиться к k8s (будет долбиться в свой localhost),
  # поэтому правильно будет использовать внутренний адрес https://kubernetes.default.svc если vault находится в том же k8s кластере, что и SA

  export K8S_HOST='https://kubernetes.default.svc'
  ```

  ```bash
  kubectl exec -it vault-0 -- vault write auth/kubernetes/config \
  token_reviewer_jwt="$SA_JWT_TOKEN" \
  kubernetes_host="$K8S_HOST" \
  kubernetes_ca_cert="$SA_CA_CRT"
  ```

  ```bash
  kubectl cp otus-policy.hcl vault-0:/tmp
  kubectl exec -it vault-0 -- vault policy write otus-policy /tmp/otus-policy.hcl

  kubectl exec -it vault-0 -- vault write auth/kubernetes/role/otus \
  bound_service_account_names=vault-auth \
  bound_service_account_namespaces=default policies=otus-policy  ttl=24h
  ```

* Проверить, что авторизация через k8s работает:

  ```bash
  kubectl run --generator=run-pod/v1 tmp  -i  --serviceaccount=vault-auth --image alpine:3.7 sleep 10000
  kubectl exec -ti tmp apk add curl jq
  ```

  `curl --request POST --data '{"bar": "baz"}'   --header "X-Vault-Token:s.Hp2AAE8tukt42iPu5hisGBb5" $VAULT_ADDR/v1/otus/otus-rw/config` завершилась с ошибкой потому что в политиках для `otus/otus-rw/*` отсутствовал `update`, поэтому правильно будет:

  ```json
  path "otus/otus-rw/*" {
      capabilities = ["read", "create", "list", "update"]
  }
  ```

* Рендеринг файлов с секретами с помощью sidecar-контейнера с consul template:

  ```bash
  kubectl apply -f consul-template/configmap-example-vault-agent-config.yaml
  kubectl apply -f consul-template/example-k8s-spec.yml

  # sidecar контейнер с consul template получил токен
  kubectl exec -ti vault-agent-example -c consul-template -- cat /home/vault/.vault-token
  s.o6WhySWAf27zQwF8Ygc6YDUw

  # сходил в vault за секретами и отрендерил конфигурацию для nginx
  kubectl exec -ti vault-agent-example -c consul-template  -- cat /etc/secrets/index.html
    <html>
    <body>
    <p>Some secrets:</p>
    <ul>
    <li><pre>username: otus</pre></li>
    <li><pre>password: asajkjkahs</pre></li>
    </ul>

    </body>
    </html>
    %

  # nginx получил уже отрендеренный конфигурационный файл
  kubectl exec -ti vault-agent-example -c nginx-container  -- cat /usr/share/nginx/html/index.html
    <html>
    <body>
    <p>Some secrets:</p>
    <ul>
    <li><pre>username: otus</pre></li>
    <li><pre>password: asajkjkahs</pre></li>
    </ul>

    </body>
    </html>
    %
  ```

* Использование Vault CA:

  ```bash
  kubectl exec -it vault-0 -- vault secrets enable pki
  kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki
  kubectl exec -it vault-0 -- vault write -field=certificate pki/root/generate/internal common_name="example.ru"  ttl=87600h > CA_cert.crt
  ```

  ```bash
  kubectl exec -it vault-0 -- vault write pki/config/urls issuing_certificates="http://vault:8200/v1/pki/ca" crl_distribution_points="http://vault:8200/v1/pki/crl"
  ```

  ```bash
  kubectl exec -it vault-0 -- vault secrets enable --path=pki_int pki
  kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki_int
  kubectl exec -it vault-0 -- vault write -format=json pki_int/intermediate/generate/internal common_name="example.ru Intermediate Authority"  | jq -r '.data.csr' > pki_intermediate.csr
  ```

  ```bash
  kubectl cp pki_intermediate.csr vault-0:./tmp
  kubectl exec -it vault-0 -- vault write -format=json pki/root/sign-intermediate csr=@/tmp/pki_intermediate.csr format=pem_bundle ttl="43800h" |  jq -r '.data.certificate' > intermediate.cert.pem
  kubectl cp intermediate.cert.pem vault-0:./tmp
  kubectl exec -it vault-0 -- vault write pki_int/intermediate/set-signed certificate=@/tmp/intermediate.cert.pem
  ```

  ```bash
  kubectl exec -it vault-0 -- vault write pki_int/roles/example-dot-ru allowed_domains="example.ru" allow_subdomains=true   max_ttl="720h"
  ```

  ```bash
  kubectl exec -it vault-0 -- vault write pki_int/issue/example-dot-ru common_name="gitlab.example.ru" ttl="24h"
  Key                 Value
  ---                 -----
  ca_chain            [-----BEGIN CERTIFICATE-----
  MIIDnDCCAoSgAwIBAgIUSt2QrQY2D62bJ46lUR7DFQL/V/gwDQYJKoZIhvcNAQEL
  BQAwFTETMBEGA1UEAxMKZXhtYXBsZS5ydTAeFw0yMDA0MDMxNjQwMzlaFw0yNTA0
  MDIxNjQxMDlaMCwxKjAoBgNVBAMTIWV4YW1wbGUucnUgSW50ZXJtZWRpYXRlIEF1
  dGhvcml0eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMJgXdQ1l0Ex
  o8IzQAC9QvNooWS12MpyA1VKmKt25hN/BXq9ooaMKbjETu0ve5NYl1cjrGcMv40/
  Ji/fV2QU5wxLUNpEYR6nTU39o4sh0WsLXjV76uK2XzL2v6eX6VJ9/yD9gAZe+NGW
  Bi1ljXtvDldJyXPp9Fpt6o2QbJE2azm+oqeGQZFuBtItpqHe4XL+gpRncF9QG8tX
  OjjdLSZO+qppaWOecq5hJ52QwSMyiNwLnuZILUqwYS1wN0CDvXp/9AugmoBec+m1
  vHmaaJpD5Re/On8XdMHMX8nI5pFJtsf0CNXMwx/BG8lyrlFHU6gbsqS1sz7o3DxU
  ereJRGWfpP8CAwEAAaOBzDCByTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUw
  AwEB/zAdBgNVHQ4EFgQUFlUbg9Q1YUfOUkl71FTXxCrjpN4wHwYDVR0jBBgwFoAU
  gGCNIGl5HQi4wiEgTzCUe8Jn7ukwNwYIKwYBBQUHAQEEKzApMCcGCCsGAQUFBzAC
  hhtodHRwOi8vdmF1bHQ6ODIwMC92MS9wa2kvY2EwLQYDVR0fBCYwJDAioCCgHoYc
  aHR0cDovL3ZhdWx0OjgyMDAvdjEvcGtpL2NybDANBgkqhkiG9w0BAQsFAAOCAQEA
  W7WncGx6CyWK5YmEYCKtGbjDG92dkT/I9X+GmN4XKzsHNqSDIYlhItlhY4v4P1XF
  IW3gK/fg6VyxTzc5/OiN2Ml7urPLPIOUY2M+YBcitHGErgSO3RjvFstO9uMUHQsB
  zl0dIV0QTsw2fvLvP7/sWJ4iq7MXyKEtVJwoVL56olKrhFrN/3ROLSo8NFGhmETc
  ttP7kvwEOrLU0hmi26v/uVEM3e1GYRlE9tLLQ+G/gXLCWs0R9I9yK5eTS0AsncT5
  isqWlhqIYhgU3WqXtbRguFyD005MnChtVyGeV7G5Eelldl71OcN6DAELlDjaxWdv
  x4CWqjwc5C4iTHXzhA01Aw==
  -----END CERTIFICATE-----]
  certificate         -----BEGIN CERTIFICATE-----
  MIIDZzCCAk+gAwIBAgIUcQ2J27iMb9AK9bFGZVIdhzjiKGAwDQYJKoZIhvcNAQEL
  BQAwLDEqMCgGA1UEAxMhZXhhbXBsZS5ydSBJbnRlcm1lZGlhdGUgQXV0aG9yaXR5
  MB4XDTIwMDQwMzE2NDQ1NloXDTIwMDQwNDE2NDUyNVowHDEaMBgGA1UEAxMRZ2l0
  bGFiLmV4YW1wbGUucnUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDy
  41ta0Q7h+KvusCUeOUrAx977bC95kJRRO0I+zkyP38iJmgoFgN9W1dU9OnTNuVp+
  gU0VvtvWTKvsuL1JlX8ksILzXxPkMqKXIZamj6HiQ2Yl5GBpytwv0z/k65Nw8Vz2
  v2f2v22WsZi6+iNVQdqyfiFuo/vZdM1t2jp0iNGV0OymrjrAQXD1Y2L8ozKdQoGB
  83R/1kpnAg3CXh6jRDuiaUzGDsBSPW0gva1Fjoiz4QjgJlUGIcCw71Sc9TopOH57
  TCMu/igP3e4GWOaRro+XRFFH7yzck3JSGoab0w69WRaNXE8FP10vxudiZC2e6Jb2
  cmQREStBUXnijVJJ/nAtAgMBAAGjgZAwgY0wDgYDVR0PAQH/BAQDAgOoMB0GA1Ud
  JQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAdBgNVHQ4EFgQUKHG85/70qJDiepC3
  CEVDVh+sZo0wHwYDVR0jBBgwFoAUFlUbg9Q1YUfOUkl71FTXxCrjpN4wHAYDVR0R
  BBUwE4IRZ2l0bGFiLmV4YW1wbGUucnUwDQYJKoZIhvcNAQELBQADggEBAJe5QLeb
  ZoFqmsx1uj8oyX5KSD4PGEfOkEOACppDGStPPzckbZlllRg7lUjw30qnZ0W4MTdr
  KwOlEhmCMG5rfsXqsEGOGrMs8c/bXFZv2qwjWoc/uq0sB1/webSK3kkyvTblm9Gq
  xJzXKNY8RtUjhPvho/ibp9gTO05dB1qbhx9jcdcHtOK8JLtvP/zFIuBzKx2xg4nb
  hKa3QgrzxfItUG8/IHUZGgzwr8/+euFb4VcznBQp8lmLQIXr/g2KO+biVyfTt6ub
  uvWRko00gUq9fKKlRnQL0jjR2LD/u4ojRjLSBFNrSNHuTeE3blwqOATOSCwcwbs7
  gkANLLjxdHfZE7A=
  -----END CERTIFICATE-----
  expiration          1586018725
  issuing_ca          -----BEGIN CERTIFICATE-----
  MIIDnDCCAoSgAwIBAgIUSt2QrQY2D62bJ46lUR7DFQL/V/gwDQYJKoZIhvcNAQEL
  BQAwFTETMBEGA1UEAxMKZXhtYXBsZS5ydTAeFw0yMDA0MDMxNjQwMzlaFw0yNTA0
  MDIxNjQxMDlaMCwxKjAoBgNVBAMTIWV4YW1wbGUucnUgSW50ZXJtZWRpYXRlIEF1
  dGhvcml0eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMJgXdQ1l0Ex
  o8IzQAC9QvNooWS12MpyA1VKmKt25hN/BXq9ooaMKbjETu0ve5NYl1cjrGcMv40/
  Ji/fV2QU5wxLUNpEYR6nTU39o4sh0WsLXjV76uK2XzL2v6eX6VJ9/yD9gAZe+NGW
  Bi1ljXtvDldJyXPp9Fpt6o2QbJE2azm+oqeGQZFuBtItpqHe4XL+gpRncF9QG8tX
  OjjdLSZO+qppaWOecq5hJ52QwSMyiNwLnuZILUqwYS1wN0CDvXp/9AugmoBec+m1
  vHmaaJpD5Re/On8XdMHMX8nI5pFJtsf0CNXMwx/BG8lyrlFHU6gbsqS1sz7o3DxU
  ereJRGWfpP8CAwEAAaOBzDCByTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUw
  AwEB/zAdBgNVHQ4EFgQUFlUbg9Q1YUfOUkl71FTXxCrjpN4wHwYDVR0jBBgwFoAU
  gGCNIGl5HQi4wiEgTzCUe8Jn7ukwNwYIKwYBBQUHAQEEKzApMCcGCCsGAQUFBzAC
  hhtodHRwOi8vdmF1bHQ6ODIwMC92MS9wa2kvY2EwLQYDVR0fBCYwJDAioCCgHoYc
  aHR0cDovL3ZhdWx0OjgyMDAvdjEvcGtpL2NybDANBgkqhkiG9w0BAQsFAAOCAQEA
  W7WncGx6CyWK5YmEYCKtGbjDG92dkT/I9X+GmN4XKzsHNqSDIYlhItlhY4v4P1XF
  IW3gK/fg6VyxTzc5/OiN2Ml7urPLPIOUY2M+YBcitHGErgSO3RjvFstO9uMUHQsB
  zl0dIV0QTsw2fvLvP7/sWJ4iq7MXyKEtVJwoVL56olKrhFrN/3ROLSo8NFGhmETc
  ttP7kvwEOrLU0hmi26v/uVEM3e1GYRlE9tLLQ+G/gXLCWs0R9I9yK5eTS0AsncT5
  isqWlhqIYhgU3WqXtbRguFyD005MnChtVyGeV7G5Eelldl71OcN6DAELlDjaxWdv
  x4CWqjwc5C4iTHXzhA01Aw==
  -----END CERTIFICATE-----
  private_key         -----BEGIN RSA PRIVATE KEY-----
  MIIEpAIBAAKCAQEA8uNbWtEO4fir7rAlHjlKwMfe+2wveZCUUTtCPs5Mj9/IiZoK
  BYDfVtXVPTp0zblafoFNFb7b1kyr7Li9SZV/JLCC818T5DKilyGWpo+h4kNmJeRg
  acrcL9M/5OuTcPFc9r9n9r9tlrGYuvojVUHasn4hbqP72XTNbdo6dIjRldDspq46
  wEFw9WNi/KMynUKBgfN0f9ZKZwINwl4eo0Q7omlMxg7AUj1tIL2tRY6Is+EI4CZV
  BiHAsO9UnPU6KTh+e0wjLv4oD93uBljmka6Pl0RRR+8s3JNyUhqGm9MOvVkWjVxP
  BT9dL8bnYmQtnuiW9nJkERErQVF54o1SSf5wLQIDAQABAoIBAE4mp3tWLwK4f6HC
  XX8XEh1rcizVx4TG52Invg31VR8p8x2LSdQxfiszjHQx/ek/zYVM11+61INkkiEN
  5CHsD0ff35KtMfpH7JbSQOYA6yahZxmkHP2NP0HIKBPhVMSPdMkUF0CGoZ1OMYVf
  /MRu9w5dlSZDb0Kt2XeSMyLR7xXTzgCusYop5uQdEmWn2piCo/o08A8GJXxN2ohk
  lx+aLznwOxjkc4TdKCs5iwJpUVyDD70SgiFQQSnrv8teaZgGuQH0BB6TabjrGFBC
  Hr50LhZ0uqTOYDQKsH72Y5nFk/0MJDFTIDF8wDk8GVqLrJLSGF6TMC0vpzESpLlf
  jDEHOGECgYEA/p7DqQwQE9374N16zV80Z32bEi4jKAKWgX3nFK6Zld9YRDIpFIZi
  6KMzXHJT2ipWcLHWtRbPAFnmtGH+qw79/ET4dy+Io6xzS0b63G8qA471V24JgQh5
  NGVyMX3hZLZncIDo6JOhoL33M7Jhs296KHY6FXmwuf5Ety2X6Tbi0ykCgYEA9DRR
  DcpX4j6na45xnB+tb4KOPBP6AKY0IUXlYwm8+zP9K/cAwDZWy9JLXbTWoAtBC9Oe
  8jw9H7YLNxhM5oGlm+Fn7tWkTUF5jZ6MEzumG6e8Typ1i1xRD3fbtwzDcwx9jJXD
  tpwxRGDcFwK7h1O8CqCp9EnBJYKw0DTgXVo1OWUCgYEAoZM2LmwNN85CLCvf5bto
  kdPPN/Y3MQiTYZD3ttQleknExWHfV7r/wQjvatbSBzueptzzlu7mZR6nnAgjh4F4
  A0HxOhDb8KFaeIaOYpvYWXG6lsSpG0y5PVqy4F01TqfBdE8ZfZ1Rj6N83z1vamJv
  boW3zjDuyNhl2qgAImpF/iECgYEA0hGPCAXfw8eRzXwjTuIRF7N/Fz83+AcBIP43
  bRKbdpwqVP+NrcsQrxSfsGQ3nEUSF1JbkJUxH25CB4rn3AH6rDUiatltFOgV4DVa
  2dCd+3w3CQLFSrSHJn88iiJ4nydHeP/788I4v1FzAnhfSPJG9/1tNa+cbuAVqYVS
  2/sVfeECgYBk1umdHwPucWLUkLM/Nye5KvBNPriu4HVPLlAoY5sLj14o41HeTSAM
  zDBgXXbfE7Fav5i6CSMmwvQbslIdKEjLw7c9SzMvKShOL/awqwaaz3QdrzQr99bI
  znP3vjSQ29P/PiCI7lPw2N48mg3h/5cixwaomi/8aBIfdj3jChgAkw==
  -----END RSA PRIVATE KEY-----
  private_key_type    rsa
  serial_number       71:0d:89:db:b8:8c:6f:d0:0a:f5:b1:46:65:52:1d:87:38:e2:28:60
  ```

  ```bash
  kubectl exec -it vault-0 -- vault write pki_int/revoke serial_number=71:0d:89:db:b8:8c:6f:d0:0a:f5:b1:46:65:52:1d:87:38:e2:28:60
  ```

* Для включения tls в vault, нужно создать certificate signing request, подписать его Kubernetes CA (в принципе, можно использовать Vault CA), загрузить в k8s secrets и включить tls в конфигурации helm chart:

  ```bash
  # Создаем сертификат
  misc/scripts/create_cert_via_k8s.sh

  # Загружаем сертификат в k8s secrets
  misc/scripts/store_cert_to_k8s_secrets.sh
  ```

  ```bash
  # применяем новую конфигурацию для vault со включенным tls
  helm upgrade --install vault ./vault-helm --values vault.values.yaml
  ```

  ```bash
  # проверяем, что теперь vault использует tls
  kubectl port-forward svc/vault 8200:8200
  curl --cacert /tmp/vault.ca \
      -H "X-Vault-Token: s.nYJq9PW1SMF0uj7M91s2Q1wv" \
      -H "X-Vault-Namespace: default" \
      -X GET \
      https://127.0.0.1:8200/v1/otus/otus-ro/config
  {"request_id":"5bdc909f-c66f-19ef-b94e-3f76d35be416","lease_id":"","renewable":false,"lease_duration":2764800,"data":{"password":"asajkjkahs","username":"otus"},"wrap_info":null,"warnings":null,"auth":null}

  ```

* Автоматическое обновление сертификата в контейнере:

  ```bash
  # Создаем docker image с nginx и включенным ssl
  cd kubernetes-vault/nginx
  docker build  -t loktionovam/web-ssl:0.1.0 .
  docker push loktionovam/web-ssl:0.1.0

  # создаем политику по обновлению сертификатов и роль renew-pki
  kubectl cp pki-policy.hcl vault-0:/tmp
  kubectl exec -it vault-0 -- vault policy write pki-policy /tmp/pki-policy.hcl

  kubectl exec -it vault-0 -- vault write auth/kubernetes/role/renew-pki \
        bound_service_account_names=vault-auth \
        bound_service_account_namespaces=default policies=pki-policy  ttl=24h
  ```

* **Задача со** (*) Autounseal с использованием Transit Secrets Engine другого Vault (vault-transit):

  ```bash
  # настраиваем новый vault в котором будет включен Transit Secrets Engine
  cp misc/scripts/vault_transit_cert.conf misc/scripts/vault_cert.conf
  misc/scripts/create_cert_via_k8s.sh
  misc/scripts/store_cert_to_k8s_secrets.sh


  cd kubernetes-vault/
  helm upgrade --install vault-transit ./vault-helm --values autounseal/vault-transit.values.yaml
  kubectl exec -ti vault-transit-0 -- vault operator init --key-shares=1 --key-threshold=1
  for POD_NUM in 0 1 2; do kubectl exec -it vault-transit-"${POD_NUM}" -- vault operator unseal;done

  kubectl exec -ti vault-transit-0 -- vault login
  kubectl exec -ti vault-transit-0 -- vault secrets enable transit

  kubectl exec -ti vault-transit-0 -- vault write -f transit/keys/autounseal
  kubectl cp autounseal/autounseal.hcl vault-transit-0:/tmp
  kubectl exec -ti vault-transit-0 -- vault policy write autounseal /tmp/autounseal.hcl
  kubectl exec -ti vault-transit-0 -- vault token create -policy="autounseal" -wrap-ttl=120

  Key                              Value
  ---                              -----
  wrapping_token:                  s.2M06LPhYX4tSa8n2bBBWlzN9
  wrapping_accessor:               jNGpcZcel6IdBbbF5mvWIifS
  wrapping_token_ttl:              2m
  wrapping_token_creation_time:    2020-04-12 09:05:43.882065894 +0000 UTC
  wrapping_token_creation_path:    auth/token/create
  wrapped_accessor:                skQczoHqRc72HhmNWaqGLj28

  ```

  ```bash
  # создаем token для доступа к vault-transit и загружаем его, как k8s secrets vault-transit-token
  vault exec -ti vault-transit-0 -- /bin/sh
  vault token create -policy="autounseal" -wrap-ttl=120
  Key                              Value
  ---                              -----
  wrapping_token:                  s.IVei3NzI9bFvCRt2yzKv6vgq
  wrapping_accessor:               kvzO6TAfYmeNFJ6xLevuakoN
  wrapping_token_ttl:              2m
  wrapping_token_creation_time:    2020-04-12 09:13:39.69151688 +0000 UTC
  wrapping_token_creation_path:    auth/token/create
  wrapped_accessor:                k5zEeLEA3FihjJzdaPJI23fe

  $ VAULT_TOKEN="s.IVei3NzI9bFvCRt2yzKv6vgq" vault unwrap
  Key                  Value
  ---                  -----
  token                s.So8Um4d4XY23tTVJbUmyp7ZE
  token_accessor       k5zEeLEA3FihjJzdaPJI23fe
  token_duration       768h
  token_renewable      true
  token_policies       ["autounseal" "default"]
  identity_policies    []
  policies             ["autounseal" "default"]

  $ exit

  kubectl create secret generic vault-transit-token --from-literal=token='s.So8Um4d4XY23tTVJbUmyp7ZE'
  ```

  ```bash
  # устанавливаем vault со включенным unseal через transit

  helm upgrade --install vault ./vault-helm --values vault.values.yaml
  # если vault для которого настраивается unseal - новая инсталляция
  kubectl exec -ti vault-0 -- vault operator init -recovery-shares=1 -recovery-threshold=1
  Recovery Key 1: 2Ev9WRlPyPoheXuWWz+iXFzu3GKqqkg81cLzSLF5JsI=

  Initial Root Token: s.5xgwi0IuFquU8likGRG3Q8UO

  Success! Vault is initialized

  Recovery key initialized with 1 key shares and a key threshold of 1. Please
  securely distribute the key shares printed above.

  # если уже существует инсталляция, нужно сделать unseal migration
  kubectl exec -ti vault-0 -- vault operator unseal -migrate
  ```

  ```bash
  # Проверим, что unseal работает - удалим pod, контроллер пересоздаст новый и новый pod будет autounsealed
  kubectl delete pods/vault-0
  kubectl logs vault-0
  ==> Vault server configuration:

                Seal Type: transit
          Transit Address: https://vault-transit:8200
          Transit Key Name: autounseal
        Transit Mount Path: transit/
              Api Address: https://10.244.3.15:8200
                      Cgo: disabled
          Cluster Address: https://10.244.3.15:8201
                Listener 1: tcp (addr: "[::]:8200", cluster address: "[::]:8201", max_request_duration: "1m30s", max_request_size: "33554432", tls: "enabled")
                Log Level: info
                    Mlock: supported: true, enabled: false
            Recovery Mode: false
                  Storage: consul (HA available)
                  Version: Vault v1.3.3

  ==> Vault server started! Log data will stream in below:

  2020-04-12T10:02:20.326Z [INFO]  proxy environment: http_proxy= https_proxy= no_proxy=
  2020-04-12T10:02:20.326Z [WARN]  storage.consul: appending trailing forward slash to path
  2020-04-12T10:02:20.367Z [INFO]  core: stored unseal keys supported, attempting fetch
  2020-04-12T10:02:20.379Z [INFO]  core.cluster-listener: starting listener: listener_address=[::]:8201
  2020-04-12T10:02:20.379Z [INFO]  core.cluster-listener: serving cluster requests: cluster_listen_address=[::]:8201
  2020-04-12T10:02:20.380Z [INFO]  core: entering standby mode
  2020-04-12T10:02:20.381Z [INFO]  core: vault is unsealed
  2020-04-12T10:02:20.381Z [INFO]  core: unsealed with stored keys: stored_keys_used=1

  ```

## EX-13.3 Как проверить проект

* Сертификат nginx до обновления:
 ![nginx-before-renew](img/ex-13-kubernetes-vault-cert-1.png)

* Сертификат nginx после обновления:
![nginx-after-renew](img/ex-13-kubernetes-vault-cert-2.png)

## EX-13.4 Как начать пользоваться проектом
