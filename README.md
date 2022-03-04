# aro-bicep-examples

TL;DR -

to install:

```bash
./run.sh -x install
```

to delete:

```bash
./run -x delete
```
## Detailed instructions

## Before you begin

You might need to run `az login` before running the commands on this quickstart. Check if you have connectivity to Azure before proceeding by executing `az account list` and verifying that you have access to an active Azure subscription. 

> This template will use the pull secret text that was obtained from the Red Hat OpenShift Cluster Manager website. Before proceeding
> make sure you have that secret saved locally as `pull-secret.txt`.

```bash
PULL_SECRET=$(cat pull-secret.txt)    # the pull secret text 
```

## Define the following parameters as environment variables with azure-cli

```bash
RESOURCEGROUP=aro-rg   # the new resource group for the cluster
LOCATION=eastus        # the location of the new ARO cluster
DOMAIN=mydomain        # the domain prefix for the cluster
CLUSTER=aro-cluster    # the name of the cluster
```

## Register the required resource providers

Register the following resource providers in your subscription: `Microsoft.RedHatOpenShift`, `Microsoft.Compute`, `Microsoft.Storage` and `Microsoft.Authorization`.

```bash
az provider register --namespace 'Microsoft.RedHatOpenShift' --wait
az provider register --namespace 'Microsoft.Compute' --wait
az provider register --namespace 'Microsoft.Storage' --wait
az provider register --namespace 'Microsoft.Authorization' --wait
```

## Create the new resource group

```bash
az group create --name $RESOURCEGROUP --location $LOCATION
```

## Create a service principal for the new Azure AD application

```bash
az ad sp create-for-rbac --name "sp-$RG_NAME-${RANDOM}" --role Contributor > app-service-principal.json
SP_CLIENT_ID=$(jq -r '.appId' app-service-principal.json)
SP_CLIENT_SECRET=$(jq -r '.password' app-service-principal.json)
SP_OBJECT_ID=$(az ad sp show --id $SP_CLIENT_ID | jq -r '.objectId')
```

## Assign the Contributor role to the new service principal with

```bash
az role assignment create \
    --role 'User Access Administrator' \
    --assignee-object-id $SP_OBJECT_ID \
    --resource-group $RESOURCEGROUP \
    --assignee-principal-type 'ServicePrincipal'

az role assignment create \
    --role 'Contributor' \
    --assignee-object-id $SP_OBJECT_ID \
    --resource-group $RESOURCEGROUP \
    --assignee-principal-type 'ServicePrincipal'
```

## Get the service principal object ID for the OpenShift resource provider

```bash
ARO_RP_SP_OBJECT_ID=$(az ad sp list --display-name "Azure Red Hat OpenShift RP" --query [0].objectId -o tsv)
```

## Deploy the cluster

```bash
az deployment group create \
    --name aroDeployment \
    --resource-group $RESOURCEGROUP \
    --template-file azuredeploy.json \
    --parameters location=$LOCATION \
    --parameters domain=$DOMAIN \
    --parameters pullSecret=$PULL_SECRET \
    --parameters clusterName=$ARO_CLUSTER_NAME \
    --parameters aadClientId=$SP_CLIENT_ID \
    --parameters aadObjectId=$SP_OBJECT_ID \
    --parameters aadClientSecret=$SP_CLIENT_SECRET \
    --parameters rpObjectId=$ARO_RP_SP_OBJECT_ID
```

---

## Connecting to your cluster

To connect your new cluster please review the described steps on [Connect to an Azure Red Hat OpenShift 4 cluster](azure/openshift/tutorial-connect-cluster).

## Clean up resources

Once you are done, run the following command to delete your resource group along with all the resources you created in this tutorial.

```azurecli
az aro delete --resource-group $RESOURCEGROUP --name $ARO_CLUSTER_NAME
