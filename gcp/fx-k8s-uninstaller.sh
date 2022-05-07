#!/bin/bash

## Deleting all deployed k8s resources from the cluster
echo "## DELETNG APISec Product Services ## "
kubectl delete -f fx-control-plane.yaml 
kubectl delete -f fx-backend-pods-manifest.yaml 
sleep 30
echo "#############################################"

echo "## DELETING RABBITMQ DATA SERVICES ##  "
helm delete fx-rabbitmq
sleep 10
echo "###########################################################"

echo "## DELETING ELASTICSEARCH DATA SERVICES ##  "
kubectl delete -f elasticsearch-service.yaml 
sleep 10 
kubectl delete -f elasticsearch.yaml 
kubectl delete -f https://download.elastic.co/downloads/eck/2.0.0/operator.yaml
echo "#######################################################" 

echo "## DELETING POSTGRES CLUSTER ##"
kubectl delete postgresql fx-postgres
sleep 20
echo "##########################################"

echo "# Delete  postgresql manifests ##"
kubectl delete -f postgres-configmap.yaml
kubectl delete -f postgres-operator-service-account-rbac.yaml
kubectl delete -f postgres-operator.yaml
kubectl delete -f postgres-api-service.yaml
kubectl delete -f postgres-secret.yaml
kubectl delete -f postgres.yaml
sleep 10
echo "########################################"

echo "## Deleting Config Environment Variables ##"
kubectl delete -f fx-cp-secret.yaml 
kubectl delete -f fx-dependent-config.yaml
kubectl delete -f tcp-configmap.yaml
kubectl delete -f cp-ingress-svc.yaml
kubectl delete -f rabbit-ingress-svc.yaml
sleep 5
echo " ##################################### "

echo "## Deleting NGINX INGRESS CONTROLER ##"
kubectl delete -f nginx-ingress.yaml
sleep 10
echo "##################################### "


echo "## veryfing the POD's deletion ##"
kubectl get all 
kubectl get all -n ingress-nginx

 
