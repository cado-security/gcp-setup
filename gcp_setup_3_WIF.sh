#!/bin/bash

# This script is part 3 of the GCP setup scripts by Cado.

### This script will:
# - Create a Workload Identity Federation Pool 'CadoAWSPool' with an AWS provider 'cado-aws-provider' from the given AWS Account ID.
# - Grant the CadoServiceAccount access to the pool.
# - Create the JSON configuration for the provider to add to the Cado platform.

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <AWS_ACCOUNT_ID>"
  exit 1
fi

# Get the active Google Cloud Project details and set service account params
PROJECT_ID="$(gcloud config get-value project)"
PROJECT_NUMBER="$(gcloud projects describe "${PROJECT_ID}" --format='value(projectNumber)')"
CADO_SERVICE_ACCOUNT_NAME="CadoServiceAccount"
CADO_SERVICE_ACCOUNT_EMAIL="${CADO_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Set the AWS account ID, pool name, and provider name
AWS_ACCOUNT_ID="$1"
POOL_NAME="cado-aws-pool" 
PROVIDER_NAME="cado-aws-provider"

# Set up the Workload Identity Federation pool
gcloud iam workload-identity-pools create ${POOL_NAME} \
    --location=global \
    --description="Workload Identity Federation pool for Cado AWS" 

# Set up the Workload Identity Federation provider
gcloud iam workload-identity-pools providers create-aws ${PROVIDER_NAME} \
    --location=global \
    --workload-identity-pool=${POOL_NAME} \
    --display-name="Cado-AWS-Provider" \
    --attribute-mapping="attribute.aws_role=assertion.arn.contains('assumed-role') ? assertion.arn.extract('{account_arn}assumed-role/') + 'assumed-role/' + assertion.arn.extract('assumed-role/{role_name}/') : assertion.arn,google.subject=assertion.arn" \
    --account-id=${AWS_ACCOUNT_ID}

# # Grant the CadoServiceAccount access to the pool
gcloud iam service-accounts add-iam-policy-binding   --role=roles/iam.workloadIdentityUser \
    --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/*" \
    ${CADO_SERVICE_ACCOUNT_EMAIL}

echo ""
echo "CadoAWSPool has been created and CadoServiceAccount has been granted access. Please now download the client config under 'Connected Service Accounts' to use in the Cado Platform"
echo "Note: the changes made by this script can take a few minutes to become live"
