#!/bin/bash

# This script is part 1 of the GCP setup scripts by Cado.

### This script will:
# - Create a 'CadoGCPRole' role in the active project and add the PERMISSIONS list to it
# Note: If an organization ID is passed as a parameter, the role is created at the organization level

set -e

# Define role ID, title and description
ROLE_ID="CadoGCPRole"
ROLE_TITLE="Cado GCP Role"
ROLE_DESC="Custom role for Cado to acquire GCP assets."
PERMISSIONS="cloudbuild.builds.create,cloudbuild.builds.get,compute.disks.get,compute.disks.useReadOnly,compute.globalOperations.get,compute.images.create,compute.instances.get,compute.instances.list,container.clusters.get,container.clusters.list,container.pods.exec,container.pods.get,container.pods.list,iam.serviceAccounts.getAccessToken,iam.serviceAccounts.implicitDelegation,resourcemanager.projects.get,storage.buckets.get,storage.buckets.list,storage.objects.get,storage.objects.list"

### Permissions Breakdown ###
# - Authentication -
# iam.serviceAccounts.getAccessToken
# iam.serviceAccounts.implicitDelegation
# resourcemanager.projects.get

# - Instance Acquisition -
# cloudbuild.builds.create
# cloudbuild.builds.get
# compute.disks.get
# compute.disks.useReadOnly
# compute.globalOperations.get
# compute.images.create
# compute.instances.get
# compute.instances.list
# storage.buckets.list

# - Storage Acquisition -
# storage.buckets.list
# storage.buckets.get
# storage.objects.get
# storage.objects.list

# - GKE Acquisition - 
# container.pods.list
# container.clusters.get
# container.clusters.list
# container.pods.exec
# container.pods.get

# Check if an organization ID was provided as an argument
if [[ $# -eq 1 ]]; then
  ORG_ID=$1
  # Create custom role at the organization level
  gcloud iam roles create $ROLE_ID \
    --organization $ORG_ID \
    --title "$ROLE_TITLE" \
    --description "$ROLE_DESC" \
    --permissions $PERMISSIONS \
    --stage GA
  
  # Get the role ID (name field)
  ROLE_NAME=$(gcloud iam roles describe $ROLE_ID --organization $ORG_ID --format="value(name)")

else
  # Create custom role at the project level

  # Get the active Google Cloud Project ID
  PROJECT_ID="$(gcloud config get-value project)"

  gcloud iam roles create $ROLE_ID \
    --project $PROJECT_ID \
    --title "$ROLE_TITLE" \
    --description "$ROLE_DESC" \
    --permissions $PERMISSIONS \
    --stage GA

  # Get the role ID (name field)
  ROLE_NAME=$(gcloud iam roles describe $ROLE_ID --project $PROJECT_ID --format="value(name)")
fi

echo ""
echo "Role '$ROLE_TITLE' has been created."
echo "Save this role ID to be used in the next script: $ROLE_NAME"
