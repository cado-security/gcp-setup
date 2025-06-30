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
PERMISSIONS="cloudbuild.builds.create,cloudbuild.builds.get,compute.disks.create,compute.disks.delete,compute.disks.get,compute.disks.list,compute.disks.setLabels,compute.disks.use,compute.disks.useReadOnly,compute.globalOperations.get,compute.images.create,compute.images.get,compute.images.useReadOnly,compute.instances.create,compute.instances.get,compute.instances.list,compute.instances.setLabels,compute.instances.setMetadata,compute.instances.setServiceAccount,compute.machineTypes.list,compute.networks.get,compute.networks.list,compute.projects.get,compute.subnetworks.use,compute.subnetworks.useExternalIp,compute.zoneOperations.get,compute.zones.list,storage.buckets.create,storage.buckets.get,storage.buckets.list,storage.objects.create,storage.objects.get,storage.objects.list,container.clusters.get,container.clusters.list,container.pods.exec,container.pods.get,container.pods.list,iam.serviceAccounts.implicitDelegation,iam.serviceAccounts.getAccessToken,resourcemanager.projects.get,iam.serviceAccounts.actAs,compute.images.delete,compute.instances.getSerialPortOutput,compute.instances.delete,compute.subnetworks.list,compute.subnetworks.get"

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
# compute.subnetworks.list
# compute.subnetworks.get

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


echo *** Debug Information and Permissions Check ***
echo Currently running with permissions from:
gcloud auth list

echo Checking current project:
gcloud config get-value project
CURRENT_PROJECT=$(gcloud config get-value project)

# Echo out the permissions of the role we're running as in the cloud shell via gcloud command:
echo "Permissions for the current role, to check it has permission to create the role:"
gcloud projects get-iam-policy $CURRENT_PROJECT --flatten="bindings[].members" --format='table(bindings.role)' --filter="bindings.members:$(gcloud auth list --format='value(account)')"


# Check if an organization ID was provided as an argument
if [[ $# -eq 1 ]]; then
  ORG_ID=$1
  # Create custom role at the organization level
  echo "Creating role at the organization level..."
  echo gcloud iam roles create $ROLE_ID \
    --organization $ORG_ID \
    --title "$ROLE_TITLE" \
    --description "$ROLE_DESC" \
    --permissions $PERMISSIONS \
    --stage GA 
  gcloud iam roles create $ROLE_ID \
    --organization $ORG_ID \
    --title "$ROLE_TITLE" \
    --description "$ROLE_DESC" \
    --permissions $PERMISSIONS \
    --stage GA
  
  # Get the role ID (name field)
  ROLE_NAME=$(gcloud iam roles describe $ROLE_ID --organization $ORG_ID --format="value(name)")
  echo "Role ID: $ROLE_NAME"

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
  echo gcloud iam roles create $ROLE_ID \
    --project $PROJECT_ID \
    --title "$ROLE_TITLE" \
    --description "$ROLE_DESC" \
    --permissions $PERMISSIONS \
    --stage GA

  # Get the role ID (name field)
  ROLE_NAME=$(gcloud iam roles describe $ROLE_ID --project $PROJECT_ID --format="value(name)")
  echo "Role ID: $ROLE_NAME"
fi

echo ""
echo "Role '$ROLE_TITLE' has been created."
echo "Save this role ID to be used in the next script: $ROLE_NAME"
