#!/bin/bash

# This script is part 1 of the GCP setup scripts by Cado.

### This script will:
# - Create a 'CadoGCPRole' (persistent) role and a 'CadoGCPRoleTagged' role in the active project
# Note: If an organization ID is passed as a parameter, roles are created at the organization level

set -e

# Define role IDs, titles and descriptions
ROLE_ID="CadoGCPRole_GeorgeDev"
ROLE_TITLE="Cado GCP Role GeorgeDev"
ROLE_DESC="Custom role for Cado to acquire GCP assets (persistent permissions)."

TAGGED_ROLE_ID="CadoGCPRoleTagged_GeorgeDev"
TAGGED_ROLE_TITLE="Cado GCP Role Tagged GeorgeDev"
TAGGED_ROLE_DESC="Custom role for Cado to acquire GCP assets (tagged resource permissions)."

### Permissions Breakdown ###
# Persistent:
#
# IAM + Projects:
# iam.serviceAccounts.getAccessToken
# iam.serviceAccounts.implicitDelegation
# resourcemanager.projects.get
#
# GCP Compute:
# cloudbuild.builds.create
# cloudbuild.builds.get
# compute.instances.list
#
# GCP Storage:
# storage.buckets.list
# storage.buckets.get
#
# GKE:
# container.pods.list
#
# Tagged:
#
# GCP Compute:
# compute.disks.get
# compute.disks.useReadOnly
# compute.globalOperations.get
# compute.images.create
# compute.instances.get
# compute.subnetworks.list
# compute.subnetworks.get
#
# GCP Storage:
# storage.objects.get
# storage.objects.list
#
# GKE:
# container.clusters.get
# container.clusters.list
# container.pods.exec
# container.pods.get

PERSISTENT_PERMISSIONS="cloudbuild.builds.create,cloudbuild.builds.get,compute.instances.list,storage.buckets.list,storage.buckets.get,container.pods.list,iam.serviceAccounts.getAccessToken,iam.serviceAccounts.implicitDelegation,resourcemanager.projects.get"

TAGGED_PERMISSIONS="compute.disks.get,compute.disks.useReadOnly,compute.globalOperations.get,compute.images.create,compute.instances.get,compute.subnetworks.list,compute.subnetworks.get,storage.objects.get,storage.objects.list,container.clusters.get,container.clusters.list,container.pods.exec,container.pods.get"


echo *** Debug Information and Permissions Check ***
echo Currently running with permissions from:
gcloud auth list

echo Checking current project:
gcloud config get-value project
CURRENT_PROJECT=$(gcloud config get-value project)

echo "Permissions for the current role, to check it has permission to create the role:"
gcloud projects get-iam-policy $CURRENT_PROJECT --flatten="bindings[].members" --format='table(bindings.role)' --filter="bindings.members:$(gcloud auth list --format='value(account)')"


create_roles() {
  local scope_flag=$1
  local scope_value=$2

  echo "Creating persistent role..."
  gcloud iam roles create $ROLE_ID \
    $scope_flag $scope_value \
    --title "$ROLE_TITLE" \
    --description "$ROLE_DESC" \
    --permissions $PERSISTENT_PERMISSIONS \
    --stage GA

  echo "Creating tagged role..."
  gcloud iam roles create $TAGGED_ROLE_ID \
    $scope_flag $scope_value \
    --title "$TAGGED_ROLE_TITLE" \
    --description "$TAGGED_ROLE_DESC" \
    --permissions $TAGGED_PERMISSIONS \
    --stage GA
}

if [[ $# -eq 1 ]]; then
  ORG_ID=$1
  echo "Creating roles at the organization level..."
  create_roles "--organization" "$ORG_ID"

  ROLE_NAME=$(gcloud iam roles describe $ROLE_ID --organization $ORG_ID --format="value(name)")
  TAGGED_ROLE_NAME=$(gcloud iam roles describe $TAGGED_ROLE_ID --organization $ORG_ID --format="value(name)")
else
  PROJECT_ID="$(gcloud config get-value project)"
  echo "Creating roles at the project level..."
  create_roles "--project" "$PROJECT_ID"

  ROLE_NAME=$(gcloud iam roles describe $ROLE_ID --project $PROJECT_ID --format="value(name)")
  TAGGED_ROLE_NAME=$(gcloud iam roles describe $TAGGED_ROLE_ID --project $PROJECT_ID --format="value(name)")
fi

echo ""
echo "Persistent role '$ROLE_TITLE' created: $ROLE_NAME"
echo "Tagged role '$TAGGED_ROLE_TITLE' created: $TAGGED_ROLE_NAME"
echo "Save these role IDs to be used in the next script."
