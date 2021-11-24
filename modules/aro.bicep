param name string
param masterSubnetId string
param workerSubnetId string
param objectId string
param clientSecret string
param podCidr string
param serviceCidr string
param clusterRg string

resource aro 'Microsoft.RedHatOpenShift/openShiftClusters@2021-09-01-preview' = {
  name: name
  location: resourceGroup().location
  tags: {
    tagName1: 'tagValue1'
    tagName2: 'tagValue2'
  }
  properties: {
    apiserverProfile: {
      visibility: 'Public'
    }
    clusterProfile: {
      domain: 'dcasati.net'
      //pullSecret: 'string'
      resourceGroupId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${clusterRg}' 
      //version: 'string'
    }
    ingressProfiles: [
      {
        name: 'default'
        visibility: 'Public'
      }
    ]
    masterProfile: {
      subnetId: masterSubnetId
      vmSize: 'Standard_D8s_v3'
      encryptionAtHost: 'Enabled'
    }
    networkProfile: {
      podCidr: podCidr
      serviceCidr: serviceCidr
      softwareDefinedNetwork: 'OpenShiftSDN'
    }
    servicePrincipalProfile: {
      clientId: objectId
      clientSecret: clientSecret
    }
    workerProfiles: [
      {
        count: 3
        diskSizeGB: 128
        name: 'worker'
        subnetId: workerSubnetId
        vmSize: 'Standard_D8s_v3'
        encryptionAtHost: 'Enabled'
      }
    ]
  }
}

output name string = aro.name
