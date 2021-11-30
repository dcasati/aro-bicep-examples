/* General Parameters */
param prefix string
var name = '${prefix}-gbb'

/* 
 * OpenShift Parameters 
 */
param client_secret string
param object_id string
param domain string

/* Master Nodes */
param masterVmSize string = 'Standard_D8s_v3'

/* Worker Nodes */
param workerVmSize string = 'Standard_D4s_v3'
param workerDiskSizeGb int = 128
param workerCount int = 3

/*
 * Network Settings
 */
param vnetPrefix string = '10.100.0.0/15'
param podCidr string = '10.0.128.0/14'
param serviceCidr string = '172.30.0.0/16'

param masterSubnet object = { 
  name: 'master-subnet'
  properties: {
    addressPrefix: '10.100.76.0/24'
    privateLinkServiceNetworkPolicies: 'Disabled'
    serviceEndpoints: [
      {
        service: 'Microsoft.ContainerRegistry'
      }
    ]
  }
}

param workerSubnet object = {
  name: 'worker-subnet'
  properties: {
    addressPrefix: '10.100.70.0/23'
    serviceEndpoints: [
      {
        service: 'Microsoft.ContainerRegistry'
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2019-09-01' = {
   name: 'aro-vnet'
   location: resourceGroup().location
   properties: {
      addressSpace: {
       addressPrefixes: [
         vnetPrefix
       ]
     }
     subnets: [
      masterSubnet
      workerSubnet
     ]
   }
 }

 /* User supplied Service Principal */
var NetworkContributorRole = '4d97b98b-1d4f-4787-a291-c67834d212e7'
var ContributorRole = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
resource aroNetworkContributor 'Microsoft.Authorization/roleAssignments@2018-09-01-preview' = {
  name: guid(vnet.id, 'NetworkContributor')
  scope: vnet
  dependsOn: [
    vnet
  ]
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', NetworkContributorRole)
    principalId: object_id
    principalType: 'ServicePrincipal'

  }
}

/* Contributor to the vNet Resource Group*/
resource aroContributor 'Microsoft.Authorization/roleAssignments@2018-09-01-preview' = {
  name: guid(vnet.id, 'Contributor')
  scope: vnet
  dependsOn: [
    vnet
  ]
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', ContributorRole)
    principalId: object_id
    principalType: 'ServicePrincipal'

  }
}


/* the ARO RP Service Principal*/

/* Network Contributor to the vNet Resource Group*/
var aroRpServicePrincipal = '50c17c64-bc11-4fdd-a339-0ecd396bf911'
resource aroSPNetworkContributor 'Microsoft.Authorization/roleAssignments@2018-09-01-preview' = {
  name: guid(vnet.id, 'NetworkContributor', 'AroSpVnetRg')
  scope: vnet
  dependsOn: [
    vnet
  ]
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', NetworkContributorRole)
    principalId: aroRpServicePrincipal
    principalType: 'ServicePrincipal'
  }
}

/* Contributor to the vNet Resource Group*/
resource aroSPContributor 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(vnet.id, 'Contributor', 'AroSpVnetRg')
  scope: vnet
  dependsOn: [
    vnet
  ]
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', ContributorRole)
    principalId: aroRpServicePrincipal
    principalType: 'ServicePrincipal'
  }
}

/*
 * Azure Red Hat OpenShift
 */
module aro 'modules/aro.bicep' = {
  name: 'aro-deployment'
  dependsOn: [
    vnet
    aroContributor
    aroContributor
  ]
  params: {
    name: format('{0}-aro',name)
    objectId: object_id
    clientSecret: client_secret
    domain: domain

    /* Networking */
    podCidr: podCidr
    serviceCidr: serviceCidr
    
    /* Master */
    masterVmSize: masterVmSize
    masterSubnetId: '${vnet.id}/subnets/${masterSubnet.name}'

    /* Worker */
    workerCount: workerCount
    workerDiskSizeGb: workerDiskSizeGb
    workerVmSize: workerVmSize
    workerSubnetId: '${vnet.id}/subnets/${workerSubnet.name}'
  }
}

/*
 * Outputs
 */
output aroClusterName string = aro.outputs.name

