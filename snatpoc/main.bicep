targetScope = 'subscription'

// Deployment parameters
param deployName string = 'api-poc-we'
param deployTime string = utcNow('yyyyMMddHHmmss')
param location string = 'westeurope'

// Virtual network parameters
param vnetSize array = [
  '10.0.0.0/16'
] 
param snetSize1 string = '10.0.0.0/24'
param snetSize2 string = '10.0.1.0/24'
param snetSize3 string = '10.0.2.0/24'
param basSnet string = '10.0.3.0/24'
param afwSnet string = '10.0.4.0/24'
param afwmgmtSnet string = '10.0.5.0/24'

// AFW parameters


// Tags
param tags object = {
  Owner: 'daniel@madit.se'
}

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-${deployName}'
  location: location
  tags: tags
}

module vnet 'br/public:avm/res/network/virtual-network:0.4.1' = {
  scope: rg
  name: 'deploy-vnet-${deployTime}'
  params: {
    name: 'vnet-${deployName}-001'
    addressPrefixes: vnetSize
    subnets: [
      {
        name: 'snet-${deployName}-001'
        addressPrefix: snetSize1
        networkSecurityGroupResourceId: nsg1.outputs.resourceId
        routeTableResourceId: rt1.outputs.resourceId
        
      }
      {
        name: 'snet-${deployName}-002'
        addressPrefix: snetSize2
        networkSecurityGroupResourceId: nsg1.outputs.resourceId
        routeTableResourceId: rt1.outputs.resourceId
      }
      {
        name: 'AzureFirewallSubnet'
        addressPrefix: afwSnet
      }
      {
        name: 'AzureBastionSubnet'
        addressPrefix: basSnet
      }
    ]
  }
}

module bas 'br/public:avm/res/network/bastion-host:0.4.0' = {
  scope: rg
  name: 'deploy-bas-${deployTime}'
  params: {
    name: 'bas-${deployName}-001'
    virtualNetworkResourceId: vnet.outputs.resourceId 
  }
}

module nsg1 'br/public:avm/res/network/network-security-group:0.5.0' = {
  scope: rg
  name: 'deploy-nsg1-${deployTime}'
  params: {
    name: 'nsg-${deployName}-001'
    securityRules: [
      {
        name: 'rule1'
        properties: {
          access: 'Deny'
          direction: 'Inbound'
          priority: 1000
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

module rt1 'br/public:avm/res/network/route-table:0.4.0' = {
  scope: rg
  name: 'deploy-rt-${deployTime}'
  params: {
    name: 'rt-${deployName}-001'
    routes: [
      {
        name: 'all-traffic-to-va'
        properties: {
          nextHopType: 'VirtualAppliance'
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress:
        }
      }
    ]
  }
}

module afw 'br/public:avm/res/network/azure-firewall:0.5.1' = {
  scope: rg
  name: 'deploy-afw-${deployTime}'
  params: {
    name: 'afw-${deployName}-001'
    azureSkuTier: 'Basic'
    virtualNetworkResourceId: vnet.outputs.resourceId
    threatIntelMode: 'Alert'
  }
}

module nat 'br/public:avm/res/network/nat-gateway:1.2.1' = {
  scope: rg
  name: 'deploy-nat-${deployTime}'
  params: {
    name: 'natgw-${deployName}-001'
    zone: 1
    publicIpResourceIds: [
      {
        
      }
    ]
  }
}

module pip1 'br/public:avm/res/network/public-ip-address:0.6.0' = {
  scope: rg
  name: 'deploy-pip1-${deployTime}'
  params: {
    name: 'pip-${deployName}-001'
    ddosSettings: {
      protectionMode: 'Enabled'
    }
    skuName: 'Standard'
    skuTier: 'Regional'
    zones: [
      1
    ]
  }
}

module pip2 'br/public:avm/res/network/public-ip-address:0.6.0' = {
  scope: rg
  name: 'deploy-pip2-${deployTime}'
  params: {
    name: 'pip-${deployName}-002'
    ddosSettings: {
      protectionMode: 'Enabled'
    }
    skuName: 'Standard'
    skuTier: 'Regional'
    zones: [
      1
    ]
  }
}
