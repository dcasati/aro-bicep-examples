#!/usr/bin/env bash
# shfmt -i 2 -ci -w
set -Ee -o pipefail

source deploy.rc

__usage="
    -f  filename for the payload
    -x  action to be executed. 
Possible verbs are:
    install        deploy Bicep resources.
    delete         delete Bicep resources.
"
usage() {
  echo "usage: ${0##*/} [options]"
  echo "${__usage/[[:space:]]/}"
  exit 1
}

# a wrapper around the command to be executed
cmd() {
  echo "\$ ${@}"
  "$@"
}

rg_create() {
  az group create --name $RG_NAME --location $RG_LOCATION
  #az group create --name $RG_CLUSTER_NAME --location $RG_LOCATION
}

sp_create() {
  az ad sp create-for-rbac --name "sp-$RG_NAME-${RANDOM}" --role Contributor >app-service-principal.json
}

sp_load() {
  SP_CLIENT_ID=$(jq -r '.appId' app-service-principal.json)
  SP_CLIENT_SECRET=$(jq -r '.password' app-service-principal.json)
  SP_ID=$(jq -r '.name' app-service-principal.json)

  SP_OBJECT_ID=$(az ad sp show --id $SP_CLIENT_ID | jq -r '.objectId')
}

sp_rbac() {
  # Assign the Contributor role to the new service principal
  az role assignment create --role 'User Access Administrator' --assignee $SP_OBJECT_ID --resource-group $RG_NAME
  az role assignment create --role 'Contributor' --assignee $SP_OBJECT_ID --resource-group $RG_NAME
}

aro_deploy() {
  echo "Deploying ARO resources ..."
  az deployment group create \
    --resource-group $RG_NAME \
    --template-file $BICEP_FILE \
    --parameters aadClientSecret=$SP_CLIENT_SECRET \
    --parameters aadObjectId=$SP_OBJECT_ID \
    --parameters aadClientId=$SP_CLIENT_ID \
    --parameters domain=$DOMAIN \
    --parameters pullSecret=$(cat pull-secret.txt) \
    --parameters clusterName=$ARO_CLUSTER_NAME \
    --parameters rpObjectId=$(az ad sp list --display-name "Azure Red Hat OpenShift RP" --query [0].objectId -o tsv)
}

do_delete() {
  echo "removing resources"
  cmd az group delete --name $RG_NAME --no-wait --yes

  # retrieves the information about the SP so we can remove it
  sp_load
  az ad sp delete --id $SP_ID
}

do_install() {
  rg_create
  sp_create
  sp_load
  sp_rbac
  aro_deploy
}

exec_case() {
  local _opt=$1

  case ${_opt} in
    install) do_install ;;
    delete) do_delete ;;
    *) usage ;;
  esac
  unset _opt
}

while getopts "f:o:x:" opt; do
  case $opt in
    f) _FILENAME="${OPTARG}" ;;
    o) _OUTPUT_TYPE="${OPTARG}" ;;
    x)
      exec_flag=true
      EXEC_OPT="${OPTARG}"
      ;;
    *) usage ;;
  esac
done
shift $(($OPTIND - 1))

if [ $OPTIND = 1 ]; then
  usage
  exit 0
fi

if [[ "${exec_flag}" == "true" ]]; then
  exec_case ${EXEC_OPT}
fi

exit 0