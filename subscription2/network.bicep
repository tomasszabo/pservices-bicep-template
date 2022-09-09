
param location string

param publicIP1Name string = 'pservices2-public-ip-${uniqueString(resourceGroup().id)}-01'
param natGateway1Name string = 'pservices2-nat-gateway-${uniqueString(resourceGroup().id)}-01'
param vnet2Name string = 'pservices2-vnet-02'


resource publicIP1 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: publicIP1Name
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource natGateway1 'Microsoft.Network/natGateways@2020-11-01' = {
  name: natGateway1Name
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: publicIP1.id
      }
    ]
  }
}

resource vnet2 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: vnet2Name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.64.0.0/10'
      ]
    }
    subnets: [
      {
        name: 'gw-outbound'
        properties: {
          addressPrefix: '10.64.1.0/29'
          natGateway: {
            id: natGateway1.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Web'
              locations: [
                '*'
              ]
            }
          ]
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'default'
        properties: {
          addressPrefix: '10.64.0.0/24'
          natGateway: {
            id: natGateway1.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Web'
              locations: [
                '*'
              ]
            }
          ]
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

output subnetDefaultId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnet2.name, 'default')
output vnet2Id string = vnet2.id
