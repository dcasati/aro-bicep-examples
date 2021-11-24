var name = '${prefix}-gbb'

param clusterRg string
param prefix string
param client_secret string
param object_id string


/*
 * Network Settings
 */
param vnetPrefix string = '10.0.0.0/22'
param podCidr string = '10.0.64.0/18'
param serviceCidr string = '10.0.128.0/18'

param masterSubnet object = { 
  name: 'master-subnet'
  properties: {
    addressPrefix: '10.0.0.0/23'
    privateEndpointNetworkPolicies: 'Enabled'
  }
}

param workerSubnet object = {
  name: 'worker-subnet'
  properties: {
    addressPrefix: '10.0.2.0/23'
  }
}

/* 
 * Top Level Resources
 */

 resource vnet 'Microsoft.Network/virtualNetworks@2020-08-01' = {
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

var NetworkContributor = '4d97b98b-1d4f-4787-a291-c67834d212e7'
resource aroNetworkContributor 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(vnet.id, 'NetworkContributor')
  scope: vnet
  dependsOn: [
    vnet
  ]
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', NetworkContributor)
    principalId: object_id
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
    aroNetworkContributor

  ]
  params: {
    name: format('{0}-aro',name)
    clusterRg: clusterRg
    masterSubnetId: '${vnet.id}/subnets/${masterSubnet.name}'
    workerSubnetId: '${vnet.id}/subnets/${workerSubnet.name}'
    objectId: object_id
    clientSecret: client_secret
    podCidr: podCidr
    serviceCidr: serviceCidr
  }
}

/*
 * Outputs
 */
output aroClusterName string = aro.outputs.name
