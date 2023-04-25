#!/bin/bash

### This script will:
# - Enable the Cloud Build API in the target project
# - Add the Origin project's CadoServiceAccount and default cloud build service account to the target project's IAM

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <CROSS_PROJECT_ID>"
  exit 1
fi

# Set Origin project params
CROSS_PROJECT_ID=$1
PROJECT_ID="$(gcloud config get-value project)"
PROJECT_NUMBER="$(gcloud projects describe "${PROJECT_ID}" --format='value(projectNumber)')"
CADO_SERVICE_ACCOUNT_NAME="CadoServiceAccount"
CADO_SERVICE_ACCOUNT_EMAIL="${CADO_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
CLOUD_BUILD_SERVICE_ACCOUNT_EMAIL="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"

# Switch to target project and enable Cloud Build API
gcloud config set project ${CROSS_PROJECT_ID}
gcloud services enable cloudbuild.googleapis.com --project "${PROJECT_ID}"

# Add the origin project's CadoServiceAccount and CloudBuild service account to the target project's IAM
gcloud projects add-iam-policy-binding "${CROSS_PROJECT_ID}" \
    --member "serviceAccount:${CADO_SERVICE_ACCOUNT_EMAIL}" \
    --role "roles/editor"
gcloud projects add-iam-policy-binding "${CROSS_PROJECT_ID}" \
    --member "serviceAccount:${CLOUD_BUILD_SERVICE_ACCOUNT_EMAIL}" \
    --role "roles/editor"

# Switch back to origin project
gcloud config set project ${PROJECT_ID}

echo ""
echo Successfully setup permissions. ${PROJECT_ID} can now acquire from ${CROSS_PROJECT_ID}
