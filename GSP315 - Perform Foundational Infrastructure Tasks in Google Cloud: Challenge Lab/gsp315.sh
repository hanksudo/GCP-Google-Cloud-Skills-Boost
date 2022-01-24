#!/bin/bash
PROJECT_ID=
BUCKET_NAME=
TOPIC_NAME=
CLOUD_FUNCTION_NAME=

gcloud config set project ${PROJECT_ID}
gcloud config set compute/zone us-east1-b
gcloud config set compute/region us-east1

# Task 1
gsutil mb -p ${PROJECT_ID} gs://${BUCKET_NAME}

# Task 2
gcloud pubsub topics create ${TOPIC_NAME}

# Task 3: Create the thumbnail Cloud Function
gcloud functions deploy ${CLOUD_FUNCTION_NAME} \
  --entry-point=thumbnail \
  --trigger-resource ${BUCKET_NAME} \
  --trigger-event google.storage.object.finalize \
  --runtime nodejs14

wget https://storage.googleapis.com/cloud-training/gsp315/map.jpg
gsutil cp map.jpg gs://${BUCKET_NAME}

# Task 4: Remove the previous cloud engineer
# Go to IAM page and remove the permission