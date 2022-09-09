
targetScope = 'subscription'    // Resource group must be deployed under 'subscription' scope

param resourceGroupName string
param location string
param otherVnetId string
param appServices array
param adminUsername string

@secure() 
param adminPassword string

resource resGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: resourceGroupName
  location: location
}

module network 'network.bicep' = {
  name: 'networkModule'
  params: {
    location: location
    otherVnetId: otherVnetId
  }
  scope: resGroup
}

module vm 'vm.bicep' = {
  name: 'vmModule'
  params: {
    location: location
    adminPassword: adminPassword
    adminUsername: adminUsername
    defaultSubnetId: network.outputs.defautlSubnetId
  }
  scope: resGroup
}

module frontDoor 'frontdoor.bicep' = {
  name: 'frontDoorModule'
  params: {
    location: location
    appServices: appServices
  }
  scope: resGroup
}
