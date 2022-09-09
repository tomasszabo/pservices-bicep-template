param location string

param appPlanName string = 'pservices2-asp-${uniqueString(resourceGroup().id)}-01'
param appPlanKind string = 'linux'
param appNamePrefix string = 'pservices2-web-app'
param appStack string = 'NODE|16-lts'
param appVnetName string = '${uniqueString(resourceGroup().id)}-default'

param appCodeRepoUrl string = 'https://github.com/tomasszabo/simple-responder-app.git'
param appCodeBranch string = 'master'

param appSubnetId string

var apps = [ 1, 2 ]

resource appPlan 'Microsoft.Web/serverFarms@2022-03-01' = {
  name: appPlanName
  location: location
  sku: {
    name: 'S1'
  }
  kind: appPlanKind
  properties: {
    reserved: true
  }
}

resource appService 'Microsoft.Web/sites@2022-03-01' = [for app in apps: {
  name: '${appNamePrefix}-${uniqueString(resourceGroup().id)}-0${app}'
  location: location
  properties: {
    serverFarmId: appPlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: appStack
      appSettings: [
        {
          name: 'APP_IDENTIFIER'
          value: 'App0${app}'
        }
      ]
    }
    virtualNetworkSubnetId: appSubnetId
  }
}]

resource appServiceConfig 'Microsoft.Web/sites/config@2022-03-01' = [for (app, index) in apps: {
  parent: appService[index]
  name: 'web'
  properties: {
    vnetName: appVnetName
    vnetRouteAllEnabled: true
    ipSecurityRestrictions: [
      {
        vnetSubnetResourceId: appSubnetId
        action: 'Allow'
        tag: 'Default'
        priority: 100
        name: 'Allow from Spoke'
      }
      {
        ipAddress: 'AzureFrontDoor.Backend'
        action: 'Allow'
        tag: 'ServiceTag'
        priority: 110
        name: 'Allow from FrontDoor'
      }
      {
        ipAddress: 'Any'
        action: 'Deny'
        priority: 2147483647
        name: 'Deny all'
        description: 'Deny all access'
      }
    ]
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
  }
}]

resource appServiceVnet 'Microsoft.Web/sites/virtualNetworkConnections@2022-03-01' = [for (app, index) in apps: {
  parent: appService[index]
  name: appVnetName
  properties: {
    vnetResourceId: appSubnetId
    isSwift: true
  }
}]

resource appServiceSrcControls 'Microsoft.Web/sites/sourcecontrols@2022-03-01' = [for (app, index) in apps: {
  parent: appService[index]
  name: 'web'
  properties: {
    repoUrl: appCodeRepoUrl
    branch: appCodeBranch
    isManualIntegration: true
  }
}]

output appServices array = [for (app, index) in apps: appService[index].properties.defaultHostName]
