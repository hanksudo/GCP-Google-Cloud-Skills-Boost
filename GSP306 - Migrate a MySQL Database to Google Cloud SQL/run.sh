#!/bin/bash

# Create Cloud MySQL instane and database on GCP UI

# Dump current database
mysqldump --databases wordpress -h localhost -u blogadmin -p \
    --hex-blob --skip-triggers --single-transaction \
    --default-character-set=utf8mb4 > wordpress.sql

# Upload to storage
export PROJECT_ID=$(gcloud info --format='value(config.project)')
gsutil mb gs://${PROJECT_ID}
gsutil cp wordpress.sql gs://${PROJECT_ID}

# Import database from storage on GCP UI

# Create user account on GCP UI
blogadmin
Password1*

# Set CIDR to wordpress database connection on GCP UI

# Modify wp-config and set cloud instance public IP
sudo vim /var/www/html/wordpress/wp-config.php