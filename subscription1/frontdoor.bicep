param location string
param appServices array

param wafPolicyName string = 'pserviceswaffd01'
param frontDoorPolicyName string = 'waf-policy-01'
param frontDoorName string = 'pservices-front-door-01'
param frontDoorEndpointName string = frontDoorName

resource wafPolicy 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2020-11-01' = {
  name: wafPolicyName
  location: location
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
  properties: {
    policySettings: {
      enabledState: 'Enabled'
      mode: 'Detection'
    }
  }
}

resource frontDoorProfile 'Microsoft.Cdn/profiles@2021-06-01' = {
  name: frontDoorName
  location: 'global'
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
}

resource frontDoorEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2021-06-01' = {
  name: frontDoorEndpointName
  parent: frontDoorProfile
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}

resource frontDoorOriginGroup 'Microsoft.Cdn/profiles/originGroups@2021-06-01' = [for (appService, index) in appServices: {
  name: 'origin-group-${index + 1}'
  parent: frontDoorProfile
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    healthProbeSettings: {
      probePath: '/time'
      probeRequestType: 'GET'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 5
    }
  }
}]

resource frontDoorOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2021-06-01' = [for (appService, index) in appServices: {
  name: 'origin-${index + 1}'
  parent: frontDoorOriginGroup[index]
  properties: {
    hostName: appService
    httpPort: 80
    httpsPort: 443
    originHostHeader: appService
    priority: 1
    weight: 1000
  }
}]

var patterns = [for (appService, index) in appServices: '/app0${index + 1}/*']

resource frontDoorRoute 'Microsoft.Cdn/profiles/afdEndpoints/routes@2021-06-01' = [for (appService, index) in appServices: {
  name: 'route-${index + 1}'
  parent: frontDoorEndpoint
  dependsOn: [
    frontDoorOrigin[index]
  ]
  properties: {
    originGroup: {
      id: frontDoorOriginGroup[index].id
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      patterns[index]
    ]
    originPath: '/'
    forwardingProtocol: 'HttpsOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
  }
}]

resource frontDoorPolicy 'Microsoft.Cdn/profiles/securityPolicies@2020-09-01' = {
  name: frontDoorPolicyName
  parent: frontDoorProfile
  properties: {
    parameters: {
      type: 'WebApplicationFirewall'
      wafPolicy: {
        id: wafPolicy.id
      }
      associations: [
        {
          domains: [
            {
              id: frontDoorEndpoint.id
            }
          ]
          patternsToMatch: [
            '/*'
          ]
        }
      ]
    }
  }
}
