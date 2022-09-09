

targetScope = 'subscription' 

param resourceGroupName string
param location string

resource resGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: resourceGroupName
  location: location
}

module network 'network.bicep' = {
  name: 'networkModule'
  params: {
    location: location
  }
  scope: resGroup
}

module compute 'compute.bicep' = {
  name: 'computeModule'
  params: {
    location: location
    appSubnetId: network.outputs.subnetDefaultId
  }
  scope: resGroup
}

output vnet2Id string = network.outputs.vnet2Id
output appServices array = compute.outputs.appServices
