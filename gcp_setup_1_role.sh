#!/bin/bash

# This script is part 1 of the GCP setup scripts by Cado.

### This script will:
# - By default: Create a single 'CadoGCPRole' role with all permissions
# - With --split-roles: Create a 'CadoGCPRole' (persistent) and 'CadoGCPRoleTagged' role
# Note: If an organization ID is passed via --org, the role(s) are created at the organization level

set -e

# Define role IDs, titles and descriptions
ROLE_ID="CadoGCPRole"
ROLE_TITLE="Cado GCP Role"
ROLE_DESC="Custom role for Cado to acquire GCP assets."

TAGGED_ROLE_ID="CadoGCPRoleTagged"
TAGGED_ROLE_TITLE="Cado GCP Role Tagged"
TAGGED_ROLE_DESC="Custom role for Cado to acquire GCP assets (tagged resource permissions)."

### Permissions Breakdown ###
#
# - Persistent (always required, cannot be tag-scoped) -
#
# Authentication:
# iam.serviceAccounts.getAccessToken
# iam.serviceAccounts.implicitDelegation
# iam.serviceAccounts.actAs
# resourcemanager.projects.get
#
# Instance Acquisition:
# cloudbuild.builds.create
# cloudbuild.builds.get
# compute.disks.create
# compute.disks.delete
# compute.disks.list
# compute.disks.setLabels
# compute.disks.use
# compute.images.get
# compute.images.useReadOnly
# compute.images.delete
# compute.instances.create
# compute.instances.list
# compute.instances.setLabels
# compute.instances.setMetadata
# compute.instances.setServiceAccount
# compute.instances.getSerialPortOutput
# compute.instances.delete
# compute.machineTypes.list
# compute.networks.get
# compute.networks.list
# compute.projects.get
# compute.subnetworks.use
# compute.subnetworks.useExternalIp
# compute.zoneOperations.get
# compute.zones.list
#
# Storage Acquisition:
# storage.buckets.create
# storage.buckets.get
# storage.buckets.list
# storage.objects.create
#
# GKE Acquisition:
# container.pods.list
#
# - Tagged (scoped to tagged resources only) -
#
# Instance Acquisition:
# compute.disks.get
# compute.disks.useReadOnly
# compute.globalOperations.get
# compute.images.create
# compute.instances.get
# compute.subnetworks.list
# compute.subnetworks.get
#
# Storage Acquisition:
# storage.objects.get
# storage.objects.list
#
# GKE Acquisition:
# container.clusters.get
# container.clusters.list
# container.pods.exec
# container.pods.get

ALL_PERMISSIONS="cloudbuild.builds.create,cloudbuild.builds.get,compute.disks.create,compute.disks.delete,compute.disks.get,compute.disks.list,compute.disks.setLabels,compute.disks.use,compute.disks.useReadOnly,compute.globalOperations.get,compute.images.create,compute.images.get,compute.images.useReadOnly,compute.instances.create,compute.instances.get,compute.instances.list,compute.instances.setLabels,compute.instances.setMetadata,compute.instances.setServiceAccount,compute.machineTypes.list,compute.networks.get,compute.networks.list,compute.projects.get,compute.subnetworks.use,compute.subnetworks.useExternalIp,compute.zoneOperations.get,compute.zones.list,storage.buckets.create,storage.buckets.get,storage.buckets.list,storage.objects.create,storage.objects.get,storage.objects.list,container.clusters.get,container.clusters.list,container.pods.exec,container.pods.get,container.pods.list,iam.serviceAccounts.implicitDelegation,iam.serviceAccounts.getAccessToken,resourcemanager.projects.get,iam.serviceAccounts.actAs,compute.images.delete,compute.instances.getSerialPortOutput,compute.instances.delete,compute.subnetworks.list,compute.subnetworks.get"
PERSISTENT_PERMISSIONS="cloudbuild.builds.create,cloudbuild.builds.get,compute.disks.create,compute.disks.delete,compute.disks.list,compute.disks.setLabels,compute.disks.use,compute.images.get,compute.images.useReadOnly,compute.images.delete,compute.instances.create,compute.instances.list,compute.instances.setLabels,compute.instances.setMetadata,compute.instances.setServiceAccount,compute.instances.getSerialPortOutput,compute.instances.delete,compute.machineTypes.list,compute.networks.get,compute.networks.list,compute.projects.get,compute.subnetworks.use,compute.subnetworks.useExternalIp,compute.zoneOperations.get,compute.zones.list,storage.buckets.create,storage.buckets.get,storage.buckets.list,storage.objects.create,container.pods.list,iam.serviceAccounts.getAccessToken,iam.serviceAccounts.implicitDelegation,iam.serviceAccounts.actAs,resourcemanager.projects.get"

