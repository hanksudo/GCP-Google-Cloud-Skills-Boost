#!/bin/bash
INSTANCE_NAME=nucleus-jumphost-716
PROJECT_ID=qwiklabs-gcp-02-bde452a033ef
PORT=8081
FIREWALL_RULE=permit-tcp-rule-791

# Config
gcloud config set project ${PROJECT_ID}
gcloud config set compute/region us-east1
gcloud config set compute/zone us-east1-b

# Task 1
gcloud compute instances create ${INSTANCE_NAME} --machine-type f1-micro

# Task 2
gcloud container clusters create my-cluster
kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:2.0
kubectl expose deployment hello-server --type=LoadBalancer --port ${PORT}

# Task 3
cat << EOF > startup.sh
#! /bin/bash
apt-get update
apt-get install -y nginx
service nginx start
sed -i -- 's/nginx/Google Cloud Platform - '"\$HOSTNAME"'/' /var/www/html/index.nginx-debian.html
EOF

# Create instance template
gcloud compute instance-templates create nginx-template --metadata-from-file startup-script=startup.sh

# Create target pool
gcloud compute target-pools create nginx-pool

# Create manage group
gcloud compute instance-groups managed create nginx-group \
   --template=nginx-template --size=2 --target-pool nginx-pool
gcloud compute instance-groups set-named-ports nginx-group --named-ports "http:80"

# Create firewall rule
gcloud compute firewall-rules create ${FIREWALL_RULE} --allow tcp:80

gcloud compute health-checks create http http-basic-check \
    --port 80

gcloud compute backend-services create web-backend-service \
    --protocol=HTTP \
    --port-name=http \
    --health-checks=http-basic-check \
    --global

gcloud compute backend-services add-backend web-backend-service \
    --instance-group=nginx-group \
    --instance-group-zone=us-east1-b \
    --global

gcloud compute url-maps create web-map-http \
    --default-service web-backend-service

gcloud compute target-http-proxies create http-lb-proxy \
    --url-map web-map-http

gcloud compute forwarding-rules create http-content-rule \
    --global \
    --target-http-proxy http-lb-proxy \
    --ports 80