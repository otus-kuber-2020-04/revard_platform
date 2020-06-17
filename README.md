
# Otus Kubernetes course

![Build Status](https://api.travis-ci.com/otus-kuber-2020-04/revard_platform.svg?branch=master)

---

## HW-10 Hashicorp Vault

![Build Status](https://api.travis-ci.com/otus-kuber-2020-04/revard_platform.svg?branch=kubernetes-vault)

### How to use

Clone repo. Change dir `cd kubernetes-vault`. Start minikube. Run commands bellow or you can try fire `run.sh` but not sure it works fine :) 

### Start

#### Install 

```
#Consul
git clone https://github.com/hashicorp/consul-helm.git
helm install consul consul-helm
#Vault 
git clone https://github.com/hashicorp/vault-helm.git
helm install vault vault-helm
```

#### Status

```
└─$> helm status vault
NAME: vault
LAST DEPLOYED: Mon Jun 15 15:43:31 2020
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
...

└─$> kubectl logs vault-0

WARNING! Unable to read storage migration status.
2020-06-15T12:43:44.026Z [INFO]  proxy environment: http_proxy= https_proxy= no_proxy=
2020-06-15T12:43:44.026Z [WARN]  storage.consul: appending trailing forward slash to path
2020-06-15T12:43:44.031Z [WARN]  storage migration check error: error="Unexpected response code: 500"
...
==> Vault server configuration:

             Api Address: http://10.60.0.5:8200
                     Cgo: disabled
         Cluster Address: https://vault-0.vault-internal:8201
              Listener 1: tcp (addr: "[::]:8200", cluster address: "[::]:8201", max_request_duration: "1m30s", max_request_size: "33554432", tls: "disabled")
               Log Level: info
                   Mlock: supported: true, enabled: false
           Recovery Mode: false
                 Storage: consul (HA available)
                 Version: Vault v1.4.2

==> Vault server started! Log data will stream in below:

2020-06-15T12:44:12.565Z [INFO]  core: seal configuration missing, not initialized
...

└─$> kubectl get po -l app.kubernetes.io/instance=vault
NAME                                    READY   STATUS    RESTARTS   AGE
vault-0                                 0/1     Running   0          16m
vault-1                                 0/1     Running   0          16m
vault-2                                 0/1     Running   0          16m
vault-agent-injector-7895bcdb5f-8svrd   1/1     Running   0          16m
```

Environments

```
└─$> kubectl exec -it vault-0 env | grep VAULT
kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl kubectl exec [POD] -- [COMMAND] instead.
VAULT_K8S_NAMESPACE=default
VAULT_ADDR=http://127.0.0.1:8200
VAULT_API_ADDR=http://10.60.0.5:8200
...
VAULT_ADDR=http://127.0.0.1:8200
```

#### Init

```
└─$> kubectl exec -it vault-0 -- vault operator init --key-shares=1 --key-threshold=1
Unseal Key 1: 1MCjYdZqt6/Kn8d65Ho/4Z47TckRXo7DGD4ncfQ6uRg=

Initial Root Token: s.375PxEXksPyzcmGCjcSexBBT
...

└─$> kubectl exec -it vault-0 -- vault status
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       1
Threshold          1
Unseal Progress    0/1
Unseal Nonce       n/a
Version            1.4.2
HA Enabled         true
command terminated with exit code 2
```

##### Unseal pods

```
kubectl exec -it vault-0 -- vault operator unseal '1MCjYdZqt6/Kn8d65Ho/4Z47TckRXo7DGD4ncfQ6uRg='
kubectl exec -it vault-1 -- vault operator unseal '1MCjYdZqt6/Kn8d65Ho/4Z47TckRXo7DGD4ncfQ6uRg='
kubectl exec -it vault-2 -- vault operator unseal '1MCjYdZqt6/Kn8d65Ho/4Z47TckRXo7DGD4ncfQ6uRg='

└─$> kubectl exec -it vault-0 -- vault status
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.4.2
Cluster Name    vault-cluster-ce97deb0
Cluster ID      cae726eb-8fc8-688e-4ba9-607539461b53
HA Enabled      true
HA Cluster      https://vault-0.vault-internal:8201
HA Mode         active
```

#### Auth

Try and get error

```
└─$>   kubectl exec -it vault-0 -- vault auth list
Error listing enabled authentications: Error making API request.

URL: GET http://127.0.0.1:8200/v1/sys/auth
Code: 400. Errors:

* missing client token
command terminated with exit code 2
```

Login

```
└─$> kubectl exec -it vault-0 -- vault login
Token (will be hidden): 
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                s.375PxEXksPyzcmGCjcSexBBT
token_accessor       OPOwyXTFocXNxMjCuoxWrQfj
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]

└─$> kubectl exec -it vault-0 -- vault auth list
Path      Type     Accessor               Description
----      ----     --------               -----------
token/    token    auth_token_d94e3444    token based credentials
```

Create secrets

```
kubectl exec -it vault-0 -- vault secrets enable --path=otus kv
kubectl exec -it vault-0 -- vault secrets list --detailed
kubectl exec -it vault-0 -- vault kv put otus/otus-ro/config username='otus' password='asajkjkahs'
kubectl exec -it vault-0 -- vault kv put otus/otus-rw/config username='otus' password='asajkjkahs'
kubectl exec -it vault-0 -- vault read otus/otus-ro/config
kubectl exec -it vault-0 -- vault kv get otus/otus-rw/config
```

Get secrets

```
└─$> kubectl exec -it vault-0 -- vault read otus/otus-ro/config
Key                 Value
---                 -----
refresh_interval    768h
password            asajkjkahs
username            otus
alf@alf-pad:~/revard_platform/kubernetes-vault (kubernetes-vault) 
└─$> kubectl exec -it vault-0 -- vault kv get otus/otus-rw/config
====== Data ======
Key         Value
---         -----
password    asajkjkahs
username    otus
```

##### Auth throught k8s

```
└─$> kubectl exec -it vault-0 -- vault auth enable kubernetes
Success! Enabled kubernetes auth method at: kubernetes/

└─$> kubectl exec -it vault-0 -- vault auth list
Path           Type          Accessor                    Description
----           ----          --------                    -----------
kubernetes/    kubernetes    auth_kubernetes_d2005c2f    n/a
token/         token         auth_token_d94e3444         token based credentials
```

Create Service Account vault-auth and apply ClusterRoleBinding

```
└─$> kubectl create serviceaccount vault-auth
serviceaccount/vault-auth created

└─$> kubectl apply --filename vault-auth-service-account.yml
clusterrolebinding.rbac.authorization.k8s.io/role-tokenreview-binding created
```

Prepare variables

```
export VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}")
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)
export K8S_HOST=$(more ~/.kube/config | grep server |awk '/http/ {print $NF}')
### alternative way
export K8S_HOST=$(kubectl cluster-info | grep 'Kubernetes master' | awk '/https/ {print $NF}' | sed 's/\x1b\[[0-9;]*m//g')
```

Write config in vault

```
└─$> kubectl exec -it vault-0 -- vault write auth/kubernetes/config \
token_reviewer_jwt="$SA_JWT_TOKEN" \
kubernetes_host="$K8S_HOST" \
kubernetes_ca_cert="$SA_CA_CRT"
Success! Data written to: auth/kubernetes/config
```

Create politic and role in vault

```
└─$> kubectl cp otus-policy.hcl vault-0:./tmp
 
└─$> kubectl exec -it vault-0 -- vault policy write otus-policy /tmp/otus-policy.hcl
Success! Uploaded policy: otus-policy

└─$> kubectl exec -it vault-0 -- vault write auth/kubernetes/role/otus \
bound_service_account_names=vault-auth \
bound_service_account_namespaces=default policies=otus-policy ttl=24h
Success! Data written to: auth/kubernetes/role/otus

```

#### Check auth

Create pod, install curl and jq
```
─$> kubectl run tmp --rm -i --tty --serviceaccount=vault-auth --image alpine:3.7
If you don't see a command prompt, try pressing enter.
/ # apk add curl jq
...
OK: 7 MiB in 19 packages
/ # VAULT_ADDR=http://vault:8200
/ # KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
/ # curl --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq
...
  "auth": {
    "client_token": "s.4Qyci2DxNUz0NGDbx5M4JTXa",
    "accessor": "UHgyyQayGcavTqq1B2ZuLWTp",
    "policies": [
      "default",
      "otus-policy"
    ],
    "token_policies": [
      "default",
      "otus-policy"
    ],
    "metadata": {
      "role": "otus",
      "service_account_name": "vault-auth",
      "service_account_namespace": "default",
      "service_account_secret_name": "vault-auth-token-jpz5q",
      "service_account_uid": "aa943883-af0a-11ea-abf5-42010a8400cf"
...
/ # TOKEN=$(curl -k -s --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq '.auth.client_token' | awk -F\" '{print $2}')
/ # echo $TOKEN
s.WpKYjRvofPFYTWNCKMGgu871

# Test read secrets 

/ # curl --header "X-Vault-Token:$TOKEN" $VAULT_ADDR/v1/otus/otus-ro/config
{"request_id":"1bbd2599-c70e-d7f5-1b0f-5656b23b16e4","lease_id":"","renewable":false,"lease_duration":2764800,"data":{"bar":"baz"},"wrap_info":null,"warnings":null,"auth":null}
/ # curl --header "X-Vault-Token:$TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config
{"request_id":"5a541e99-c2ff-52b4-0558-a17fac613ca5","lease_id":"","renewable":false,"lease_duration":2764800,"data":{"bar":"baz"},"wrap_info":null,"warnings":null,"auth":null}

# Test write secrets 

/ # curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:$TOKEN" $VAULT_ADDR/v1/otus/otus-ro/config
/ # curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:$TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config
/ # curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:$TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config1

/ # curl --header "X-Vault-Token:$TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config | jq
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
{ 0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
  "request_id": "02c335e9-6862-e08c-41ce-022d67d6e082",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 2764800,
  "data": {
    "bar": "baz"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
100   177  100   177    0     0   5900      0 --:--:-- --:--:-- --:--:--  5709
```

**NOTE** If you have `{"errors":["permission denied"]}` edit role policy file `otus-policy.hcl` and add more rights!

### Use case nginx authorization

#### The plan :)

1. Use vault-agent for authorization and get a client token

2. Using consul-template we get the secret and put it in nginx

3. Result - nginx got a secret from vault, not knowing anything about vault

#### Install

Used examples - https://github.com/hashicorp/vault-guides/tree/master/identity/vault-agent-k8s-demo

```
kubectl apply -f ./configs-k8s/example-vault-agent-config.yaml
kubectl apply -f ./configs-k8s/example-k8s-spec.yaml 
```

#### Test

```
└─$> kubectl get configmap example-vault-agent-config -o yaml
apiVersion: v1
data:
  vault-agent-config.hcl: |
    # Comment this out if running as sidecar instead of initContainer
    exit_after_auth = true

    pid_file = "/home/vault/pidfile"

    auto_auth {
        method "kubernetes" {
            mount_path = "auth/kubernetes"
            config = {
                role = "example"
            }
        }

        sink "file" {
            config = {
                path = "/home/vault/.vault-token"
            }
        }
    }

    template {
    destination = "/etc/secrets/index.html"
    contents = <<EOT
    <html>
    <body>
    <p>Some secrets:</p>
    {{- with secret "otus/otus-ro/config" }}
    <ul>
    <li><pre>username: {{ .Data.username }}</pre></li>
    <li><pre>password: {{ .Data.password }}</pre></li>
    </ul>
    {{ end }}
    </body>
    </html>
    EOT
    }
kind: ConfigMap
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","data":{"vault-agent-config.hcl":"# Comment this out if running as sidecar instead of initContainer\nexit_after_auth = true\n\npid_file = \"/home/vault/pidfile\"\n\nauto_auth {\n    method \"kubernetes\" {\n        mount_path = \"auth/kubernetes\"\n        config = {\n            role = \"example\"\n        }\n    }\n\n    sink \"file\" {\n        config = {\n            path = \"/home/vault/.vault-token\"\n        }\n    }\n}\n\ntemplate {\ndestination = \"/etc/secrets/index.html\"\ncontents = \u003c\u003cEOT\n\u003chtml\u003e\n\u003cbody\u003e\n\u003cp\u003eSome secrets:\u003c/p\u003e\n{{- with secret \"otus/otus-ro/config\" }}\n\u003cul\u003e\n\u003cli\u003e\u003cpre\u003eusername: {{ .Data.username }}\u003c/pre\u003e\u003c/li\u003e\n\u003cli\u003e\u003cpre\u003epassword: {{ .Data.password }}\u003c/pre\u003e\u003c/li\u003e\n\u003c/ul\u003e\n{{ end }}\n\u003c/body\u003e\n\u003c/html\u003e\nEOT\n}\n"},"kind":"ConfigMap","metadata":{"annotations":{},"name":"example-vault-agent-config","namespace":"default"}}
  creationTimestamp: "2020-06-16T09:01:54Z"
  name: example-vault-agent-config
  namespace: default
  resourceVersion: "11427"
  selfLink: /api/v1/namespaces/default/configmaps/example-vault-agent-config
  uid: 06b3cd10-afb0-11ea-aef5-42010a84006f

└─$> kubectl exec -ti vault-agent-example -c nginx-container  --  curl localhost
<html>
<body>
<p>Some secrets:</p>
<ul>
<li><pre>username: otus</pre></li>
<li><pre>password: asajkjkahs</pre></li>
</ul>

</body>
</html>
```

#### CA by vault

Pki secrets

```
└─$> kubectl exec -it vault-0 -- vault secrets enable pki
Success! Enabled the pki secrets engine at: pki/

└─$> kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki
Success! Tuned the secrets engine at: pki/

└─$> kubectl exec -it vault-0 -- vault write -field=certificate pki/root/generate/internal common_name="exmaple.ru" ttl=87600h > CA_cert.crt
```

URLs for CA and revoked CA

```
└─$> kubectl exec -it vault-0 -- vault write pki/config/urls issuing_certificates="http://vault:8200/v1/pki/ca" crl_distribution_points="http://vault:8200/v1/pki/crl"
Success! Data written to: pki/config/urls
```

Intermediate Cert

```
└─$> kubectl exec -it vault-0 -- vault secrets enable --path=pki_int pki
Success! Enabled the pki secrets engine at: pki_int/

└─$> kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki_int
Success! Tuned the secrets engine at: pki_int/

└─$> kubectl exec -it vault-0 -- vault write -format=json pki_int/intermediate/generate/internal  common_name="example.ru Intermediate Authority" | jq -r '.data.csr' > pki_intermediate.csr
```

Register Intermediate Cert in Vault

```
└─$> kubectl cp pki_intermediate.csr vault-0:./tmp

└─$> kubectl exec -it vault-0 -- vault write -format=json pki/root/sign-intermediate csr=@/tmp/pki_intermediate.csr format=pem_bundle ttl="43800h" | jq -r '.data.certificate' > intermediate.cert.pem

└─$> kubectl cp intermediate.cert.pem vault-0:./tmp

└─$> kubectl exec -it vault-0 -- vault write pki_int/intermediate/set-signed certificate=@/tmp/intermediate.cert.pem
Success! Data written to: pki_int/intermediate/set-signed
```

Create and revoke new certs

```
# Create role
└─$> kubectl exec -it vault-0 -- vault write pki_int/roles/example-dot-ru allowed_domains="example.ru" allow_subdomains=true max_ttl="720h"
Success! Data written to: pki_int/roles/example-dot-ru

#Create cert

─$> kubectl exec -it vault-0 -- vault write pki_int/issue/example-dot-ru common_name="gitlab.example.ru" ttl="24h"


Key                 Value
---                 -----
ca_chain            [-----BEGIN CERTIFICATE-----
MIIDnDCCAoSgAwIBAgIUNFm8g7lUz8LtvkJciCcsswfBjpIwDQYJKoZIhvcNAQEL
BQAwFTETMBEGA1UEAxMKZXhtYXBsZS5ydTAeFw0yMDA2MTYxNTEzNDlaFw0yNTA2
MTUxNTE0MTlaMCwxKjAoBgNVBAMTIWV4YW1wbGUucnUgSW50ZXJtZWRpYXRlIEF1
dGhvcml0eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAL3rcdL2tUDj
rloRMbKiir5nn4ARio4+LIre8pYneY0e0Jz8rhNDtVYU4iFCoRxir0z+NLVwxwg7
Z5dJ+qcJe31PRfc3NQqf7yoN2kZhhfWL30b0itUPL+ACblBQPA1/j81E0SPx2Bu0
DJghFaG2of0kgy+86Egn9g+eZLky4AlypKiDEMYBIfRMRJltDUS/ZhrpCYIrl9Dm
npanIBqpNL7S6CagXIK1Zuwr4WAXkoEvzNZzng+imO6+By5QctBlPO0ve4Z98K7J
R2u+n9cYBqT3p/7V3g8Mh0QyltAklj/aNtckHDnvuG/3WA9HcVTuwq0uZnCXDqz9
y1fsmT/nPDECAwEAAaOBzDCByTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUw
AwEB/zAdBgNVHQ4EFgQUHKcy9uwJT/jQwdCKLBn6blVolXYwHwYDVR0jBBgwFoAU
aZpBPL9TS5411c+6sbuJd1BxhiIwNwYIKwYBBQUHAQEEKzApMCcGCCsGAQUFBzAC
hhtodHRwOi8vdmF1bHQ6ODIwMC92MS9wa2kvY2EwLQYDVR0fBCYwJDAioCCgHoYc
aHR0cDovL3ZhdWx0OjgyMDAvdjEvcGtpL2NybDANBgkqhkiG9w0BAQsFAAOCAQEA
ICizXh6WHXEl+Z/O9/GhLAIIEirowt9k1lLdd/opEmQxKyiATQV3PR736NyaSKTv
35CEc4pxdeCzSgmkgo466f676Cg0diRvfbYrZlAbV5Hyrepe8GjkddcFDZKMMkP8
qCjFsYP6f0hTS+xt0U7Fig3FMNyV75o6S1jhAKx3NB3FNf+ydkTBUyHkb1N7yTs2
uPLoY6PWi1Wu4ddbceE+plIS47kvaSb8FoKCu4DcBlO7qF62b8Z2QHxPWdH/pFBX
oga/WQuXlPZAJViENAqmvTwc7janzOg4XYS0wtuZXM603hy0W0YEqke46WBjFohv
rddWlkJr1gsjwDGOh3xshw==
-----END CERTIFICATE-----]
certificate         -----BEGIN CERTIFICATE-----
MIIDZzCCAk+gAwIBAgIUM0hPFdEP27uFpe1hVOv6X17eG7MwDQYJKoZIhvcNAQEL
BQAwLDEqMCgGA1UEAxMhZXhhbXBsZS5ydSBJbnRlcm1lZGlhdGUgQXV0aG9yaXR5
MB4XDTIwMDYxNjE1NDUxNFoXDTIwMDYxNzE1NDU0NFowHDEaMBgGA1UEAxMRZ2l0
bGFiLmV4YW1wbGUucnUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDu
hP0czout0uxZa5jYx9vgtNTVI/sKLCHctdACcyJBQ6jkRxJGy3JP9hRIBCjtUV96
o1sbi2AE12vT/xtgjKBgv3CwMwlItm+/IUAp4aNYHQHdMXcEtzaqH34S2p+D23Ly
vQOROZw3J89Ip5P333bhkAybG0OEBLLIye9oN0W53WI5sueimkmPuyeQBdaFmWMe
FedUsC23SdQq98RF8JlIpDork2LwTgg7QeEFMaDXe6xiO+qJ4/v3IbgueIE46L1H
moejke4Dmvnqy5IM/bqNV/xL0Y9fgP+jpltp8YJEHECc1VLQxVWols5w3RPoYOMP
HC+ExMke6mpdn4lxkvPdAgMBAAGjgZAwgY0wDgYDVR0PAQH/BAQDAgOoMB0GA1Ud
JQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAdBgNVHQ4EFgQUZhDtd/qvEJH7GxkO
I4WZkrAdONUwHwYDVR0jBBgwFoAUHKcy9uwJT/jQwdCKLBn6blVolXYwHAYDVR0R
BBUwE4IRZ2l0bGFiLmV4YW1wbGUucnUwDQYJKoZIhvcNAQELBQADggEBACuataML
ub1mXHhYrfHwMFeOgXJaYotYoB74WzU2+M5WbBDqhbUl/sgFgzwT7wc/a7vf8DpI
CvhaWsOtFPnrPerAezWyGvdSRr+Lhsl4yz3YJZkmjJWHt/6ghMTz0LAZTwMC3gjC
D6+5OxMMUxZ7RiIoCZVMdjSxjGrOMvbcaM7uPXc//qtm2jEYfcPVNhnAoJUZ8TW0
1+U/isVba2nboTPi1uaWFfoMDKErV+hQblvjhmmdEZ6rclT9fGA9PufPiKy+2UkK
xsOljztOd+ppKg4JfjMYlp0V/ddIo6USoM2Q3w9sk2mNLxpBo4ocwgtUnwTgPS6M
7oYJ7Howl7Ef15A=
-----END CERTIFICATE-----
expiration          1592408744
issuing_ca          -----BEGIN CERTIFICATE-----
MIIDnDCCAoSgAwIBAgIUNFm8g7lUz8LtvkJciCcsswfBjpIwDQYJKoZIhvcNAQEL
BQAwFTETMBEGA1UEAxMKZXhtYXBsZS5ydTAeFw0yMDA2MTYxNTEzNDlaFw0yNTA2
MTUxNTE0MTlaMCwxKjAoBgNVBAMTIWV4YW1wbGUucnUgSW50ZXJtZWRpYXRlIEF1
dGhvcml0eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAL3rcdL2tUDj
rloRMbKiir5nn4ARio4+LIre8pYneY0e0Jz8rhNDtVYU4iFCoRxir0z+NLVwxwg7
Z5dJ+qcJe31PRfc3NQqf7yoN2kZhhfWL30b0itUPL+ACblBQPA1/j81E0SPx2Bu0
DJghFaG2of0kgy+86Egn9g+eZLky4AlypKiDEMYBIfRMRJltDUS/ZhrpCYIrl9Dm
npanIBqpNL7S6CagXIK1Zuwr4WAXkoEvzNZzng+imO6+By5QctBlPO0ve4Z98K7J
R2u+n9cYBqT3p/7V3g8Mh0QyltAklj/aNtckHDnvuG/3WA9HcVTuwq0uZnCXDqz9
y1fsmT/nPDECAwEAAaOBzDCByTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUw
AwEB/zAdBgNVHQ4EFgQUHKcy9uwJT/jQwdCKLBn6blVolXYwHwYDVR0jBBgwFoAU
aZpBPL9TS5411c+6sbuJd1BxhiIwNwYIKwYBBQUHAQEEKzApMCcGCCsGAQUFBzAC
hhtodHRwOi8vdmF1bHQ6ODIwMC92MS9wa2kvY2EwLQYDVR0fBCYwJDAioCCgHoYc
aHR0cDovL3ZhdWx0OjgyMDAvdjEvcGtpL2NybDANBgkqhkiG9w0BAQsFAAOCAQEA
ICizXh6WHXEl+Z/O9/GhLAIIEirowt9k1lLdd/opEmQxKyiATQV3PR736NyaSKTv
35CEc4pxdeCzSgmkgo466f676Cg0diRvfbYrZlAbV5Hyrepe8GjkddcFDZKMMkP8
qCjFsYP6f0hTS+xt0U7Fig3FMNyV75o6S1jhAKx3NB3FNf+ydkTBUyHkb1N7yTs2
uPLoY6PWi1Wu4ddbceE+plIS47kvaSb8FoKCu4DcBlO7qF62b8Z2QHxPWdH/pFBX
oga/WQuXlPZAJViENAqmvTwc7janzOg4XYS0wtuZXM603hy0W0YEqke46WBjFohv
rddWlkJr1gsjwDGOh3xshw==
-----END CERTIFICATE-----
private_key         -----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEA7oT9HM6LrdLsWWuY2Mfb4LTU1SP7Ciwh3LXQAnMiQUOo5EcS
RstyT/YUSAQo7VFfeqNbG4tgBNdr0/8bYIygYL9wsDMJSLZvvyFAKeGjWB0B3TF3
BLc2qh9+Etqfg9ty8r0DkTmcNyfPSKeT99924ZAMmxtDhASyyMnvaDdFud1iObLn
oppJj7snkAXWhZljHhXnVLAtt0nUKvfERfCZSKQ6K5Ni8E4IO0HhBTGg13usYjvq
ieP79yG4LniBOOi9R5qHo5HuA5r56suSDP26jVf8S9GPX4D/o6ZbafGCRBxAnNVS
0MVVqJbOcN0T6GDjDxwvhMTJHupqXZ+JcZLz3QIDAQABAoIBAAYYmguBb+p6aJYE
fPyVZxZAKOxlpgXliNwGPZHCdY6rdwaWlm3+xyYqCOyqRo2CNemBgVOb5VFaXCQn
8gAut+6hFfU66LLWDtcYt3YakT0wSJrpp7wUHq6MbYF32vnYwwBXOl8c1NRIDTEz
L0H3kSdEsj3InZojMJqXJqpIN1z/seA/OQXwa1CTSKuNqV4EO8c1xbat7CpVlRVK
25b+6+OfYgLcQfD14KOVwEj5Vv+ryoqymthkKS0wc0To/fbXXTeVG+M/H93CFW7g
aEXrLtzNnILhI+J4KfO+fGLCqEV6goPqBOMZ7HffwMAYN526Ij/LkV5TScxahogq
y/lJvAECgYEA9NAuHABSGSsXxY3zKKi88IvuplP0xPA1PU1kvrQGOJuT2NhxLVHr
TflQB9C6+Aj8Wj7LoAxX3bT3BNWfIkAB4tzv1CgH+qF02+rzQVMt8aHZvVis30CQ
sKjUA/1wOkOMrL7Kcm5P1iuuzyZ2zAxBnkXlluvzBSPGFZMtod90+wECgYEA+Wsv
UaVshnDGCf/h78i/cKtJgDU12sEBa8jzU4nj0sLgwFn4XN06l8yB1vRUbahSDIX+
zcboWCE2F9ui+wsJ/xr9UDzf08OqcZtNq50CQQ0LawtYOs14RJnbVsZdqmheq8w7
WxfnbS20FygENE4tBw0Zr2LEmk/Dc2epqwjqRN0CgYEAwUz7i2qJaIwJGhjqLWmG
vhyPVE+oTjQopX3NlXKKEvps8+R7AMDVHd1EXtdmOeDGeO9qUrZMTqfL/8o4+480
rg+rYoY1PqVroxXR+vuVpFwalBJHdYQCeyrjNT9Q9QBPPDrtmQsXCNG3FqOVW6o1
yaYBEXi+i4lip7htaIoLUQECgYEAn/q0GzZz6bekDv3luZuVz3rOZkG7DVkGxE/c
YxTq4GDHMBmFSGtODdfK4ElPbhasqgO4b9zJYt3KiHsEiumFu+9f03t4RagXR09J
/m1y6K6pSDu6l9z662WUXpBVu9u9/Yu99qvacRkDjmbIa5RJJWCtvOUpHaFTyE4R
cfcB7LECgYEA3HyAVxxP2ym1Hi+QJhqZrmv0gt8uKxE08WxlED3fc6L9AqMdrw5o
j9N5cPtSrezdVnJjchF1Zth7Z1kIyXdohF1J10MMmV9li9tjxV/AQUoZTHYHFy9S
qfbIzIISKPZDJ6etWKvzlLMjISYV1blgdcIGrlnY+iGQozt9YSA6t2s=
-----END RSA PRIVATE KEY-----
private_key_type    rsa
serial_number       33:48:4f:15:d1:0f:db:bb:85:a5:ed:61:54:eb:fa:5f:5e:de:1b:b3

# Revoke cert
└─$> kubectl exec -it vault-0 -- vault write pki_int/revoke serial_number="33:48:4f:15:d1:0f:db:bb:85:a5:ed:61:54:eb:fa:5f:5e:de:1b:b3"
Key                        Value
---                        -----
revocation_time            1592322419
revocation_time_rfc3339    2020-06-16T15:46:59.989504478Z
```

---

## HW-9 Logging

![Build Status](https://api.travis-ci.com/otus-kuber-2020-04/revard_platform.svg?branch=kubernetes-logging)

### How to use

Clone repo. Change dir `cd kubernetes-logging`. Start gce k8s. Run `run.sh`or commands bellow.

### GCE cluster

We need two pools: 

* default-pool 1 node

* infra-pool 3 nodes (taint GCP: node-role=infra:NoSchedule)

##### Tips 

```
# GCE taint
kubectl taint nodes gke-cluster-1-infra-pool-146ddf2e-4vj3 node-role=infra:NoSchedule
# Untaint
kubectl taint nodes gke-cluster-1-infra-pool-146ddf2e-4vj3  node-role:NoSchedule-
```

```
└─$> kubectl get nodes
NAME                                       STATUS   ROLES    AGE   VERSION
gke-cluster-1-default-pool-d3df1154-fp3r   Ready    <none>   18m   v1.14.10-gke.36
gke-cluster-1-infra-pool-14425da5-bwlh     Ready    <none>   18m   v1.14.10-gke.36
gke-cluster-1-infra-pool-14425da5-cjw9     Ready    <none>   18m   v1.14.10-gke.36
gke-cluster-1-infra-pool-14425da5-jfjg     Ready    <none>   18m   v1.14.10-gke.36
```

### Hipster-shop

#### Install

```
└─$> kubectl create ns microservices-demo
namespace/microservices-demo created

└─$> kubectl apply -f https://raw.githubusercontent.com/express42/otus-platform-snippets/master/Module-02/Logging/microservices-demo-without-resources.yaml -n microservices-demo
deployment.apps/emailservice created
service/emailservice created
deployment.apps/checkoutservice created
...

└─$> kubectl get pods -n microservices-demo -o wide
NAME                                     READY   STATUS              RESTARTS   AGE   IP           NODE                                       NOMINATED NODE   READINESS GATES
adservice-6898984d4c-wltk8               0/1     ContainerCreating   0          59s   <none>       gke-cluster-1-default-pool-d3df1154-fp3r   <none>           <none>
cartservice-86854d9586-xlc89             0/1     Completed           0          60s   10.60.2.12   gke-cluster-1-default-pool-d3df1154-fp3r   <none>           <none>
checkoutservice-85597d98b5-ltsft         1/1     Running             0          62s   10.60.2.9    gke-cluster-1-default-pool-d3df1154-fp3r   <none>           <none>
...
```

### ELK

#### Helm chart 

https://github.com/elastic/helm-charts

```
helm repo add elastic https://helm.elastic.co

kubectl create ns observability

# ElasticSearch
helm upgrade --install elasticsearch elastic/elasticsearch --namespace observability -f elasticsearch.values.yaml 
# Kibana
helm upgrade --install kibana elastic/kibana --namespace observability -f kibana.values.yaml 
# Fluent Bit
helm upgrade --install fluent-bit stable/fluent-bit --namespace observability -f fluentbit.values.yaml 
```

```
└─$> kubectl get pods -n observability -o wide -l chart=elasticsearch
NAME                     READY   STATUS    RESTARTS   AGE     IP          NODE                                     NOMINATED NODE   READINESS GATES
elasticsearch-master-0   1/1     Running   0          3m19s   10.20.3.2   gke-cluster-1-infra-pool-146ddf2e-kmtp   <none>           <none>
elasticsearch-master-1   1/1     Running   0          3m19s   10.20.1.2   gke-cluster-1-infra-pool-146ddf2e-5mgh   <none>           <none>
elasticsearch-master-2   1/1     Running   0          3m18s   10.20.0.2   gke-cluster-1-infra-pool-146ddf2e-4vj3   <none>           <none>
```

#### Nginx-ingress

```
kubectl create ns nginx-ingress
helm upgrade --install nginx-ingress stable/nginx-ingress --namespace=nginx-ingress -f nginx-ingress.values.yaml
```
![ElkPage](./kubernetes-logging/elk_dashboard.png)

#### Kibana

Web page by http://kibana.34.89.8.127.xip.io/

#### Fluent-bit

https://fluentbit.io/documentation/0.13/output/elasticsearch.html

https://github.com/helm/charts/blob/master/stable/fluent-bit/values.yaml

Duplicate @timestamp fields in elasticsearch output issue - https://github.com/fluent/fluent-bit/issues/628


### Monitoring 

#### Prometheus elasticsearch-exporter

https://github.com/justwatchcom/elasticsearch_exporter

```
helm upgrade --install prometheus-operator stable/prometheus-operator --namespace=observability

helm upgrade --install elasticsearch-exporter stable/elasticsearch-exporter --set es.uri=http://elasticsearch-master:9200 --set serviceMonitor.enabled=true --namespace=observability
```

Access grafana webpage (admin/prom-operator):
```
kubectl port-forward service/prometheus-operator-grafana 3000:80&
```

Install dashboard https://grafana.com/grafana/dashboards/4358

![GrafanaPage](./kubernetes-logging/grafana_elk_dashboard.png)

#### Loki

```
└─$> helm repo add loki https://grafana.github.io/loki/charts
"loki" has been added to your repositories

└─$> helm upgrade --install loki loki/loki-stack --namespace observability -f loki.values.yaml
```
![LokiPage](./kubernetes-logging/loki.png)

#### Status

```
└─$> kubectl get pods -n observability 
NAME                                                      READY   STATUS    RESTARTS   AGE
alertmanager-prometheus-operator-alertmanager-0           2/2     Running   0          3h23m
elasticsearch-exporter-c868cd459-6sn9j                    1/1     Running   0          3h19m
elasticsearch-master-0                                    1/1     Running   0          3h32m
elasticsearch-master-1                                    1/1     Running   0          3h32m
elasticsearch-master-2                                    1/1     Running   0          3h32m
fluent-bit-g5vsn                                          1/1     Running   0          3h26m
fluent-bit-zxjzq                                          1/1     Running   0          3h32m
kibana-kibana-b5b59bc46-dwsxg                             1/1     Running   0          3h32m
loki-0                                                    1/1     Running   0          127m
loki-promtail-58n9n                                       1/1     Running   0          127m
loki-promtail-lcqzm                                       1/1     Running   0          127m
loki-promtail-qlhfs                                       1/1     Running   0          127m
loki-promtail-zf2vk                                       1/1     Running   0          127m
prometheus-operator-grafana-6bc65b8fb6-69lgx              2/2     Running   0          3h23m
prometheus-operator-kube-state-metrics-59dd6cc4f8-trwrr   1/1     Running   0          3h29m
prometheus-operator-operator-8547d85c6f-q8ldv             2/2     Running   0          3h29m
prometheus-operator-prometheus-node-exporter-7fl76        1/1     Running   0          3h29m
prometheus-operator-prometheus-node-exporter-cqpnx        1/1     Running   0          3h29m
prometheus-operator-prometheus-node-exporter-s6kdm        1/1     Running   0          3h29m
prometheus-operator-prometheus-node-exporter-vtk85        1/1     Running   0          3h29m
prometheus-prometheus-operator-prometheus-0               3/3     Running   1          3h27m
```

#####  Tip useful util

Event logging | k8s-event-logger  https://github.com/max-rocket-internet/k8s-event-logger

---

## HW-8 Monitoring

![Build Status](https://api.travis-ci.com/otus-kuber-2020-04/revard_platform.svg?branch=kubernetes-monitoring)

### How to use

Clone repo. Change dir `cd kubernetes-monitoring`. Start minikube. Run commands bellow.

### Prometheus-operator

Install

```
└─$> helm upgrade --install prometheus-operator stable/prometheus-operator --create-namespace --namespace monitoring 
Release "prometheus-operator" does not exist. Installing it now.
...

└─$> kubectl get pods -n monitoring
NAME                                                     READY   STATUS    RESTARTS   AGE
alertmanager-prometheus-operator-alertmanager-0          2/2     Running   0          92s
prometheus-operator-grafana-64bcbf975f-mbdtj             2/2     Running   0          2m11s
prometheus-operator-kube-state-metrics-5fdcd78bc-jj5wg   1/1     Running   0          2m11s
prometheus-operator-operator-778d5d7b98-vkh55            2/2     Running   0          2m11s
prometheus-operator-prometheus-node-exporter-k4wdv       1/1     Running   0          2m11s
prometheus-prometheus-operator-prometheus-0              3/3     Running   1          82s
```

### Nginx app deployment

```
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f servicemonitor.yaml

└─$> kubectl get pods 
NAME                    READY   STATUS    RESTARTS   AGE
nginx-cc94594f8-ggtz5   2/2     Running   0          4m37s
nginx-cc94594f8-kddn9   2/2     Running   0          4m37s
nginx-cc94594f8-vrqzr   2/2     Running   0          4m37s

└─$> kubectl get service
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                       AGE
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP                       9m41s
nginx-app    NodePort    10.96.114.211   <none>        80:31978/TCP,9113:31605/TCP   4m47s
```

#### Port forward for test
```
kubectl port-forward service/prometheus-operator-grafana -n monitoring 3000:80&
kubectl port-forward service/nginx-app 9113:9113&
kubectl port-forward service/prometheus-operator-prometheus -n monitoring 9090:9090&
```


kubernetes.labels.app : nginx-ingress and status >= 200 and status <= 299

#### Grafana

##### !Tips! 

Get Graffana password.
```
─$> kubectl get secret prometheus-operator-grafana -o jsonpath='{.data.admin-password}' -n monitoring| base64 --decode
prom-operator
```
Install this dashboard in grafana https://github.com/nginxinc/nginx-prometheus-exporter/tree/master/grafana

### Results

Now we can see:

![GrafanaPage](./kubernetes-monitoring/grafana.png)
![MetricsPage](./kubernetes-monitoring/metrics.png)
![PrometheusPage](./kubernetes-monitoring/prometheus.png)

---

## HW-7 Operators

![Build Status](https://api.travis-ci.com/otus-kuber-2020-04/revard_platform.svg?branch=kubernetes-operators)

### How to use

Clone repo. Change dir `cd kubernetes-operators`. Start minikube. Run commands bellow.

### Palying with CRD

#### Create

```
└─$> kubectl apply -f deploy/crd.yml
customresourcedefinition.apiextensions.k8s.io/mysqls.otus.homework created

└─$> kubectl apply -f deploy/cr.yml
mysql.otus.homework/mysql-instance created
```

#### Check

```
└─$> kubectl get crd
NAME                   CREATED AT
mysqls.otus.homework   2020-06-03T08:20:18Z

└─$> kubectl get mysqls.otus.homework
NAME             AGE
mysql-instance   16s

└─$> kubectl describe mysqls.otus.homework mysql-instance
Name:         mysql-instance
Namespace:    default
Labels:       <none>
Annotations:  API Version:  otus.homework/v1
Kind:         MySQL
Metadata:
  Creation Timestamp:  2020-06-03T08:20:28Z
  Generation:          1
...
```

### MySQL controller

#### Run controller

```
└─$> kopf run mysql-operator.py
[2020-06-03 21:35:37,142] kopf.reactor.activit [INFO    ] Initial authentication has been initiated.
[2020-06-03 21:35:37,158] kopf.activities.auth [INFO    ] Handler 'login_via_pykube' succeeded.
[2020-06-03 21:35:37,182] kopf.activities.auth [INFO    ] Handler 'login_via_client' succeeded.
[2020-06-03 21:35:37,182] kopf.reactor.activit [INFO    ] Initial authentication has finished.
[2020-06-03 21:35:37,200] kopf.engines.peering [WARNING ] Default peering object not found, falling back to the standalone mode.

# After kubectl apply -f deploy/cr.yml

mysql-operator.py:28: YAMLLoadWarning: calling yaml.load() without Loader=... is deprecated, as the default Loader is unsafe. Please read https://msg.pyyaml.org/load for full details.
  json_manifest = yaml.load(yaml_manifest)
{'api_version': 'v1',
 'kind': 'PersistentVolume',
...
 'status': {'message': None, 'phase': 'Pending', 'reason': None}}
[2020-06-03 22:20:29,447] kopf.objects         [INFO    ] [default/mysql-instance] Handler 'mysql_on_create' succeeded.
[2020-06-03 22:20:29,448] kopf.objects         [INFO    ] [default/mysql-instance] All handlers succeeded for creation.
start deletion
job with backup-mysql-instance-job  found,wait untill end
job with backup-mysql-instance-job  found,wait untill end
job with backup-mysql-instance-job  success

# After kubectl delete mysqls.otus.homework mysql-instance

[2020-06-03 22:24:54,522] kopf.objects         [INFO    ] [default/mysql-instance] Handler 'delete_object_make_backup' succeeded.
[2020-06-03 22:24:54,523] kopf.objects         [INFO    ] [default/mysql-instance] All handlers succeeded for deletion.
```

#### Install

!Tip!

If you will get bug with `pvc pending` you need to disable addon:
```
└─$> minikube addons disable default-storageclass
🌑  "The 'default-storageclass' addon is disabled
```

Now create
```
└─$> kubectl apply -f deploy/cr.yml
mysql.otus.homework/mysql-instance created

└─$> kubectl get pv
NAME                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                               STORAGECLASS   REASON   AGE
backup-mysql-instance-pv   1Gi        RWO            Retain           Bound    default/backup-mysql-instance-pvc                           11s
mysql-instance-pv          1Gi        RWO            Retain           Bound    default/mysql-instance-pvc                                  11s
alf@alf-pad:~/revard_platform/kubernetes-operators (kubernetes-operators) 
└─$> kubectl get pvc
NAME                        STATUS   VOLUME                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
backup-mysql-instance-pvc   Bound    backup-mysql-instance-pv   1Gi        RWO                           14s
mysql-instance-pvc          Bound    mysql-instance-pv          1Gi        RWO                           14s
```

#### Test MySQL DB

```
└─$> export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="
> {.items[*].metadata.name}")

└─$> kubectl exec -it $MYSQLPOD -- mysql -u root -potuspassword -e "CREATE TABLE test (
> id smallint unsigned not null auto_increment, name varchar(20) not null, constraint
> pk_example primary key (id) );" otus-database
mysql: [Warning] Using a password on the command line interface can be insecure.

└─$> kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name
> ) VALUES ( null, 'some data' );" otus-database
mysql: [Warning] Using a password on the command line interface can be insecure.
 
└─$> kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name )
> VALUES ( null, 'some data-2' );" otus-database
mysql: [Warning] Using a password on the command line interface can be insecure.

└─$> kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
mysql: [Warning] Using a password on the command line interface can be insecure.
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
+----+-------------+
```

Try delete main DB
```
└─$> kubectl delete mysqls.otus.homework mysql-instance
mysql.otus.homework "mysql-instance" deleted

└─$> kubectl get pv
NAME                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                               STORAGECLASS   REASON   AGE
backup-mysql-instance-pv   1Gi        RWO            Retain           Bound    default/backup-mysql-instance-pvc                           5m42s

└─$> kubectl get jobs.batch
NAME                         COMPLETIONS   DURATION   AGE
backup-mysql-instance-job    1/1           2s         119s
restore-mysql-instance-job   1/1           6m22s      6m22s
```

Recreate main DB and get all back
```
└─$> kubectl apply -f deploy/cr.yml 
mysql.otus.homework/mysql-instance created

└─$> export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="
> {.items[*].metadata.name}")

└─$> kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
mysql: [Warning] Using a password on the command line interface can be insecure.
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
+----+-------------+
```

#### Delete all

```
kubectl delete mysqls.otus.homework mysql-instance
kubectl delete deployments.apps mysql-instance
kubectl delete pvc mysql-instance-pvc
kubectl delete pv mysql-instance-pv
kubectl delete svc mysql-instance
```

#### Docker image

Build image
```
cd build
docker build --tag=revard/mysql-operator:v0.1 .
dpclet login
docker push revard/mysql-operator:v0.1
```

Test
```
└─$> kubectl apply -f ./deploy/service-account.yml
serviceaccount/mysql-operator created

└─$> kubectl apply -f ./deploy/role.yml 
clusterrole.rbac.authorization.k8s.io/mysql-operator created

└─$> kubectl apply -f ./deploy/role-binding.yml
clusterrolebinding.rbac.authorization.k8s.io/workshop-operator created

└─$> kubectl apply -f ./deploy/deploy-operator.yml 
deployment.apps/mysql-operator created

└─$> kubectl get pvc
NAME                        STATUS   VOLUME                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
backup-mysql-instance-pvc   Bound    backup-mysql-instance-pv   1Gi        RWO                           34m
mysql-instance-pvc          Bound    mysql-instance-pv          1Gi        RWO                           27m

└─$> export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="
> {.items[*].metadata.name}")

└─$> kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
mysql: [Warning] Using a password on the command line interface can be insecure.
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
+----+-------------+
```

Delete DB
```
└─$> kubectl delete mysqls.otus.homework mysql-instance
mysql.otus.homework "mysql-instance" deleted

└─$> kubectl get pv
NAME                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS        CLAIM                               STORAGECLASS   REASON   AGE
backup-mysql-instance-pv   1Gi        RWO            Retain           Bound         default/backup-mysql-instance-pvc                           36m

└─$> kubectl get jobs.batch
NAME                         COMPLETIONS   DURATION   AGE
backup-mysql-instance-job    1/1           2s         2m27s
```

Restore DB
```
└─$> kubectl apply -f deploy/cr.yml 
mysql.otus.homework/mysql-instance created

└─$> export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="
> {.items[*].metadata.name}")

└─$> kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
mysql: [Warning] Using a password on the command line interface can be insecure.
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
+----+-------------+

└─$> kubectl get jobs.batch
NAME                         COMPLETIONS   DURATION   AGE
backup-mysql-instance-job    1/1           2s         3m42s
restore-mysql-instance-job   1/1           49s        113s
```

---

## HW-6 Templates

![Build Status](https://api.travis-ci.com/otus-kuber-2020-04/revard_platform.svg?branch=kubernetes-templating)

### How to use

Clone repo. Change dir `cd kubernetes-templates`. Run commands bellow.

### GCP Kubernetes

https://cloud.google.com/kubernetes-engine/

https://cloud.google.com/compute/docs/instances/interacting-with-serial-console

Create new cluster on gCP.

#### Install gcloud

https://cloud.google.com/sdk/docs/quickstart-linux

Connect by using command from button `connect` on cluster page.
```
└─$> gcloud container clusters get-credentials cluster-1 --zone europe-west1-b --project otus-kuber-*****
Fetching cluster endpoint and auth data.
kubeconfig entry generated for cluster-1.
```

#### Check

```
└─$>  kubectl config current-context
gke_otus-kuber-*****_europe-west1-b_cluster-1

└─$> gcloud beta container clusters get-credentials cluster-1 
Fetching cluster endpoint and auth data.
kubeconfig entry generated for cluster-1.
```

### Helm

#### Tips

Create release:
```
$ helm install <chart_name> --name=<release_name> --namespace=<namespace>
$ kubectl get secrets -n <namespace> | grep <release_name>
sh.helm.release.v1.<release_name>.v1 helm.sh/release.v1 1 115m
```

Update release:
```
$ helm upgrade <release_name> <chart_name> --namespace=<namespace>
$ kubectl get secrets -n <namespace> | grep <release_name>
sh.helm.release.v1.<release_name>.v1 helm.sh/release.v1 1 115m
sh.helm.release.v1.<release_name>.v2 helm.sh/release.v1 1 56m
```

Create or update release:
```
$ helm upgrade --install <release_name> <chart_name> --namespace=<namespace>
$ kubectl get secrets -n <namespace> | grep <release_name>
sh.helm.release.v1.<release_name>.v1 helm.sh/release.v1 1 115m
sh.helm.release.v1.<release_name>.v2 helm.sh/release.v1 1 56m
sh.helm.release.v1.<release_name>.v3 helm.sh/release.v1 1 5s
```

#### Install

https://github.com/helm/helm#install

#### Add google repo

```
└─$> helm repo add stable https://kubernetes-charts.storage.googleapis.com
"stable" has been added to your repositories

└─$> helm repo list
NAME    	URL                                             
stable  	https://kubernetes-charts.storage.googleapis.com

```

### Helm charts

https://github.com/helm/charts/tree/master/stable/nginx-ingress

https://github.com/jetstack/cert-manager/tree/master/deploy/charts/cert-manager

https://github.com/helm/charts/tree/master/stable/chartmuseum

https://github.com/goharbor/harbor-helm

#### Ingress

* Create namespaces and releases

```
└─$> kubectl create ns nginx-ingress
namespace/nginx-ingress created

└─$> helm upgrade --install nginx-ingress stable/nginx-ingress --wait \
 --namespace=nginx-ingress \
 --version=1.11.1
Release "nginx-ingress" does not exist. Installing it now.
NAME: nginx-ingress
LAST DEPLOYED: Fri May 29 15:07:12 2020
NAMESPACE: nginx-ingress
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The nginx-ingress controller has been installed.
It may take a few minutes for the LoadBalancer IP to be available.
You can watch the status by running 'kubectl --namespace nginx-ingress get services -o wide -w nginx-ingress-controller'
...
```


#### Cert-manager

Add repo
```
└─$> helm repo add jetstack https://charts.jetstack.io
"jetstack" has been added to your repositories
```

Create CRD https://github.com/jetstack/cert-manager/tree/master/deploy/charts/cert-manager
```
└─$> kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.9/deploy/manifests/00-crds.yaml
customresourcedefinition.apiextensions.k8s.io/certificates.certmanager.k8s.io created
customresourcedefinition.apiextensions.k8s.io/certificaterequests.certmanager.k8s.io created
customresourcedefinition.apiextensions.k8s.io/challenges.certmanager.k8s.io created
customresourcedefinition.apiextensions.k8s.io/clusterissuers.certmanager.k8s.io created
customresourcedefinition.apiextensions.k8s.io/issuers.certmanager.k8s.io created
customresourcedefinition.apiextensions.k8s.io/orders.certmanager.k8s.io created
```

Setup
```
└─$> kubectl create ns cert-manager
namespace/cert-manager created

└─$> kubectl label namespace cert-manager certmanager.k8s.io/disable-validation="true"
namespace/cert-manager labeled
```

Install
```
└─$> helm upgrade --install cert-manager jetstack/cert-manager --wait \
 --namespace=cert-manager \
 --version=0.9.0
Release "cert-manager" does not exist. Installing it now.
NAME: cert-manager
LAST DEPLOYED: Fri May 29 15:23:01 2020
NAMESPACE: cert-manager
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
cert-manager has been deployed successfully!
...
```

#####   

For correct work need to create issuer 

https://cert-manager.io/docs/installation/kubernetes/#configuring-your-first-issuer

https://docs.cert-manager.io/en/release-0.11/tasks/issuers/index.html

```
└─$> kubectl apply -f ./cert-manager/issuer-letsencrypt.yaml 
clusterissuer.certmanager.k8s.io/issuer-letsencrypt created

└─$> kubectl describe ClusterIssuer 
Name:         issuer-letsencrypt
Namespace:    
Labels:       <none>
Annotations:  API Version:  certmanager.k8s.io/v1alpha1
Kind:         ClusterIssuer
Metadata:
  Creation Timestamp:  2020-05-29T12:44:00Z
  Generation:          2
  Resource Version:    15429
  Self Link:           /apis/certmanager.k8s.io/v1alpha1/clusterissuers/issuer-letsencrypt
  UID:                 11ef9bd0-a1aa-11ea-bde0-42010a840235
...
```

#### Chartmuseum

https://github.com/helm/charts/tree/master/stable/chartmuseum

https://github.com/helm/charts/blob/master/stable/chartmuseum/values.yaml

##### Install
```
└─$> kubectl create ns chartmuseum
namespace/chartmuseum created

└─$> helm upgrade --install chartmuseum stable/chartmuseum --wait --namespace=chartmuseum --version=2.3.2 -f chartmuseum/values.yaml
Release "chartmuseum" does not exist. Installing it now.
NAME: chartmuseum
LAST DEPLOYED: Sat May 30 09:36:28 2020
NAMESPACE: chartmuseum
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
** Please be patient while the chart is being deployed **

Get the ChartMuseum URL by running:

  export POD_NAME=$(kubectl get pods --namespace chartmuseum -l "app=chartmuseum" -l "release=chartmuseum" -o jsonpath="{.items[0].metadata.name}")
  echo http://127.0.0.1:8080/
  kubectl port-forward $POD_NAME 8080:8080 --namespace chartmuseum
```

##### Check
```
└─$> helm ls -n chartmuseum
NAME       	NAMESPACE  	REVISION	UPDATED                                	STATUS  	CHART            	APP VERSION
chartmuseum	chartmuseum	1       	2020-05-30 16:37:48.617500332 +0300 MSK	deployed	chartmuseum-2.3.2	0.8.2  

└─$> curl https://$(kubectl get ingress chartmuseum-chartmuseum -n chartmuseum -o jsonpath={.spec.rules[0].host})
...
<title>Welcome to ChartMuseum!</title>
...
```

##### How to use Chartmuseum (*)

```
└─$> helm repo add chartmuseum https://chartmuseum.104.155.101.164.nip.io/
"chartmuseum" has been added to your repositories

└─$> helm repo list
NAME       	URL                                             
stable     	https://kubernetes-charts.storage.googleapis.com
jetstack   	https://charts.jetstack.io                      
chartmuseum	https://chartmuseum.104.155.101.164.nip.io/     


└─$> helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "chartmuseum" chart repository
...Successfully got an update from the "stable" chart repository
...Successfully got an update from the "jetstack" chart repository
Update Complete. ⎈ Happy Helming!⎈ 

└─$> helm pull stable/chartmuseum --version=2.3.2

└─$> curl -L --data-binary "@chartmuseum-2.3.2.tgz" https://chartmuseum.104.155.101.164.nip.io/api/charts
{"saved":true}
```

![ChartmuseumPage](./kubernetes-templating/chartmuseum.png)

### Harbor

https://github.com/goharbor/harbor-helm

#### Install

  ```
└─$> helm repo add harbor https://helm.goharbor.io
"harbor" has been added to your repositories

└─$> kubectl create ns harbor
namespace/harbor created

└─$> helm upgrade --install harbor harbor/harbor --wait --namespace=harbor --version=1.1.2 -f harbor/values.yaml
Release "harbor" does not exist. Installing it now.
NAME: harbor
LAST DEPLOYED: Sun May 31 10:11:44 2020
NAMESPACE: harbor
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Please wait for several minutes for Harbor deployment to complete.
Then you should be able to visit the Harbor portal at https://harbor.104.155.101.164.nip.io. 
For more details, please visit https://github.com/goharbor/harbor.

└─$> kubectl get secrets -n harbor -l owner=helm
NAME                           TYPE                 DATA   AGE
sh.helm.release.v1.harbor.v1   helm.sh/release.v1   1      15m
```

#### Status

```
└─$> helm ls -n harbor
NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
harbor  harbor          1               2020-05-31 10:11:44.202733384 +0300 MSK deployed        harbor-1.1.2    1.8.2     

└─$> curl https://$(kubectl get ingress harbor-harbor-ingress -n harbor -o jsonpath={.spec.rules[0].host})
...
    <title>Harbor</title>
...
```

![HarborPage](./kubernetes-templating/harbor.png)

### Helm chart

We will use https://github.com/GoogleCloudPlatform/microservices-demo

#### Install 

Init structure
```
└─$> helm create hipster-shop
Creating hipster-shop
```

Install
```
└─$> kubectl create ns hipster-shop
namespace/hipster-shop created

└─$> helm upgrade --install hipster-shop ./hipster-shop --namespace hipster-shop
Release "hipster-shop" does not exist. Installing it now.
NAME: hipster-shop
LAST DEPLOYED: Sun May 31 10:46:23 2020
NAMESPACE: hipster-shop
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

##### Check

1. Using firewall rule for PortNode
```
└─$> gcloud compute firewall-rules create test-node-port --allow tcp:$(kubectl get svc/frontend -n hipster-shop -o jsonpath={.spec.ports[0].nodePort})
Creating firewall...⠹Created [https://www.googleapis.com/compute/v1/projects/otus-kuber-278614/global/firewalls/test-node-port].                                                                    
Creating firewall...done.                                                                                                                                                                           
NAME            NETWORK  DIRECTION  PRIORITY  ALLOW      DENY  DISABLED
test-node-port  default  INGRESS    1000      tcp:32145        False

└─$> curl -v http://$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}'):$(kubectl get svc/frontend -n hipster-shop -o jsonpath={.spec.ports[0].nodePort})
*   Trying 34.78.55.255:32145...
* TCP_NODELAY set
* Connected to 34.78.55.255 (34.78.55.255) port 32145 (#0)
> GET / HTTP/1.1
> Host: 34.78.55.255:32145
> User-Agent: curl/7.68.0
> Accept: */*
...

```

2. Using ingress for example
```
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: hipstershop-frontend
spec:
  rules:
    - host: shop.YOUR_IP.nip.io
      http:
        paths:
          - path: /
            backend:
              serviceName: frontend
              servicePort: 80

└─$> curl http://$(kubectl get ingress frontend -n hipster-shop -o jsonpath={.spec.rules[0].host})              
```

#### Helm chart for frontend app

Config in dir `frontend`.

Update helm pkg dependencies
```
└─$> helm dep update ./hipster-shop
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "harbor" chart repository
...Successfully got an update from the "jetstack" chart repository
...Successfully got an update from the "chartmuseum" chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈Happy Helming!⎈
Saving 1 charts
Deleting outdated charts
```

Test
```
└─$> helm upgrade --install frontend ./frontend/ --namespace hipster-shop
Release "frontend" has been upgraded. Happy Helming!
NAME: frontend
LAST DEPLOYED: Sun May 31 20:53:16 2020
NAMESPACE: hipster-shop
STATUS: deployed
REVISION: 7
TEST SUITE: None
```

### Kubecfg

Install `kubecfg` by using manual https://github.com/bitnami/kubecfg

Jsonnet guestbook kubecfg:

https://github.com/bitnami/kubecfg/blob/master/examples/guestbook.jsonnet

https://github.com/bitnami-labs/kube-libsonnet/raw/52ba963ca44f7a4960aeae9ee0fbee44726e481f/kube.libsonnet

#### Check

```
└─$> kubecfg show kubecfg/services.jsonnet 
---
apiVersion: v1
kind: Service
...
```

#### Install 

```
└─$> kubecfg update ./kubecfg/services.jsonnet --namespace hipster-shop
INFO  Validating deployments paymentservice
INFO  validate object "apps/v1beta2, Kind=Deployment"
INFO  Validating services paymentservice
INFO  validate object "/v1, Kind=Service"
INFO  Validating deployments shippingservice
INFO  validate object "apps/v1beta2, Kind=Deployment"
INFO  Validating services shippingservice
INFO  validate object "/v1, Kind=Service"
INFO  Fetching schemas for 4 resources
INFO  Creating services paymentservice
INFO  Creating services shippingservice
INFO  Creating deployments paymentservice
INFO  Creating deployments shippingservice
```

All work fine!

```
└─$> helm ls -n hipster-shop
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
hipster-shop    hipster-shop    4               2020-06-01 14:28:24.588606156 +0300 MSK deployed        hipster-shop-0.1.0      1.16.0   

└─$> curl http://$(kubectl get ingress hipstershop-frontend -n hipster-shop -o jsonpath={.spec.rules[0].host})

<!DOCTYPE html>
...
    <title>Hipster Shop</title>
...
```
![HipstershopPage](./kubernetes-templating/hipster-shop.png)

### Kustomize

https://kubectl.docs.kubernetes.io/pages/app_customization/introduction.html

#### Run

```
└─$> kubectl apply -f ./kustomize/overlays/hipster-shop-prod/namespace.yaml 
namespace/hipster-shop-prod created

└─$> kubectl apply -k ./kustomize/overlays/hipster-shop-prod/
service/prod-adservice created
deployment.apps/prod-adservice created
```

#### Check

```
└─$> kubectl get service -n hipster-shop-prod
NAME             TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
prod-adservice   ClusterIP   10.8.11.177   <none>        9555/TCP   81s
```

---

## HW-5 Volumes

![Build Status](https://api.travis-ci.com/otus-kuber-2020-04/revard_platform.svg?branch=kubernetes-volumes)

### How to use

Clone repo. Change dir `cd kubernetes-volumes`. Run commands bellow.

Run kind
```
kind create cluster
kind export kubeconfig

```
### Minio 

https://min.io/

#### Install
```
└─$> kubectl apply -f https://raw.githubusercontent.com/express42/otus-platform-snippets/master/Module-02/Kuberenetes-volumes/minio-statefulset.yaml
statefulset.apps/minio created

└─$> kubectl apply -f https://raw.githubusercontent.com/express42/otus-platform-snippets/master/Module-02/Kuberenetes-volumes/minio-headless-service.yaml
service/minio created
```

#### Check 

Can use https://github.com/minio/mc

or
```
└─$> kubectl get statefulsets
NAME    READY   AGE
minio   1/1     37m

└─$> kubectl get pods
NAME      READY   STATUS    RESTARTS   AGE
minio-0   1/1     Running   0          37m

└─$> kubectl get pvc
NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
data-minio-0   Bound    pvc-b6cecf15-075b-4e44-85ed-d4d35c7520d4   10Gi       RWO            standard       38m

└─$> kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                  STORAGECLASS   REASON   AGE
pvc-b6cecf15-075b-4e44-85ed-d4d35c7520d4   10Gi       RWO            Delete           Bound    default/data-minio-0   standard                38m

# detailed info
kubectl describe <resource> <resource_name>
```

### Secret

https://kubernetes.io/docs/concepts/configuration/secret/


Generate
```
└─$> echo -n 'minio' | base64
bWluaW8=

└─$> echo -n 'minio123' | base64
bWluaW8xMjM=
```

Aplly
```
─$> kubectl apply -f ./minio-secret.yaml
secret/minio-secret created

└─$> kubectl get secrets
NAME                  TYPE                                  DATA   AGE
default-token-4n8gw   kubernetes.io/service-account-token   3      6h46m
minio-secret          Opaque                                2      3s
```

---

## HW-4 Networks

![Build Status](https://api.travis-ci.com/otus-kuber-2020-04/revard_platform.svg?branch=kubernetes-networks)

### How to use

Clone repo. Start minicube. Change dir `cd kubernetes-networks`. Run commands bellow.

### Playing with web app

#### Test deployment with `maxSurge` and `maxUnavailable`

You can use kubespy for monitoring https://github.com/pulumi/kubespy

We change paramters and image version than run `kubectl apply -f web-deploy.yaml`

Check events `kubectl get events --watch | egrep "SuccessfulDelete|SuccessfulCreate|Killing|Started"`

##### maxSurge - 0, maxUnavailable -0 

```
└─$> kubectl apply -f web-deploy.yaml 
The Deployment "web" is invalid: spec.strategy.rollingUpdate.maxUnavailable: Invalid value: intstr.IntOrString{Type:0, IntVal:0, StrVal:""}: may not be 0 when `maxSurge` is 0
```

##### maxSurge - 100, maxUnavailable - 100 

```
0s          Normal    Killinga             pod/web-68466c4fd7-5c86c    Stopping container web
0s          Normal    Killing             pod/web-68466c4fd7-tv7tb    Stopping container web
0s          Normal    Killing             pod/web-68466c4fd7-s8x7v    Stopping container web
0s          Normal    Started             pod/web-6d7d49c47d-tnqfr    Started container html-gen
0s          Normal    Started             pod/web-6d7d49c47d-649c8    Started container html-gen
0s          Normal    Started             pod/web-6d7d49c47d-q5cwf    Started container html-gen
0s          Normal    Started             pod/web-6d7d49c47d-tnqfr    Started container web
0s          Normal    Started             pod/web-6d7d49c47d-649c8    Started container web
0s          Normal    Started             pod/web-6d7d49c47d-q5cwf    Started container web
```

##### maxSurge - 100, maxUnavailable - 0 

```
0s          Normal    Started             pod/web-68466c4fd7-hmbtg    Started container html-gen
0s          Normal    Started             pod/web-68466c4fd7-5d9xz    Started container html-gen
0s          Normal    Started             pod/web-68466c4fd7-97q8b    Started container html-gen
0s          Normal    Started             pod/web-68466c4fd7-hmbtg    Started container web
0s          Normal    Started             pod/web-68466c4fd7-97q8b    Started container web
0s          Normal    Started             pod/web-68466c4fd7-5d9xz    Started container web
0s          Normal    Killing             pod/web-6d7d49c47d-tnqfr    Stopping container web
0s          Normal    Killing             pod/web-6d7d49c47d-649c8    Stopping container web
0s          Normal    Killing             pod/web-6d7d49c47d-q5cwf    Stopping container web
```

##### maxSurge - 0, maxUnavailable - 100 

```
0s          Normal    Killing             pod/web-68466c4fd7-5d9xz    Stopping container web
0s          Normal    SuccessfulDelete    replicaset/web-68466c4fd7   (combined from similar events): Deleted pod: web-68466c4fd7-5d9xz
0s          Normal    Killing             pod/web-68466c4fd7-hmbtg    Stopping container web
0s          Normal    Killing             pod/web-68466c4fd7-97q8b    Stopping container web
0s          Normal    Started             pod/web-6d7d49c47d-7szcn    Started container html-gen
0s          Normal    Started             pod/web-6d7d49c47d-7hkvm    Started container html-gen
0s          Normal    Started             pod/web-6d7d49c47d-pbtqd    Started container html-gen
0s          Normal    Started             pod/web-6d7d49c47d-7szcn    Started container web
0s          Normal    Started             pod/web-6d7d49c47d-pbtqd    Started container web
0s          Normal    Started             pod/web-6d7d49c47d-7hkvm    Started container web
```

### Service

#### ClisterIP

Run service
```
└─$> kubectl apply -f web-svc-cip.yaml 
service/web-svc-cip created

└─$>  kubectl get services
NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
kubernetes    ClusterIP   10.96.0.1       <none>        443/TCP   17d
web-svc-cip   ClusterIP   10.103.101.59   <none>        80/TCP    9s
```

Ckeck IP
```
└─$> minikube ssh
docker@minikube:~$ sudo -i

root@minikube:~# curl http://10.103.101.59/index.html  
<html>
<head/>
<body>
<!-- IMAGE BEGINS HERE -->
```

This service IP can`t be ping it in iptables https://msazure.club/kubernetes-services-and-iptables/
```
root@minikube:~# iptables --list -nv -t nat 
...
Chain KUBE-SERVICES (2 references)
 pkts bytes target     prot opt in     out     source               destination         
...
    1    60 KUBE-MARK-MASQ  tcp  --  *      *      !10.244.0.0/16        10.103.101.59        /* default/web-svc-cip: cluster IP */ tcp dpt:80
    1    60 KUBE-SVC-WKCOG6KH24K26XRJ  tcp  --  *      *       0.0.0.0/0            10.103.101.59        /* default/web-svc-cip: cluster IP */ tcp dpt:80
...
```

#### Kube-proxy IPVS mode

https://github.com/kubernetes/kubernetes/blob/master/pkg/proxy/ipvs/README.md

###### Turn on IPVS

1. You can run minicube with extra parameters `minikube start --extra-config=kube-proxy.Mode="ipvs"` but i my case i got error.

2. So we change it manualy in proxy config. Run `kubectl edit -n kube-system configmap/kube-proxy` and cange mode to ipvs. 

Also need add `strictApp` https://github.com/metallb/metallb/issues/153

```
    ...
    ipvs:
      strictARP: true        <----- Add this setting
    ...  
    kind: KubeProxyConfiguration
    metricsBindAddress: 172.17.0.2:10249
    mode: "ipvs"             <----- Change  to "ipvs"
    nodePortAddresses: null
    ...
```

Restart kube-proxy `kubectl --namespace kube-system delete pod --selector='k8s-app=kube-proxy'`

Clean iptables rules:
```
$ minikube ssh

docker@minikube:~$ cat /tmp/iptables.cleanup
*nat
-A POSTROUTING -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE
COMMIT
*filter
COMMIT
*mangle
COMMIT

docker@minikube:~$ sudo iptables-restore /tmp/iptables.cleanup

docker@minikube:~$ ip addr show kube-ipvs0
17: kube-ipvs0: <BROADCAST,NOARP> mtu 1500 qdisc noop state DOWN group default 
...
    inet 10.103.101.59/32 brd 10.103.101.59 scope global kube-ipvs0
       valid_lft forever preferred_lft forever

root@minikube:/home/docker# ipvsadm --list -n
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
...  
TCP  10.103.101.59:80 rr
  -> 172.18.0.4:8000              Masq    1      0          0         
  -> 172.18.0.5:8000              Masq    1      0          0         
  -> 172.18.0.6:8000              Masq    1      0          0         
...

root@minikube:/home/docker#  ping -c1 10.103.101.59
PING 10.103.101.59 (10.103.101.59) 56(84) bytes of data.
64 bytes from 10.103.101.59: icmp_seq=1 ttl=64 time=0.073 ms

--- 10.103.101.59 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.073/0.073/0.073/0.000 ms
```

3. Another way to use `minikube dashboard` (namespace kubesystem , Configs and Storage/Config Maps)

Tips: Connect to kube-proxy `$> kubectl -n kube-system exec -it kube-proxy-dl5r5 -- /bin/sh `

### LoadBalancers

#### MetalLB

##### Install

```
└─$> kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/namespace.yaml
namespace/metallb-system created

└─$> kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/metallb.yaml
podsecuritypolicy.policy/controller created
podsecuritypolicy.policy/speaker created
serviceaccount/controller created
serviceaccount/speaker created
clusterrole.rbac.authorization.k8s.io/metallb-system:controller created
clusterrole.rbac.authorization.k8s.io/metallb-system:speaker created
role.rbac.authorization.k8s.io/config-watcher created
role.rbac.authorization.k8s.io/pod-lister created
clusterrolebinding.rbac.authorization.k8s.io/metallb-system:controller created
clusterrolebinding.rbac.authorization.k8s.io/metallb-system:speaker created
rolebinding.rbac.authorization.k8s.io/config-watcher created
rolebinding.rbac.authorization.k8s.io/pod-lister created
daemonset.apps/speaker created
deployment.apps/controller created

└─$> kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
secret/memberlist created
```

##### Check

```
└─$>   
NAME                              READY   STATUS    RESTARTS   AGE
pod/controller-57f648cb96-cc9g9   1/1     Running   0          59s
pod/speaker-nm2f5                 1/1     Running   0          59s

NAME                     DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                 AGE
daemonset.apps/speaker   1         1         1       1            1           beta.kubernetes.io/os=linux   59s

NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/controller   1/1     1            1           59s

NAME                                    DESIRED   CURRENT   READY   AGE
replicaset.apps/controller-57f648cb96   1         1         1       59s
```

##### Config apply

```
└─$> kubectl apply -f metallb-config.yaml 
configmap/config created
```

##### LoadBalancer 

```└─$> kubectl apply -f web-svc-lb.yaml
service/web-svc-lb created

└─$> kubectl get pods -n metallb-system
NAME                          READY   STATUS    RESTARTS   AGE
controller-57f648cb96-cc9g9   1/1     Running   0          9m2s
speaker-nm2f5                 1/1     Running   0          9m2s

└─$> kubectl --namespace metallb-system logs controller-57f648cb96-cc9g9
...
{"caller":"service.go:114","event":"ipAllocated","ip":"172.17.255.1","msg":"IP address assigned by controller","service":"default/web-svc-lb","ts":"2020-05-24T10:07:46.106293825Z"}
...

└─$>   kubectl describe svc web-svc-lb
Name:                     web-svc-lb
Namespace:                default
Labels:                   <none>
Annotations:              Selector:  app=web
Type:                     LoadBalancer
IP:                       10.101.76.16
LoadBalancer Ingress:     172.17.255.1
Port:                     <unset>  80/TCP
TargetPort:               8000/TCP
NodePort:                 <unset>  31556/TCP
Endpoints:                172.18.0.2:8000,172.18.0.3:8000,172.18.0.7:8000
Session Affinity:         None
External Traffic Policy:  Cluster
Events:
  Type    Reason        Age    From                Message
  ----    ------        ----   ----                -------
  Normal  IPAllocated   5m16s  metallb-controller  Assigned IP "172.17.255.1"
  Normal  nodeAssigned  5m16s  metallb-speaker     announcing from node "minikube"
```

##### Add route to IP and check

```
└─$> minikube ip
172.17.0.2

└─$> sudo ip route add 172.17.255.0/24 via 172.17.0.2 proto static metric 50
```

Now we can see our apps page!

![AppWebPage](./kubernetes-networks/metallb.png)


##### Useful links

https://kubernetes.io/blog/2018/07/09/ipvs-based-in-cluster-load-balancing-deep-dive/

http://www.linuxvirtualserver.org/docs/scheduling.html

https://github.com/kubernetes/kubernetes/blob/1cb3b5807ec37490b4582f22d991c043cc468195/pkg/proxy/apis/config/types.go#L185


#### LoadBalancer for CoreDns (*) https://metallb.universe.tf/usage/

```
└─$> kubectl apply --validate -f ./coredns-svc-lb.yaml 
service/coredns-svc-tcp-lb unchanged
service/coredns-svc-udp-lb unchanged

└─$> kubectl get service -n kube-system
NAME                 TYPE           CLUSTER-IP       EXTERNAL-IP    PORT(S)                  AGE
coredns-svc-tcp-lb   LoadBalancer   10.97.129.43     172.17.255.2   53:31785/TCP             6m37s
coredns-svc-udp-lb   LoadBalancer   10.102.211.127   172.17.255.2   53:30594/UDP             6m37s
kube-dns             ClusterIP      10.96.0.10       <none>         53/UDP,53/TCP,9153/TCP   20d

└─$> kubectl describe svc coredns-svc-tcp-lb -n kube-system
Name:                     coredns-svc-tcp-lb
Namespace:                kube-system
Labels:                   <none>
Annotations:              metallb.universe.tf/allow-shared-ip: coredns
Selector:                 k8s-app=kube-dns
Type:                     LoadBalancer
IP:                       10.97.129.43
IP:                       172.17.255.2
LoadBalancer Ingress:     172.17.255.2
Port:                     <unset>  53/TCP
TargetPort:               53/TCP
NodePort:                 <unset>  31785/TCP
Endpoints:                172.18.0.6:53,172.18.0.8:53
Session Affinity:         None
External Traffic Policy:  Cluster
Events:
  Type    Reason        Age    From                Message
  ----    ------        ----   ----                -------
  Normal  IPAllocated   6m47s  metallb-controller  Assigned IP "172.17.255.2"
  Normal  nodeAssigned  2m43s  metallb-speaker     announcing from node "minikube"

# Test DNS
└─$> nslookup 172.17.255.2 172.17.255.2
2.255.17.172.in-addr.arpa	name = coredns-svc-udp-lb.kube-system.svc.cluster.local.

# It works!
```

### Ingress 

#### Install

```
└─$> kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/baremetal/deploy.yaml
namespace/ingress-nginx created
serviceaccount/ingress-nginx created
configmap/ingress-nginx-controller created
clusterrole.rbac.authorization.k8s.io/ingress-nginx created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx created
role.rbac.authorization.k8s.io/ingress-nginx created
rolebinding.rbac.authorization.k8s.io/ingress-nginx created
service/ingress-nginx-controller-admission created
service/ingress-nginx-controller created
deployment.apps/ingress-nginx-controller created
validatingwebhookconfiguration.admissionregistration.k8s.io/ingress-nginx-admission created
clusterrole.rbac.authorization.k8s.io/ingress-nginx-admission created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
job.batch/ingress-nginx-admission-create created
job.batch/ingress-nginx-admission-patch created
role.rbac.authorization.k8s.io/ingress-nginx-admission created
rolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
serviceaccount/ingress-nginx-admission created
```

Here some instruction for NodePort service https://kubernetes.github.io/ingress-nginx/deploy/#bare-metal

Can simple run `minikube addons enable ingress`

But we will create Ingress with LoadBalancer:

```
└─$> kubectl apply -f ./nginx-lb.yaml 
service/ingress-nginx created

└─$> kubectl get service -n ingress-nginx
NAME                                 TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)                      AGE
ingress-nginx                        LoadBalancer   10.110.13.33    172.17.255.3   80:31180/TCP,443:32175/TCP   3m9s
ingress-nginx-controller             NodePort       10.96.210.22    <none>         80:31985/TCP,443:31260/TCP   8m56s
ingress-nginx-controller-admission   ClusterIP      10.110.168.66   <none>         443/TCP                      8m56s

# test and see nginx works
└─$> curl 172.17.255.3
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx/1.17.10</center>
</body>
</html>
```

#### Headless service

We don`t need cluster IP so create new headless service.

```
└─$> kubectl apply -f ./web-svc-headless.yaml 
service/web-svc created

└─$> kubectl get service
NAME          TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)        AGE
kubernetes    ClusterIP      10.96.0.1       <none>         443/TCP        21d
web-svc       ClusterIP      None            <none>         80/TCP         2s    <---- no IP
web-svc-cip   ClusterIP      10.103.101.59   <none>         80/TCP         3d2h
web-svc-lb    LoadBalancer   10.101.76.16    172.17.255.1   80:31556/TCP   6h31m
```
 
#### Ingress rules

```
└─$> kubectl apply -f ./web-ingress.yaml
ingress.networking.k8s.io/web created

└─$> kubectl describe ingress/web
Name:             web
Namespace:        default
Address:          172.17.0.2
Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
Rules:
  Host        Path  Backends
  ----        ----  --------
  *           
              /web   web-svc:8000 (172.18.0.2:8000,172.18.0.3:8000,172.18.0.7:8000)
Annotations:  nginx.ingress.kubernetes.io/rewrite-target: /
Events:
  Type    Reason  Age   From                      Message
  ----    ------  ----  ----                      -------
  Normal  CREATE  36s   nginx-ingress-controller  Ingress default/web
  Normal  CREATE  36s   nginx-ingress-controller  Ingress default/web
  Normal  UPDATE  24s   nginx-ingress-controller  Ingress default/web
  Normal  UPDATE  24s   nginx-ingress-controller  Ingress default/web
```

Now we can check that IP works  http://172.17.0.2/web/index.html

![AppWebPage](./kubernetes-networks/ingress.png)


### Ingress for DashBoard (*)

Install

```
└─$> kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.1/aio/deploy/recommended.yaml

└─$> minikube addons enable ingress
🌟  The 'ingress' addon is enabled

└─$> kubectl apply -f ./dashboard/ingress-dashboard.yaml 
ingress.networking.k8s.io/dashboard-ingress created

└─$> kubectl -n kubernetes-dashboard describe ingress dashboard-ingress
Name:             dashboard-ingress
Namespace:        kubernetes-dashboard
Address:          172.17.0.2
Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
Rules:
  Host        Path  Backends
  ----        ----  --------
  *           
              /dashboard/(.*)   kubernetes-dashboard:443 (172.18.0.4:8443)
Annotations:  kubernetes.io/ingress.class: nginx
              nginx.ingress.kubernetes.io/backend-protocol: HTTPS
              nginx.ingress.kubernetes.io/rewrite-target: /$1
              nginx.ingress.kubernetes.io/secure-backends: true
Events:
  Type    Reason  Age                    From                      Message
  ----    ------  ----                   ----                      -------
  Normal  CREATE  7m33s                  nginx-ingress-controller  Ingress kubernetes-dashboard/dashboard-ingress
  Normal  UPDATE  6m40s (x2 over 6m44s)  nginx-ingress-controller  Ingress kubernetes-dashboard/dashboard-ingress

```

Now we can access dashboard webpage from our host by https://172.17.0.2/dashboard/.

![AppWebPage](./kubernetes-networks/dashboard.png)


### Canary deployment (in progress)

https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/nginx-configuration/annotations.md#canary

---

## HW-3 K8s Security

![Build Status](https://api.travis-ci.com/otus-kuber-2020-04/revard_platform.svg?branch=kubernetes-security)

### How to use

Clone repo. Start k8s. Run `cd kubernetes-security`. Run commands bellow.

### Get status

#### Cluster info 

```
└─$> kubectl cluster-info dump | grep authorization-mode
                            "--authorization-mode=Node,RBAC",
```
or
```
└─$> kubectl -n kube-system describe pod kube-apiserver-minikube 
Name:                 kube-apiserver-minikube
Namespace:            kube-system
Priority:             2000000000
...
```

#### Api resourses https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.17/

```
└─$>  kubectl api-resources
NAME                              SHORTNAMES   APIGROUP                       NAMESPACED   KIND
bindings                                                                      true         Binding
componentstatuses                 cs                                          false        ComponentStatus
configmaps                        cm                                          true         ConfigMap
endpoints                         ep                                          true         Endpoints
...
```

### Palying with SA CR CRB

For example `cd task01`

#### Create ServiceAccount

```
└─$> kubectl apply -f ./01-sa-bob.yaml 
serviceaccount/bob created

└─$> kubectl apply -f ./03-sa-dave.yaml 
serviceaccount/dave created

└─$> kubectl get sa
NAME      SECRETS   AGE
bob       1         4m57s
dave      1         5s
default   1         15d
```

#### Create ClusterRoleBinding

```
└─$> kubectl apply -f ./02-crb-bob.yaml 
clusterrolebinding.rbac.authorization.k8s.io/bob-cluster-admin created

└─$> kubectl get clusterrolebinding
NAME                                                   ROLE                                                                               AGE
bob-cluster-admin                                      ClusterRole/cluster-admin                                                          2m20s
cluster-admin                                          ClusterRole/cluster-admin                                                          15d
```

### Exmples

You can find some examples in dir `examples`.

---

## HW-2 Kubernetes controllers

![Build Status](https://api.travis-ci.com/otus-kuber-2020-04/revard_platform.svg?branch=kubernetes-controllers)

### How to use

Clone repo. Cd in dir `kubernetes-controllers`. Run commands bellow.

### Kind 

##### Install 

https://kind.sigs.k8s.io/docs/user/quick-start/

##### Start 
```
└─$> kind create cluster --config kind-config.yaml
Creating cluster "kind" ...
 ✓ Ensuring node image (kindest/node:v1.18.2) 🖼 
 ✓ Preparing nodes 📦 📦 📦 📦 📦 📦  
 ✓ Configuring the external load balancer ⚖️ 
 ✓ Writing configuration 📜 
 ✓ Starting control-plane 🕹️ 
 ✓ Installing CNI 🔌 
 ✓ Installing StorageClass 💾 
 ✓ Joining more control-plane nodes 🎮 
 ✓ Joining worker nodes 🚜 
Set kubectl context to "kind-kind"
You can now use your cluster with:

kubectl cluster-info --context kind-kind

Thanks for using kind! 😊
```

##### Status
```
└─$> kubectl get nodes
NAME                  STATUS   ROLES    AGE     VERSION
kind-control-plane    Ready    master   3m41s   v1.18.2
kind-control-plane2   Ready    master   3m11s   v1.18.2
kind-control-plane3   Ready    master   2m31s   v1.18.2
kind-worker           Ready    <none>   2m13s   v1.18.2
kind-worker2          Ready    <none>   2m13s   v1.18.2
kind-worker3          Ready    <none>   2m13s   v1.18.2
```

### Controllers

#### ReplicaSet

https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/

##### Create
```
─$> kubectl apply -f ./frontend-replicaset.yaml
replicaset.apps/frontend created

└─$> kubectl scale replicaset frontend --replicas=3
replicaset.apps/frontend scaled

─$> kubectl get pods -l app=frontend
NAME             READY   STATUS    RESTARTS   AGE
frontend-54ntp   1/1     Running   0          63s
frontend-9mdpz   1/1     Running   0          63s
frontend-mxzc6   1/1     Running   0          63s

└─$> kubectl get rs frontend
NAME       DESIRED   CURRENT   READY   AGE
frontend   3         3         3       2m16s
```

##### Try delete and get rise again
```
└─$> kubectl delete pods -l app=frontend | kubectl get pods -l app=frontend -w
...

└─$> kubectl get pods -l app=frontend
NAME             READY   STATUS    RESTARTS   AGE
frontend-727g8   1/1     Running   0          66s
frontend-8wt4p   1/1     Running   0          66s
frontend-h9hbv   1/1     Running   0          66s
```

##### Change image version

We edit in `frontend-replicaset.yaml` docker image version and aplly it but nothing happend.

Check current versions:
```
└─$> kubectl get replicaset frontend -o=jsonpath='{.spec.template.spec.containers[0].image}'
revard/otus-k8s-frontend:v0.0.2
 
└─$> kubectl get pods -l app=frontend -o=jsonpath='{.items[0:3].spec.containers[0].image}'
revard/otus-k8s-frontend:latest
```

Now we delete all pods and recreate.
```
└─$> kubectl delete pods -l app=frontend | kubectl get pods -l app=frontend -w
...
```

Get new image version. 
```
└─$> kubectl get replicaset frontend -o=jsonpath='{.spec.template.spec.containers[0].image}'
revard/otus-k8s-frontend:v0.0.2
```

!!! It happend because ReplicaSet doesn`t check manifest!!! 

#### Deployment

##### Aplly
```
└─$> kubectl apply -f ./paymentservice-deployment.yaml
deployment.apps/paymentservice created

└─$> kubectl get ds
No resources found in default namespace.

└─$> kubectl get deployment
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
paymentservice   1/3     3            1           16s

└─$> kubectl get rs
NAME                       DESIRED   CURRENT   READY   AGE
paymentservice-bdf74f647   3         3         1       22s

└─$> kubectl get pods
NAME                             READY   STATUS    RESTARTS   AGE
paymentservice-bdf74f647-4svkd   1/1     Running   0          90s
paymentservice-bdf74f647-htvll   1/1     Running   0          90s
paymentservice-bdf74f647-qmc64   1/1     Running   0          90s
```

##### Rolling Update (default). Let`s change version in deployment manifest and apply. 
```
alf@alf-pad:~/revard_platform/kubernetes-controllers (kubernetes-controllers) 
└─$> kubectl apply -f paymentservice-deployment.yaml 

└─$> kubectl get replicaset 
NAME                        DESIRED   CURRENT   READY   AGE
paymentservice-7d745d469d   3         3         3       2m6s
paymentservice-bdf74f647    0         0         0       4m33s

└─$> kubectl get replicaset paymentservice-7d745d469d -o=jsonpath='{.spec.template.spec.containers[0].image}'
revard/otus-k8s-paymentservice:v0.0.2 
└─$> kubectl get replicaset paymentservice-bdf74f647 -o=jsonpath='{.spec.template.spec.containers[0].image}'
revard/otus-k8s-paymentservice:v0.0.1

```

##### History
```
└─$> kubectl rollout history deployment paymentservice
deployment.apps/paymentservice 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```

##### Rollback
```
└─$> kubectl rollout undo deployment paymentservice --to-revision=1 | kubectl get rs -l app=paymentservice -w
...

└─$> kubectl get replicaset 
NAME                        DESIRED   CURRENT   READY   AGE
paymentservice-7d745d469d   0         0         0       15m
paymentservice-bdf74f647    3         3         3       18m
```

##### Deployment strategy

We can use `Max Surge` and `Max Unavailable` parameters. 

https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy

Blue-Green example in `paymentservice-deployment-bg.yaml`

Reverse Rolling Update in `paymentservice-deployment-reverse.yaml`

#### Probes

https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/

##### Check status
```
└─$> kubectl describe pod | grep Readiness
    Readiness:      http-get http://:8080/_healthz delay=10s timeout=1s period=10s #success=1 #failure=3
    Readiness:      http-get http://:8080/_healthz delay=10s timeout=1s period=10s #success=1 #failure=3
    Readiness:      http-get http://:8080/_healthz delay=10s timeout=1s period=10s #success=1 #failure=3
```

##### Wrong probe example
```
─$> kubectl get pod 
NAME                        READY   STATUS    RESTARTS   AGE
frontend-7cd948bf65-cb6h7   1/1     Running   0          68m
frontend-7cd948bf65-t5w4n   1/1     Running   0          68m
frontend-7cd948bf65-vnsc9   1/1     Running   0          68m
frontend-7f454bbbf8-crpvw   0/1     Running   0          18s

└─$> kubectl describe pod  frontend-7f454bbbf8-crpvw
...
Events:
  Type     Reason     Age               From                  Message
  ----     ------     ----              ----                  -------
...
  Warning  Unhealthy  4s (x2 over 14s)  kubelet, kind-worker  Readiness probe failed: HTTP probe failed with statuscode: 404  
```

##### Deployment status
```
└─$> kubectl rollout status deployment/frontend
Waiting for deployment "frontend" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "frontend" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "frontend" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "frontend" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "frontend" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "frontend" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "frontend" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "frontend" rollout to finish: 1 old replicas are pending termination...
deployment "frontend" successfully rolled out
```

##### Probe status examples fot GitLab CI/CD
```
deploy_job:
stage: deploy
script:
- kubectl apply -f frontend-deployment.yaml
- kubectl rollout status deployment/frontend --timeout=60s
```
```
rollback_deploy_job:
stage: rollback
script:
- kubectl rollout undo deployment/frontend
when: on_failure
```

#### DaemonSet

We try run `node-exporter-daemonset`

```
└─$> kubectl apply -f node-exporter-daemonset.yaml 
daemonset.apps/node-exporter created

└─$> kubectl get ds
NAME            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
node-exporter   6         6         0       6            0           kubernetes.io/os=linux   6s
 
└─$> kubectl get pods 
NAME                        READY   STATUS    RESTARTS   AGE
frontend-58d98549cb-4zclg   1/1     Running   0          10m
frontend-58d98549cb-srr46   1/1     Running   0          11m
frontend-58d98549cb-vsgss   1/1     Running   0          10m
node-exporter-d2xkf         2/2     Running   0          2m36s
node-exporter-k8cjd         2/2     Running   0          2m36s
node-exporter-pwjfb         2/2     Running   0          2m36s
node-exporter-q84vz         2/2     Running   0          2m36s
node-exporter-r46xc         2/2     Running   0          2m36s
node-exporter-r7gth         2/2     Running   0          2m36s
```

##### Test. Forward port and get all ok.
```
└─$> kubectl port-forward node-exporter-d2xkf 9100:9100
Forwarding from 127.0.0.1:9100 -> 9100
Forwarding from [::1]:9100 -> 9100
Handling connection for 9100

└─$> curl localhost:9100/metrics
# HELP go_gc_duration_seconds A summary of the GC invocation durations.
# TYPE go_gc_duration_seconds summary
go_gc_duration_seconds{quantile="0"} 0
go_gc_duration_seconds{quantile="0.25"} 0
go_gc_duration_seconds{quantile="0.5"} 0
```

As we can see DaemonSet run on all nodes:
```
└─$> kubectl describe nodes  | egrep "Name:|node-exporte"
Name:               kind-control-plane
  default                     node-exporter-z47qv                           112m (1%)     270m (3%)   200Mi (1%)       220Mi (1%)     3m3s
Name:               kind-control-plane2
  default                     node-exporter-v2qqb                            112m (1%)     270m (3%)   200Mi (1%)       220Mi (1%)     3m3s
Name:               kind-control-plane3
  default                     node-exporter-rxw47                            112m (1%)     270m (3%)   200Mi (1%)       220Mi (1%)     3m3s
Name:               kind-worker
  default                     node-exporter-fh25z          112m (1%)     270m (3%)   200Mi (1%)       220Mi (1%)     3m3s
Name:               kind-worker2
  default                     node-exporter-4m62w          112m (1%)     270m (3%)   200Mi (1%)       220Mi (1%)     3m3s
Name:               kind-worker3
  default                     node-exporter-5rcct          112m (1%)     270m (3%)   200Mi (1%)       220Mi (1%)     3m3s
```

If for some reason daemonset won`t run on master nodes you can setup toleration:
```
...
kind: DaemonSet
spec:
  ...
  template:
   ...
    spec:
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
```

---

## HW-1 Kubernetes Intro

![Build Status](https://api.travis-ci.com/otus-kuber-2020-04/revard_platform.svg?branch=kubernetes-intro)

### Install

* kubectl 

https://kubernetes.io/docs/tasks/tools/install-kubectl/

* minicube

https://kubernetes.io/docs/tasks/tools/install-minikube/

* kind

https://kind.sigs.k8s.io/docs/user/quick-start/

* Web UI (Dashboard)

https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/

* Kubernetes CLI

https://k9scli.io/


### Minikube

#### Start

```
alf@alf-pad:~/revard_platform (master) 
└─$>  minikube start
😄  minikube v1.9.2 on Ubuntu 20.04
✨  Automatically selected the docker driver
👍  Starting control plane node m01 in cluster minikube
🚜  Pulling base image ...
💾  Downloading Kubernetes v1.18.0 preload ...
    > preloaded-images-k8s-v2-v1.18.0-docker-overlay2-amd64.tar.lz4: 542.91 MiB
🔥  Creating Kubernetes in docker container with (CPUs=2) (8 available), Memory=3900MB (15909MB available) ...
🐳  Preparing Kubernetes v1.18.0 on Docker 19.03.2 ...
    ▪ kubeadm.pod-network-cidr=10.244.0.0/16
🌟  Enabling addons: default-storageclass, storage-provisioner
🏄  Done! kubectl is now configured to use "minikube"
```

#### Check config

```
alf@alf-pad:~/revard_platform (master) 
└─$> kubectl cluster-info
Kubernetes master is running at https://172.17.0.2:8443
KubeDNS is running at https://172.17.0.2:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.


alf@alf-pad:~/revard_platform (master) 
└─$> kubectl config view
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /home/alf/.minikube/ca.crt
    server: https://172.17.0.2:8443
  name: minikube
contexts:
- context:
    cluster: minikube
    user: minikube
  name: minikube
current-context: minikube
kind: Config
preferences: {}
users:
- name: minikube
  user:
    client-certificate: /home/alf/.minikube/profiles/minikube/client.crt
    client-key: /home/alf/.minikube/profiles/minikube/client.key
```

#### Playing with k8s

* Connect to k8s and try delete containers. As we see they rise again.

```
alf@alf-pad:~/revard_platform (master) 
└─$> minikube ssh

docker@minikube:~$ docker ps
CONTAINER ID        IMAGE                  COMMAND                  CREATED             STATUS              PORTS               NAMES
57d75b38e437        67da37a9a360           "/coredns -conf /etc…"   2 hours ago         Up 2 hours                              k8s_coredns_coredns-66bff467f8-dwcwl_kube-system_7afa9fa7-a1b4-4ceb-baa1-855b25be6c8e_0
358c69b2d37d        67da37a9a360           "/coredns -conf /etc…"   2 hours ago         Up 2 hours                              k8s_coredns_coredns-66bff467f8-sw6zt_kube-system_e486de76-96c3-41e6-8efb-0bc6ae98341f_0
...

docker@minikube:~$ docker rm -f $(docker ps -a -q)
57d75b38e437
358c69b2d37d
...

docker@minikube:~$ docker ps
CONTAINER ID        IMAGE                  COMMAND                  CREATED             STATUS              PORTS               NAMES
774796c60f8e        67da37a9a360           "/coredns -conf /etc…"   5 seconds ago       Up 3 seconds                            k8s_coredns_coredns-66bff467f8-dwcwl_kube-system_7afa9fa7-a1b4-4ceb-baa1-855b25be6c8e_0
5d249edbe72b        67da37a9a360           "/coredns -conf /etc…"   5 seconds ago       Up 3 seconds                            k8s_coredns_coredns-66bff467f8-sw6zt_kube-system_e486de76-96c3-41e6-8efb-0bc6ae98341f_0
...
```

* Status by kubernetes NS

```
alf@alf-pad:~/revard_platform (master) 
└─$> kubectl get pods -n kube-system

NAME                               READY   STATUS    RESTARTS   AGE
coredns-66bff467f8-dwcwl           1/1     Running   0          137m
coredns-66bff467f8-sw6zt           1/1     Running   0          137m
etcd-minikube                      1/1     Running   0          137m
kindnet-bnbvp                      1/1     Running   0          137m
kube-apiserver-minikube            1/1     Running   0          137m
kube-controller-manager-minikube   1/1     Running   0          137m
kube-proxy-jq5jt                   1/1     Running   0          137m
kube-scheduler-minikube            1/1     Running   0          137m
storage-provisioner                1/1     Running   1          137m

```
* Delete again and get all ok.

```
alf@alf-pad:~/revard_platform (master) 
└─$> kubectl delete pod --all -n kube-system
pod "coredns-66bff467f8-dwcwl" deleted
pod "coredns-66bff467f8-sw6zt" deleted
pod "etcd-minikube" deleted
pod "kindnet-bnbvp" deleted
pod "kube-apiserver-minikube" deleted
pod "kube-controller-manager-minikube" deleted
pod "kube-proxy-jq5jt" deleted
pod "kube-scheduler-minikube" deleted
pod "storage-provisioner" deleted

alf@alf-pad:~/revard_platform (master) 
└─$> kubectl get componentstatuses (cs)
NAME                 STATUS    MESSAGE             ERROR
controller-manager   Healthy   ok                  
scheduler            Healthy   ok                  
etcd-0               Healthy   {"health":"true"}  
```

### Pods in NS kube-system are recreating due:

1. Kubernetes static pods in manifest dir controled directly by kublet.

```
docker@minikube:~$ ll /etc/kubernetes/manifests/                   
...
-rw------- 1 root root 1895 May  3 15:48 etcd.yaml
-rw------- 1 root root 3429 May  3 15:48 kube-apiserver.yaml
-rw------- 1 root root 3105 May  3 15:48 kube-controller-manager.yaml
-rw------- 1 root root 1120 May  3 15:48 kube-scheduler.yaml
```

2. Core-dns is recreated by Deployment.

```
alf@alf-pad:~/revard_platform (master) 
└─$> kubectl get deployment --namespace=kube-system -o wide
NAME      READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                     SELECTOR
coredns   2/2     2            2           17h   coredns      k8s.gcr.io/coredns:1.6.7   k8s-app=kube-dns
```

3. Kube-proxy recreated by DaemonSet.

```
alf@alf-pad:~/revard_platform (master) 
└─$> kubectl get ds --namespace=kube-system -o wide
NAME         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE   CONTAINERS    IMAGES                          SELECTOR
kindnet      1         1         1       1            1           <none>                   17h   kindnet-cni   kindest/kindnetd:0.5.3          app=kindnet
kube-proxy   1         1         1       1            1           kubernetes.io/os=linux   17h   kube-proxy    k8s.gcr.io/kube-proxy:v1.18.0   k8s-app=kube-proxy
```

### Playing with pods

#### Web app

* Create pod

```
alf@alf-pad:~/revard_platform/kubernetes-intro (master) 
└─$> kubectl apply -f web-pod.yaml
pod/web created

alf@alf-pad:~/revard_platform/kubernetes-intro (master) 
└─$> kubectl get pods
NAME   READY   STATUS    RESTARTS   AGE
web    1/1     Running   0          10s
```

* Delete pod

```
alf@alf-pad:~/revard_platform/kubernetes-intro (master) 
└─$> kubectl delete pod web
pod "web" deleted
```

* Recreate pod

```
alf@alf-pad:~/revard_platform/kubernetes-intro (master) 
└─$> kubectl apply -f web-pod.yaml && kubectl get pods -w
pod/web created
NAME   READY   STATUS     RESTARTS   AGE
web    0/1     Init:0/1   0          0s
web    0/1     Init:0/1   0          2s
web    0/1     PodInitializing   0          3s
web    1/1     Running           0          6s
```

* Forward port

```
alf@alf-pad:~/revard_platform/kubernetes-intro (master) 
└─$> kubectl port-forward --address 0.0.0.0 pod/web 8000:8000
Forwarding from 0.0.0.0:8000 -> 8000
Handling connection for 8000
Handling connection for 8000
```

Alternative - https://kube-forwarder.pixelpoint.io/

#### Hipster frontend app

* Run

```
alf@alf-pad:~/revard_platform/kubernetes-intro (master) 
└─$> kubectl run frontend --image revard/otus-k8s-frontend --restart=Never
pod/frontend created

alf@alf-pad:~/revard_platform/kubernetes-intro (master) 
└─$> kubectl get pods
NAME       READY   STATUS    RESTARTS   AGE
frontend   0/1     Error     0          33s
web        1/1     Running   0          18h
```

* Generate manifest

```
alf@alf-pad:~/revard_platform/kubernetes-intro (master) 
└─$> kubectl run frontend --image revard/otus-k8s-frontend --restart=Never --dry-run=client -o yaml > frontend-pod.yaml
```

### Torubleshooting

Try find out what is wrong with frontend pod.

Let`s see status:
```
alf@alf-pad:~/tmp/microservices-demo/src/frontend (master) 
└─$> kubectl describe pod frontend
Name:         frontend
Namespace:    default
Priority:     0
Node:         minikube/172.17.0.2
Start Time:   Tue, 05 May 2020 10:44:32 +0300
Labels:       run=frontend
Annotations:  <none>
Status:       Failed
IP:           172.18.0.3
IPs:
  IP:  172.18.0.3
Containers:
  frontend:
    Container ID:   docker://69788574e7c0cac911cdbd58a756c840ad40e62b960543448a291635dc09de56
    Image:          revard/otus-k8s-frontend
    Image ID:       docker-pullable://revard/otus-k8s-frontend@sha256:6fce3b26da2e5d089c57f326371866d034c8e1db527dfa3a385b10c1125a04c9
    Port:           <none>
    Host Port:      <none>
    State:          Terminated
      Reason:       Error
      Exit Code:    2
      Started:      Tue, 05 May 2020 10:44:38 +0300
      Finished:     Tue, 05 May 2020 10:44:38 +0300
    Ready:          False
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-gkg4c (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             False 
  ContainersReady   False 
  PodScheduled      True 
Volumes:
  default-token-gkg4c:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-gkg4c
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  6m30s  default-scheduler  Successfully assigned default/frontend to minikube
  Normal  Pulling    6m29s  kubelet, minikube  Pulling image "revard/otus-k8s-frontend"
  Normal  Pulled     6m24s  kubelet, minikube  Successfully pulled image "revard/otus-k8s-frontend"
  Normal  Created    6m24s  kubelet, minikube  Created container frontend
  Normal  Started    6m24s  kubelet, minikube  Started container frontend
```

Events look good. Take a look on container. Quick way is `kubectl logs frontend`

```
alf@alf-pad:~/revard_platform (master)
└─$> minikube ssh

docker@minikube:~$ docker logs $(docker ps -a | grep otus-k8s-frontend | awk '{print $1}')
{"message":"Tracing enabled.","severity":"info","timestamp":"2020-05-05T07:44:38.251381079Z"}
{"message":"Profiling enabled.","severity":"info","timestamp":"2020-05-05T07:44:38.251476052Z"}
{"message":"jaeger initialization disabled.","severity":"info","timestamp":"2020-05-05T07:44:38.25165138Z"}
panic: environment variable "PRODUCT_CATALOG_SERVICE_ADDR" not set

goroutine 1 [running]:
main.mustMapEnv(0xc0003b4000, 0xb0f14e, 0x1c)
	/go/src/github.com/GoogleCloudPlatform/microservices-demo/src/frontend/main.go:259 +0x10e
main.main()
	/go/src/github.com/GoogleCloudPlatform/microservices-demo/src/frontend/main.go:117 +0x4ff
```

So we have enviroment variable issue. Let`s fix this by adding ENV to manifest an restart pod.

```
alf@alf-pad:~/revard_platform/kubernetes-intro (master)
└─$> kubectl delete pod frontend
pod "frontend" deleted

alf@alf-pad:~/revard_platform/kubernetes-intro (master) 
└─$> kubectl apply -f frontend-pod-healthy.yaml && kubectl get pods -w
pod/frontend created
NAME       READY   STATUS              RESTARTS   AGE
frontend   0/1     ContainerCreating   0          0s
web        1/1     Running             0          19h
frontend   1/1     Running             0          4s
```

Now all is OK!

```
alf@alf-pad:~/revard_platform/kubernetes-intro (master) 
└─$> kubectl get pods
NAME       READY   STATUS    RESTARTS   AGE
frontend   1/1     Running   0          77s
web        1/1     Running   0          19h
```

#### Links

https://github.com/GoogleCloudPlatform/microservices-demo.git