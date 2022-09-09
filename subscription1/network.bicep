
param location string
param otherVnetId string

// param publicIP1Name string = 'pservices-public-ip-${uniqueString(resourceGroup().id)}-01'
param nsg1Name string = 'pservices-nsg-${uniqueString(resourceGroup().id)}-01'
param vnet1Name string = 'pservices-vnet-01'

// not used anymore, may be removed
// resource publicIP1 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
//   name: publicIP1Name
//   location: location
//   sku: {
//     name: 'Standard'
//     tier: 'Regional'
//   }
//   properties: {
//     publicIPAddressVersion: 'IPv4'
//     publicIPAllocationMethod: 'Static'
//     idleTimeoutInMinutes: 4
//   }
// }

resource nsg1 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: nsg1Name
  location: location
  properties: {
    securityRules: [
      {
        name: 'Port_GW'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Port_80'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'default-allow-3389'
        properties: {
          priority: 130
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vnet1 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: vnet1Name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/10'
      ]
    }
    subnets: [
      {
        name: 'gw-inbound'
        properties: {
          addressPrefix: '10.0.2.0/24'
          serviceEndpoints: [
            {
              service: 'Microsoft.Web'
              locations: [
                '*'
              ]
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
          serviceEndpoints: [
            {
              service: 'Microsoft.Web'
              locations: [
                '*'
              ]
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

resource vnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-01-01' = {
  parent: vnet1
  name: 'vnet-peering-01'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: otherVnetId
    }
  }
}

output defautlSubnetId string = vnet1.properties.subnets[1].id
