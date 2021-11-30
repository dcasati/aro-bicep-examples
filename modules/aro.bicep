param name string
param objectId string
param clientSecret string
param podCidr string
param serviceCidr string

/* Master Nodes */
param masterVmSize string  
param masterSubnetId string

/* Worker Nodes */
param workerVmSize string  
param workerDiskSizeGb int  
param workerCount int  
param workerSubnetId string
param domain string


resource aro 'Microsoft.RedHatOpenShift/openShiftClusters@2020-04-30' = {
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
      domain: domain
      resourceGroupId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/aro-${domain}'
      //version: 'string'
      //pullSecret:
    }
    ingressProfiles: [
      {
        name: 'default'
        visibility: 'Public'
      }
    ]
    masterProfile: {
      subnetId: masterSubnetId
      vmSize: masterVmSize
      //encryptionAtHost: 'Enabled'
    }
    networkProfile: {
      podCidr: podCidr
      serviceCidr: serviceCidr
     // softwareDefinedNetwork: 'OpenShiftSDN'
    }
    servicePrincipalProfile: {
      clientId: objectId
      clientSecret: clientSecret
    }
    workerProfiles: [
      {
        count: workerCount
        diskSizeGB: workerDiskSizeGb
        name: 'worker'
        subnetId: workerSubnetId
        vmSize: workerVmSize
        //encryptionAtHost: 'Enabled'
      }
    ]
  }
}

output name string = aro.name

