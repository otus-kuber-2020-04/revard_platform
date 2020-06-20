#!/bin/bash

#git clone https://github.com/hashicorp/consul-helm.git
#git clone https://github.com/hashicorp/vault-helm.git

helm install consul consul-helm
helm install vault vault-helm

sleep 60
kubectl exec -it vault-0 -- vault operator init --key-shares=1 --key-threshold=1 | tee /tmp/vault.tmp
UNSEAL_KEY=$(grep "Unseal Key" /tmp/vault.tmp | awk '{print $4}' | sed 's/\x1b\[[0-9;]*m//g')
ROOT_TOKEN=$(grep "Root Token" /tmp/vault.tmp | awk '{print $4}' | sed 's/\x1b\[[0-9;]*m//g')

kubectl exec -it vault-0 -- vault operator unseal "$UNSEAL_KEY"
kubectl exec -it vault-1 -- vault operator unseal "$UNSEAL_KEY"
kubectl exec -it vault-2 -- vault operator unseal "$UNSEAL_KEY"

#kubectl exec -it vault-0 -- vault login
echo $ROOT_TOKEN | kubectl exec -it vault-0 -- vault login -

kubectl exec -it vault-0 -- vault secrets enable --path=otus kv
kubectl exec -it vault-0 -- vault secrets list --detailed
kubectl exec -it vault-0 -- vault kv put otus/otus-ro/config username='otus' password='asajkjkahs'
kubectl exec -it vault-0 -- vault kv put otus/otus-rw/config username='otus' password='asajkjkahs'
kubectl exec -it vault-0 -- vault read otus/otus-ro/config
kubectl exec -it vault-0 -- vault kv get otus/otus-rw/config

kubectl exec -it vault-0 -- vault auth enable kubernetes
kubectl create serviceaccount vault-auth
kubectl apply --filename vault-auth-service-account.yml

export VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}")
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)
export K8S_HOST=$(kubectl cluster-info | grep 'Kubernetes master' | awk '/https/ {print $NF}' | sed 's/\x1b\[[0-9;]*m//g')

kubectl exec -it vault-0 -- vault write auth/kubernetes/config token_reviewer_jwt="$SA_JWT_TOKEN" kubernetes_host="$K8S_HOST" kubernetes_ca_cert="$SA_CA_CRT"

kubectl cp otus-policy.hcl vault-0:./tmp
kubectl exec -it vault-0 -- vault policy write otus-policy /tmp/otus-policy.hcl
kubectl exec -it vault-0 -- vault write auth/kubernetes/role/otus bound_service_account_names=vault-auth bound_service_account_namespaces=default policies=otus-policy ttl=24h

#git clone https://github.com/hashicorp/vault-guides.git
#cd vault-guides/identity/vault-agent-k8s-demo

kubectl apply -f ./configs-k8s/example-vault-agent-config.yaml
kubectl apply -f ./configs-k8s/example-k8s-spec.yaml 

# CA by vault

kubectl exec -it vault-0 -- vault secrets enable pki
kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki
kubectl exec -it vault-0 -- vault write -field=certificate pki/root/generate/internal common_name="exmaple.ru" ttl=87600h > CA_cert.crt

kubectl exec -it vault-0 -- vault write pki/config/urls issuing_certificates="http://vault:8200/v1/pki/ca" crl_distribution_points="http://vault:8200/v1/pki/crl"

kubectl exec -it vault-0 -- vault secrets enable --path=pki_int pki
kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki_int
kubectl exec -it vault-0 -- vault write -format=json pki_int/intermediate/generate/internal  common_name="example.ru Intermediate Authority" | jq -r '.data.csr' > pki_intermediate.csr

kubectl cp pki_intermediate.csr vault-0:./tmp
kubectl exec -it vault-0 -- vault write -format=json pki/root/sign-intermediate csr=@/tmp/pki_intermediate.csr format=pem_bundle ttl="43800h" | jq -r '.data.certificate' > intermediate.cert.pem
kubectl cp intermediate.cert.pem vault-0:./tmp
kubectl exec -it vault-0 -- vault write pki_int/intermediate/set-signed certificate=@/tmp/intermediate.cert.pem

kubectl exec -it vault-0 -- vault write pki_int/roles/example-dot-ru allowed_domains="example.ru" allow_subdomains=true max_ttl="720h"
kubectl exec -it vault-0 -- vault write pki_int/issue/example-dot-ru common_name="gitlab.example.ru" ttl="24h" | tee /tmp/cert.tmp

CER_SN=$(grep "serial_number" /tmp/cert.tmp | awk '{print $2}' | sed 's/\x1b\[[0-9;]*m//g')
kubectl exec -it vault-0 -- vault write pki_int/revoke serial_number="$CERT_SN"