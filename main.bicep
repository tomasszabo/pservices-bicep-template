
@description('Subscription 1 ID used for deployment of HUB resources')
param subscription1Id string 
@description('Subscription 2 ID used for deployment of spoke resources')
param subscription2Id string

@description('Region where to deploy all resources')
param location string

@description('Administrator username used for VM that serves as jumphost')
param adminUsername string

@description('Administrator password used for VM that serves as jumphost')
@secure() 
param adminPassword string

targetScope = 'subscription'  

module subscription2 './subscription2/subscription2.bicep' = {
  name: 'subscription2Module'
  params: {
    resourceGroupName: 'pservices2-rg'
    location: location
  }
  scope: subscription(subscription2Id)
}

module subscription1 './subscription1/subscription1.bicep' = {
  name: 'subscription1Module'
  params: {
    resourceGroupName: 'pservices1-rg'
    location: location
    otherVnetId: subscription2.outputs.vnet2Id
    appServices: subscription2.outputs.appServices
    adminPassword: adminPassword
    adminUsername: adminUsername
  }
  scope: subscription(subscription1Id)
}
