# GSP314 - Deploy and Manage Cloud Environments with Google Cloud: Challenge Lab

## Task 1

```bash
export CLUSTER_NAME=kraken-production-714
export INSTANCE_NAME=kraken-admin-175

gcloud config set compute/region us-east1
gcloud config set compute/zone us-east1-b

cd /work/dm
sed -i s/SET_REGION/us-east1/g prod-network.yaml

gcloud deployment-manager deployments create prod-network --config=prod-network.yaml

gcloud container clusters create ${CLUSTER_NAME} \
    --num-nodes=2 --network=kraken-prod-vpc --subnetwork kraken-prod-subnet
gcloud container clusters get-credentials ${CLUSTER_NAME}

cd /work/k8s
kubectl apply -f service-prod-frontend.yaml 
kubectl apply -f service-prod-backend.yaml
kubectl apply -f deployment-prod-backend.yaml
kubectl apply -f deployment-prod-frontend.yaml

gcloud compute instances create ${INSTANCE_NAME} --network-interface="subnet=kraken-mgmt-subnet" --network-interface="subnet=kraken-prod-subnet"
```

## Task 2

Monitoring -> Alerting

Threshold=80%

Set notification channel

## Task 3

```bash
gcloud container clusters get-credentials spinnaker-tutorial --zone us-east1-b --project qwiklabs-gcp-03-109b0c15021b \
 && kubectl port-forward $(kubectl get pod --selector="app=spin,cluster=spin-deck" --output jsonpath='{.items[0].metadata.name}') 8080:9000
```
