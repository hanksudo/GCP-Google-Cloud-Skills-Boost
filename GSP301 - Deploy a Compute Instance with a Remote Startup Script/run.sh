#!/bin/bash
gcloud config set compute/region us-east1
gcloud config set compute/zone us-east1-a

gsutil mb gs://${DEVSHELL_PROJECT_ID}

cat << EOF > install-web.sh
 #!/bin/bash
apt-get update
apt-get install -y apache2
EOF

gsutil cp install-web.sh gs://$(gcloud info --format='value(config.project)')

gcloud compute instances create my-instance \
  --scopes=storage-ro \
  --tags http-server,https-server \
  --metadata=startup-script-url=gs://${DEVSHELL_PROJECT_ID}/install-web.sh

gcloud compute firewall-rules create allow-http --target-tags http-server --source-ranges 0.0.0.0/0 --allow tcp:80