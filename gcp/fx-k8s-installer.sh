#!/bin/bash

echo "## CREATING STORAGE CLASS ##"
kubectl apply -f gcp-storage-class-yaml
echo " "

echo "## CREATING DOCKER LOGIN SECRET ##" 
kubectl create secret docker-registry dockerlogin --docker-username=fxlabs --docker-password=82f2f3d4-6fab-4791-821a-2d858d8932cf --docker-email=cloud@apisec.ai
echo " "

echo "## Installing NGINX ingress controller on GKE cluster ##"
kubectl apply -f nginx-ingress.yaml
sleep 30
echo " "

echo "## Creating Config Environment Variables ##"
kubectl apply -f fx-cp-secret.yaml
kubectl apply -f fx-dependent-config.yaml
sleep 5
kubectl get secret
echo " "
kubectl get cm
echo " "

echo "## DEPLOYING RABBITMQ DATA SERVICES ##  "
### Add helm repo
helm repo add bitnami https://charts.bitnami.com/bitnami
sleep 10

echo "### Install Rabbitmq spesific version ###"
helm install fx-rabbitmq bitnami/rabbitmq --version 6.8.3 -f rabbit-values.yaml
sleep 120 
echo " "

echo "### Deleting Rabbitmq POD's###" 
kubectl delete pods fx-rabbitmq-0 fx-rabbitmq-1 fx-rabbitmq-2
sleep 10

echo "### Patch Rabbitmq Liveness and Readiness Healthcheck Probes ###"
kubectl patch statefulset fx-rabbitmq --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/livenessProbe", "value":{
  "exec": {
    "command": [
      "/bin/bash",
      "-ec",
      "rabbitmq-diagnostics -q ping"
    ]
  },
  "timeoutSeconds": 10,
}}]'

kubectl patch statefulset fx-rabbitmq --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/readinessProbe", "value":{
  "exec": {
    "command": [
      "/bin/bash",
      "-ec",
      "rabbitmq-diagnostics -q ping"
    ]
  },
  "timeoutSeconds": 10,
}}]'

sleep 10

echo "## APPLYING CM AND SECRETS ##"
kubectl apply -f tcp-configmap.yaml
kubectl apply -f cp-ingress-svc.yaml
kubectl apply -f rabbit-ingress-svc.yaml
kubectl get cm -n ingress-nginx
echo " "
kubectl get ingress
echo " "


echo "## DEPLOYING POSTGRES ##  "
### Install Postgresql Operator
kubectl create -f postgres-operator/manifests/configmap.yaml  # configuration
kubectl create -f postgres-operator/manifests/operator-service-account-rbac.yaml  # identity and permissions
kubectl create -f postgres-operator/manifests/postgres-operator.yaml  # deployment
kubectl create -f postgres-operator/manifests/api-service.yaml  # operator API to be used by UI
sleep 30

echo "### Create fx-admin user secret.###" 
kubectl apply -f postgres-secret.yaml

echo "## Create Postgresql Version 10 cluster ##" 
kubectl apply -f postgres.yaml
sleep 30

echo "## DEPLOYING ELASTICSEARCH ##"
kubectl apply -f https://download.elastic.co/downloads/eck/2.0.0/operator.yaml
sleep 15

echo "## DEPLOYING ELASTIC SERVICE ##"
kubectl apply -f elasticsearch-service.yaml
kubectl apply -f elasticsearch.yaml
sleep 5
echo " "

echo "# RabbitMQ Scanbot password (These commands need to executed on RabbitMQ pods) ##"
kubectl exec -it $(kubectl get pods -o=name | grep fx-rabbitmq-0 ) -- rabbitmqctl  add_user fx_bot_user fx_bot_uat_pwd
kubectl exec -it $(kubectl get pods -o=name | grep fx-rabbitmq-0 ) -- rabbitmqctl  set_permissions -p fx fx_bot_user "" ".*" ".*"
sleep 30
echo " "

echo "## LISTING THE DEPLOYED PODS ##" 
kubectl get pods -o wide
sleep 5
echo " "

echo "## DEPLOYING CONTROL-PLANE ##" 
kubectl apply -f fx-control-plane.yaml
sleep 60
echo " "

echo "## DEPLOYING BACKEND SERVICES ##"
kubectl apply -f fx-backend-pods-manifest.yaml
sleep 60
echo " "

kubectl get service -o wide
sleep 10
echo "## Successfully deployed Services in a K8S Cluster ##"

