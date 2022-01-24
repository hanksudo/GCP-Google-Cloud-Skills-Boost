# GSP114 - Continuous Delivery Pipelines with Spinnaker and Kubernetes Engine

```bash
gcloud config set compute/zone us-central1-f

# Create cluster
gcloud container clusters create spinnaker-tutorial \
    --machine-type=n1-standard-2

# Create service account
gcloud iam service-accounts create spinnaker-account \
    --display-name spinnaker-account

# Store the service account email address and your current project ID in environment variables for use in later commands:
export SA_EMAIL=$(gcloud iam service-accounts list \
    --filter="displayName:spinnaker-account" \
    --format='value(email)')
export PROJECT=$(gcloud info --format='value(config.project)')

# Bind storage.admin role to service account
gcloud projects add-iam-policy-binding "$PROJECT" \
    --role roles/storage.admin \
    --member serviceAccount:"$SA_EMAIL"

# Download service account key
gcloud iam service-accounts keys create spinnaker-sa.json \
     --iam-account "$SA_EMAIL"
```

## Setup Cloud Pub/Sub to trigger Spinnaker pipelines

```bash
gcloud pubsub topics create projects/"$PROJECT"/topics/gcr

# Create subscription
gcloud pubsub subscriptions create gcr-triggers \
    --topic projects/"${PROJECT}"/topics/gcr

# Give spinnaker service account permissions to read gcr-triggers subscription
gcloud beta pubsub subscriptions add-iam-policy-binding gcr-triggers \
    --role roles/pubsub.subscriber --member serviceAccount:"$SA_EMAIL"
```

## Deploying Spinnaker using Helm

```bash
# Grant Helm the cluster-admin role in cluster
kubectl create clusterrolebinding user-admin-binding \
    --clusterrole=cluster-admin --user=$(gcloud config get-value account)

# Grant Spinnaker the cluster-admin role so it can deploy resources across all namespaces
kubectl create clusterrolebinding spinnaker-admin \
    --clusterrole=cluster-admin --serviceaccount=default:default

# Helm repositories
helm repo add stable https://charts.helm.sh/stable
helm repo update

# Configure Spinnaker
export BUCKET=$PROJECT-spinnaker-config
gsutil mb -c regional -l us-central1 gs://$BUCKET

# Create Spinnaker config
sh generate-spinnaker-config.sh

# Deploy the Spinnaker chart
helm install -n default cd stable/spinnaker -f spinnaker-config.yaml \
           --version 2.0.0-rc9 --timeout 10m0s --wait

# Port forward Spinnaker
export DECK_POD=$(kubectl get pods --namespace default -l "cluster=spin-deck" \
    -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward --namespace default $DECK_POD 8080:9000 >> /dev/null &
```

## Building the Docker image

```bash
# sample source code
gsutil -m cp -r gs://spls/gsp114/sample-app.tar .
mkdir sample-app && tar xvf sample-app.tar -C ./sample-app && cd sample-app

git config --global user.email "$(gcloud config get-value core/account)"
git config --global user.name "$(gcloud config get-value core/account)"

git init && git add . && git commit -m "Initial commit"

# Create and Push code to repository
gcloud source repos create sample-app
git config credential.helper gcloud.sh
git remote add origin https://source.developers.google.com/p/$PROJECT/r/sample-app
git push origin master
```

### Configure Trigger in Cloud Build

Name: sample-app-tags
Event: Push new tag
Repository: sample-app
Tag: v1.*
Configuration: cloudbuild.yaml

### Prepare your Kubernetes Manifests for use in Spinnaker

```bash
gsutil mb -l us-central1 gs://$PROJECT-kubernetes-manifests
# Enable versioning on the bucket so that you have a history of your manifest
gsutil versioning set on gs://$PROJECT-kubernetes-manifests
# set projec ID in manifests
sed -i s/PROJECT/$PROJECT/g k8s/deployments/*

git commit -a -m "Set project ID"
```

### Build image

```bash
git tag v1.0.0
git push --tags
```

This should trigger Cloud Build

## Configuring your deployment pipelines

### Install spin CLI for managing Spinnaker

```bash
curl -LO https://storage.googleapis.com/spinnaker-artifacts/spin/1.14.0/linux/amd64/spin && chmod +x spin
```

### Create the deployment pipeline

```bash
# create Spinnaker app
./spin application save --application-name sample \
                        --owner-email "$(gcloud config get-value core/account)" \
                        --cloud-providers kubernetes \
                        --gate-endpoint http://localhost:8080/gate
# upload example pipeline
export PROJECT=$(gcloud info --format='value(config.project)')
sed s/PROJECT/$PROJECT/g spinnaker/pipeline-deploy.json > pipeline.json
./spin pipeline save --gate-endpoint http://localhost:8080/gate -f pipeline.json
```

### Manually Trigger and View your pipeline execution

- Go WebPreview on Port 8080
- Manually trigger sample app on Spinnaker UI

After build, go to Load balancers and check the IP of frontend to see the result.

### Trigger your pipeline from code changes

```bash
# change color
sed -i 's/orange/blue/g' cmd/gke-info/common-service.go

git commit -am "Change color to blue"
git tag v1.0.1
git push --tags
```
