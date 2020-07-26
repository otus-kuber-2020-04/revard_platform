#!/bin/bash

# gke cluster
./gkecluster.sh 
gcloud container clusters get-credentials standart-cluster-1 --zone europe-west4-a --project otus-kuber-278614
gcloud beta container clusters update standart-cluster-1 --update-addons=Istio=ENABLED --istio-config=auth=MTLS_PERMISSIVE --region=europe-west4-a 
kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/master/deploy/crds.yaml
kubectl -n istio-system apply -f install-prometheus.yaml
helm upgrade -i flagger-grafana flagger/grafana --namespace=istio-system --set url=http://prometheus:9090 --set user=admin --set password=admin
kubectl apply -f grafana-virtual-service.yaml
#helm repo add fluxcd https://charts.fluxcd.io
kubectl create namespace flux
helm upgrade --install flux fluxcd/flux -f flux.values.yaml --namespace flux
helm upgrade --install helm-operator fluxcd/helm-operator -f helm-operator.values.yaml --namespace flux
fluxctl identity --k8s-fwd-ns flux

#helm repo add flagger https://flagger.app
kubectl apply -f https://raw.githubusercontent.com/weaveworks/flagger/master/artifacts/flagger/crd.yaml
helm upgrade --install flagger flagger/flagger \
--namespace=istio-system \
--set crd.create=false \
--set meshProvider=istio \
--set metricsServer=http://prometheus:9090

# new frontend image 
export USERNAME=revard; export APP_TAG=v0.0.3; cd microservices-demo/src/frontend && docker build -t $USERNAME/frontend:$APP_TAG .;docker push $USERNAME/frontend:$APP_TAG; cd ../../..