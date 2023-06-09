#!/bin/bash

# This script is part 2 of the GCP setup scripts by Cado.

### This script will:
# - Create a 'CadoServiceAccount' service account and grant it the CadoGCPRole role.
# - Enable the CloudBuild API and grant the CadoGCPRole role to the default Cloud Build service account.

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <CADO_GCP_ROLE ID>"
  exit 1
fi

ROLE_ID=$1

# Get the active Google Cloud Project ID and Number
PROJECT_ID="$(gcloud config get-value project)"
PROJECT_NUMBER="$(gcloud projects describe "${PROJECT_ID}" --format='value(projectNumber)')"

# Set the service account params
CADO_SERVICE_ACCOUNT_NAME="CadoServiceAccount"
CADO_SERVICE_ACCOUNT_EMAIL="${CADO_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Enable Cloud Build API if not already enabled and get the default Cloud Build service account email
gcloud services enable cloudbuild.googleapis.com --project "${PROJECT_ID}"
CLOUD_BUILD_SERVICE_ACCOUNT_EMAIL="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"

# Create the CadoServiceAccount service account
gcloud iam service-accounts create "${CADO_SERVICE_ACCOUNT_NAME}" \
    --display-name "${CADO_SERVICE_ACCOUNT_NAME}" \
    --project "${PROJECT_ID}"

# Grant Editor permissions to the CadoServiceAccount service account
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member "serviceAccount:${CADO_SERVICE_ACCOUNT_EMAIL}" \
    --role "${ROLE_ID}"

# Grant Editor permissions to the default Cloud Build service account
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member "serviceAccount:${CLOUD_BUILD_SERVICE_ACCOUNT_EMAIL}" \
    --role "${ROLE_ID}"

echo ""
echo "Successfully created CadoServiceAccount and granted CadoGCPRole permissions to the CadoServiceAccount and default Cloud Build service account."