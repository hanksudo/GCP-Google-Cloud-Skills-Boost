#!/bin/bash

# Preparation
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a

gcloud container clusters get-credentials echo-cluster
kubectl create deployment echo-web --image=gcr.io/qwiklabs-resources/echo-app:v1
kubectl expose deployment echo-web --type=LoadBalancer --port 80 --target-port 8000

# Build and deploy the updated application with a new tag
gsutil -m cp -r gs://${DEVSHELL_PROJECT_ID}/echo-web-v2.tar.gz .
mkdir echo-web && tar -zxvf echo-web-v2.tar.gz -C ./echo-web && cd echo-web

docker build -t echo-app:v2 .
docker tag echo-app:v2 gcr.io/${DEVSHELL_PROJECT_ID}/echo-app:v2

# Push the image to the Container Registry
docker push gcr.io/${DEVSHELL_PROJECT_ID}/echo-app:v2

kubectl set image deployment echo-web echo-app=gcr.io/qwiklabs-resources/echo-app:v2
kubectl scale deployment echo-web --replicas=2