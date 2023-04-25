# gcp-setup
Scripts to aid in automating setup of GCP environment to support acquisition by Cado. For more details see the [Cado documentation](https://docs.cadosecurity.com/cado-response/deploy/gcp/gcp-settings). These should be run from inside the GCP Shell in the Primary account. 

To enable the GCP Shell in the GCP Console click on the Activate icon
[!Activate](gcp-setup-activate.png)


Automating GCP setup comprises three scripts

1. **gcp_setup_service_account.sh** -  Creates a 'CadoServiceAccount' service account and grant it the Editor role, enable the CloudBuild API and grant the Editor role to the default Cloud Build service account. ***This script should always be run first, unless the CadoServiceAccount already exists***.

   >*Usage*: `bash gcp_setup_service_account.sh`

2. **gcp_setup_WIF.sh** - Creates a Workload Identity Federation Pool 'CadoAWSPool' with an AWS provider 'cado-aws-provider' for a given AWS Account ID, grant the CadoServiceAccount access to the pool, create the JSON configuration for the provider to add to the Cado platform.

   >*Usage*: `bash gcp_setup_WIF.sh <12-digit-aws-acccount-id>`

*Note: Assumes you already have a service account called 'CadoServiceAccount' and will not work if that account is not available*

  
3. **gcp_setup_cross_project.sh** - Enables the Cloud Build API in the secondary project, adds the primary project's CadoServiceAccount and default cloud build service account to the secondary project's IAM

   >*Usage*: `bash gcp_setup_cross_project.sh <secondary-project-id>`
