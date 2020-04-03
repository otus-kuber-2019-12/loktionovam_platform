# EX-13 K8s + Vault

* [EX-13 K8s + Vault](#ex-13-k8s--vault)
  * [EX-13.1 Что было сделано](#ex-131-%d0%a7%d1%82%d0%be-%d0%b1%d1%8b%d0%bb%d0%be-%d1%81%d0%b4%d0%b5%d0%bb%d0%b0%d0%bd%d0%be)
  * [EX-13.2 Как запустить проект](#ex-132-%d0%9a%d0%b0%d0%ba-%d0%b7%d0%b0%d0%bf%d1%83%d1%81%d1%82%d0%b8%d1%82%d1%8c-%d0%bf%d1%80%d0%be%d0%b5%d0%ba%d1%82)
  * [EX-13.3 Как проверить проект](#ex-133-%d0%9a%d0%b0%d0%ba-%d0%bf%d1%80%d0%be%d0%b2%d0%b5%d1%80%d0%b8%d1%82%d1%8c-%d0%bf%d1%80%d0%be%d0%b5%d0%ba%d1%82)
  * [EX-13.4 Как начать пользоваться проектом](#ex-134-%d0%9a%d0%b0%d0%ba-%d0%bd%d0%b0%d1%87%d0%b0%d1%82%d1%8c-%d0%bf%d0%be%d0%bb%d1%8c%d0%b7%d0%be%d0%b2%d0%b0%d1%82%d1%8c%d1%81%d1%8f-%d0%bf%d1%80%d0%be%d0%b5%d0%ba%d1%82%d0%be%d0%bc)

## EX-13.1 Что было сделано

## EX-13.2 Как запустить проект

```bash
git clone https://github.com/hashicorp/consul-helm.git
helm install consul ./consul-helm
```

```bash
git clone https://github.com/hashicorp/vault-helm.git
helm upgrade --install vault ./vault-helm --values vault.values.yaml
```

```bash
helm status vault                                                                                                                                                                                                                                                         ─╯
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

```bash
kubectl exec -ti vault-0 -- vault operator init --key-shares=1 --key-threshold=1
Unseal Key 1: LJSyeNq1bVNZ86E7TlAUAjZg/6gMXMpPmGlYliv/abA=
Initial Root Token: s.zilTe4vzHF2lWwAlCxkoSaUQ


```

```bash
for POD_NUM in 0 1 2; do kubectl exec -it vault-"${POD_NUM}" -- vault operator unseal;done

kubectl exec -it vault-0 -- vault status                                                                                                                                                                                                                                  ─╯
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

```bash
kubectl exec -it vault-0 -- vault login                                                                                                                                                                                                                                         ─╯
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
kubectl exec -it vault-0 -- vault auth list                                                                                                                                                                                                                                     ─╯
Path      Type     Accessor               Description
----      ----     --------               -----------
token/    token    auth_token_e837ff1f    token based credentials
```

```bash
kubectl exec -it vault-0 -- vault secrets enable --path=otus kv
kubectl exec -it vault-0 -- vault secrets list --detailed
kubectl exec -it vault-0 -- vault kv put otus/otus-ro/config username='otus' password='asajkjkahs'
kubectl exec -it vault-0 -- vault kv put otus/otus-rw/config username='otus' password='asajkjkahs'

kubectl exec -it vault-0 -- vault read otus/otus-ro/config                                                                                                                                                                                                                ─╯
Key                 Value
---                 -----
refresh_interval    768h
password            asajkjkahs
username            otus

kubectl exec -it vault-0 -- vault kv get otus/otus-rw/config                                                                                                                                                                                                              ─╯
====== Data ======
Key         Value
---         -----
password    asajkjkahs
username    otus

```

```bash
kubectl exec -ti vault-0 -- vault auth enable kubernetes
kubectl exec -ti vault-0 -- vault auth list                                                                                                                                                                                                                               ─╯
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

* Consul template

```bash
kubectl apply -f consul-template/configmap-example-vault-agent-config.yaml
kubectl apply -f consul-template/example-k8s-spec.yml

# sidecar контейнер с consul template получил токен
kubectl exec -ti vault-agent-example -c consul-template -- cat /home/vault/.vault-token                                                                                                                                                                                   ─╯
s.o6WhySWAf27zQwF8Ygc6YDUw

# сходил в vault за секретами и отрендерил конфигурацию для nginx
kubectl exec -ti vault-agent-example -c consul-template  -- cat /etc/secrets/index.html                                                                                                                                                                                   ─╯
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
kubectl exec -ti vault-agent-example -c nginx-container  -- cat /usr/share/nginx/html/index.html                                                                                                                                                                          ─╯
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

## EX-13.3 Как проверить проект

## EX-13.4 Как начать пользоваться проектом
