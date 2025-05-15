# Hybrid AI Portal aka HAIP

-------------------------------------------------
##################################
# List of things to improve
##################################

// TODO: describe how to connect to arc enabled k3s via Arc cluster connect https://learn.microsoft.com/en-us/azure/azure-arc/kubernetes/cluster-connect?tabs=azure-cli

-------------------------------------------------


A self-hosted LLM web portal powered by Ollama on Azure Arc-enabled K3s.

This project uses Terraform to deploy Azure resources, including a resource group and a Static Web App.

### Prerequisites

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Terraform](https://developer.hashicorp.com/terraform/downloads)
- Docker and docker compose
- kubectl
- Extension

### Authentication with Azure CLI

Before deploying any infrastructure, ensure you are authenticated to Azure using the device login flow.

An Azure **Service Principal** with at least Contributor permissions
- Export the following environment variables for Terraform to authenticate:

```bash
export ARM_CLIENT_ID="<your-client-id>"
export ARM_CLIENT_SECRET="<your-client-secret>"
export ARM_SUBSCRIPTION_ID="<your-subscription-id>"
export ARM_TENANT_ID="<your-tenant-id>"
```
// TODO: update steps to create and login with Azure SPN

<!-- 1. Open a terminal and run:

```sh
az login --use-device-code
```

2. You’ll be given a code and a URL. Open the URL in your browser and enter the code to sign in.

3. After successful login, confirm the account and tenant:

```sh
az account show
``` -->

### Install Terraform
// TODO: add steps how to install TF on Windows and WSL/Linux

### Install Azure Providers and Extensions

```sh
az provider register --namespace Microsoft.Kubernetes
az provider register --namespace Microsoft.KubernetesConfiguration
az provider register --namespace Microsoft.ExtendedLocation

az extension add --name connectedk8s
az extension add --name k8s-configuration
```

You can monitor the registration process with the following commands:

```sh
az provider show -n Microsoft.Kubernetes -o table
az provider show -n Microsoft.KubernetesConfiguration -o table
az provider show -n Microsoft.ExtendedLocation -o table
```



## Deploying Infrastructure with Terraform

1. Navigate to the infra/ folder:

```sh
cd infra
```

2. Initialize Terraform:

```sh
terraform init
```

3. Preview what will be deployed:

```sh
terraform plan
```

4. Apply the infrastructure changes:

```sh
terraform apply
```

> Tip: Use -auto-approve to skip the confirmation prompt if you're scripting this.

## Docker Image build and upload

# grab your KV and ACR

```sh
KV=$(terraform output -raw kv_name)
ACR_SERVER=$(terraform output -raw acr_login_server)
```

# pull credentials from KV

```sh
ACR_USER=$(az keyvault secret show --vault-name $KV --name acr-admin-username --query value -o tsv)
ACR_PASS=$(az keyvault secret show --vault-name $KV --name acr-admin-password --query value -o tsv)
```


Option #1. Download and build image locally and push it to ACR

# if you’re currently in infra/

```sh
cd ..
```

# authenticate with Azure Container Registry, build image and push it to ACR

```sh
echo "$ACR_PASS" | docker login $ACR_SERVER --username "$ACR_USER" --password-stdin
docker build -t $ACR_SERVER/ollama-api:latest ./ollama-api
docker push $ACR_SERVER/ollama-api:latest
```


Option #2. Importing the upstream image straight into ACR

```sh
az acr import \
  --name $ACR_SERVER \
  --source docker.io/ollama/ollama-api:latest \
  --image ollama-api:latest
```

After that you can docker pull jshaipacr7401.azurecr.io/ollama-api:latest (from anywhere with network access) without rebuilding locally.


### Building Ollama deployment

ACR_ID=$(terraform output -raw acr_id)
PRINCIPAL_ID=$(terraform output -raw k3s_cp_principal_id)

# grant pull rights:
az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role     AcrPull \
  --scope    $ACR_ID
