#!/bin/bash

while [[ -z "$(gcloud config get-value core/account)" ]]; 
do echo "waiting login" && sleep 2; 
done

while [[ -z "$(gcloud config get-value project)" ]]; 
do echo "waiting project" && sleep 2; 
done


gcloud config set compute/zone us-central1-b
gcloud container clusters create io


cd kubernetes

kubectl create deployment nginx --image=nginx:1.10.0
kubectl expose deployment nginx --port 80 --type LoadBalancer

kubectl create -f pods/monolith.yaml

kubectl create secret generic tls-certs --from-file tls/
kubectl create configmap nginx-proxy-conf --from-file nginx/proxy.conf
kubectl create -f pods/secure-monolith.yaml

kubectl create -f services/monolith.yaml

kubectl label pods secure-monolith 'secure=enabled'

kubectl create -f services/frontend.yaml
kubectl create -f deployments/auth.yaml
kubectl create -f services/auth.yaml
kubectl create -f deployments/hello.yaml
kubectl create -f services/hello.yaml

kubectl create -f deployments/frontend.yaml

kubectl create configmap nginx-frontend-conf --from-file=nginx/frontend.conf

gcloud compute firewall-rules create allow-monolith-nodeport \
  --allow=tcp:31000



