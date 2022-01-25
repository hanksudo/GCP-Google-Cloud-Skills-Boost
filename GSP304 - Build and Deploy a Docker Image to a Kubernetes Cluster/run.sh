#!/bin/bash
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a

# Create a Kubernetes Cluster
gcloud container clusters create echo-cluster \
    --machine-type=n1-standard-2

# Build a tagged Docker Image
gsutil -m cp -r gs://${DEVSHELL_PROJECT_ID}/echo-web.tar.gz .
mkdir echo-web && tar zxvf echo-web.tar.gz -C ./echo-web && cd echo-web

docker build -t echo-app:v1 .
docker tag echo-app:v1 gcr.io/${DEVSHELL_PROJECT_ID}/echo-app:v1
docker push gcr.io/${DEVSHELL_PROJECT_ID}/echo-app:v1

# Deploy the application to the Kubernetes Cluster
gcloud container clusters get-credentials echo-cluster

kubectl create deployment echo-web --image=gcr.io/${DEVSHELL_PROJECT_ID}/echo-app:v1
kubectl expose deployment echo-web --type=LoadBalancer --port 80 --target-port 8000

kubectl get service