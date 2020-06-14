#!/bin/bash

kubectl create ns microservices-demo
kubectl apply -f https://raw.githubusercontent.com/express42/otus-platform-snippets/master/Module-02/Logging/microservices-demo-without-resources.yaml -n microservices-demo

helm repo add elastic https://helm.elastic.co
kubectl create ns observability
helm upgrade --install elasticsearch elastic/elasticsearch --namespace observability -f elasticsearch.values.yaml 
helm upgrade --install kibana elastic/kibana --namespace observability -f kibana.values.yaml 
helm upgrade --install fluent-bit stable/fluent-bit --namespace observability -f fluentbit.values.yaml

kubectl create ns nginx-ingress
helm upgrade --install nginx-ingress stable/nginx-ingress --namespace=nginx-ingress -f nginx-ingress.values.yaml
helm upgrade --install prometheus-operator stable/prometheus-operator --namespace=observability -f prometheus-operator.values.yaml 
helm upgrade --install elasticsearch-exporter stable/elasticsearch-exporter --set es.uri=http://elasticsearch-master:9200 --set serviceMonitor.enabled=true --namespace=observability

helm repo add loki https://grafana.github.io/loki/charts
helm upgrade --install loki loki/loki-stack --namespace observability -f kubernetes-logging/loki.values.yaml