TAGGED_PERMISSIONS="compute.disks.get,compute.disks.useReadOnly,compute.globalOperations.get,compute.images.create,compute.instances.get,compute.subnetworks.list,compute.subnetworks.get,storage.objects.get,storage.objects.list,container.clusters.get,container.clusters.list,container.pods.exec,container.pods.get"

help() {
  echo "Usage: $(basename $0) [--split-roles] [--org=ORG_ID] [--help]"
  echo ""
  echo "  --split-roles  Create separate persistent and tagged roles instead of one combined role"
  echo "  --org=ORG_ID   Create role(s) at the organization level instead of the current project"
  echo "  -h, --help     Show this message"
  exit 0
}

# Parse arguments
SPLIT_ROLES=false
ORG_ID=""

for arg in "$@"; do
  case $arg in
    --split-roles) SPLIT_ROLES=true ;;
    --org=*) ORG_ID="${arg#--org=}" ;;
    --help) help ;;
    -h) help ;;
  esac
done


echo *** Debug Information and Permissions Check ***
echo Currently running with permissions from:
gcloud auth list

echo Checking current project:
gcloud config get-value project
CURRENT_PROJECT=$(gcloud config get-value project)

echo "Permissions for the current role, to check it has permission to create the role:"
gcloud projects get-iam-policy $CURRENT_PROJECT --flatten="bindings[].members" --format='table(bindings.role)' --filter="bindings.members:$(gcloud auth list --format='value(account)')"


create_role() {
  local role_id=$1
  local role_title=$2
  local role_desc=$3
  local permissions=$4

  if [[ -n "$ORG_ID" ]]; then
    gcloud iam roles create $role_id \
      --organization $ORG_ID \
      --title "$role_title" \
      --description "$role_desc" \
      --permissions $permissions \
      --stage GA
    gcloud iam roles describe $role_id --organization $ORG_ID --format="value(name)"
  else
    local project_id="$(gcloud config get-value project)"
    gcloud iam roles create $role_id \
      --project $project_id \
      --title "$role_title" \
      --description "$role_desc" \
      --permissions $permissions \
      --stage GA
    gcloud iam roles describe $role_id --project $project_id --format="value(name)"
  fi
}

if [[ "$SPLIT_ROLES" == true ]]; then
  echo "Creating split roles (persistent + tagged)..."
  ROLE_NAME=$(create_role "$ROLE_ID" "$ROLE_TITLE" "$ROLE_DESC" "$PERSISTENT_PERMISSIONS")
  TAGGED_ROLE_NAME=$(create_role "$TAGGED_ROLE_ID" "$TAGGED_ROLE_TITLE" "$TAGGED_ROLE_DESC" "$TAGGED_PERMISSIONS")

  echo ""
  echo "Persistent role '$ROLE_TITLE' created: $ROLE_NAME"
  echo "Tagged role '$TAGGED_ROLE_TITLE' created: $TAGGED_ROLE_NAME"
  echo "Save these role IDs to be used in the next script."
else
  echo "Creating single role..."
  ROLE_NAME=$(create_role "$ROLE_ID" "$ROLE_TITLE" "$ROLE_DESC" "$ALL_PERMISSIONS")

  echo ""
  echo "Role '$ROLE_TITLE' created: $ROLE_NAME"
  echo "Save this role ID to be used in the next script."
fi
