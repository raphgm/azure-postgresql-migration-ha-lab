@description('Name of the PostgreSQL Flexible Server')
param serverName string = 'pg-prod-primary'

@description('Azure region')
param location string = resourceGroup().location

@description('Administrator login name')
param adminLogin string = 'dbadmin'

@secure()
@description('Administrator password')
param adminPassword string

@description('Zone the primary lands in; the HA standby is placed in a different zone automatically for zone-redundant HA')
param availabilityZone string = '1'

@description('Zone-redundant HA standby zone (must differ from availabilityZone)')
param standbyZone string = '2'

resource server 'Microsoft.DBforPostgreSQL/flexibleServers@2025-08-01' = {
  name: serverName
  location: location
  sku: {
    name: 'Standard_D2ds_v5'
    tier: 'GeneralPurpose'
  }
  properties: {
    version: '16'
    administratorLogin: adminLogin
    administratorLoginPassword: adminPassword
    availabilityZone: availabilityZone
    highAvailability: {
      mode: 'ZoneRedundant'
      standbyAvailabilityZone: standbyZone
    }
    storage: {
      storageSizeGB: 128
    }
    backup: {
      backupRetentionDays: 35
      geoRedundantBackup: 'Enabled'
    }
    network: {
      publicNetworkAccess: 'Disabled'
    }
  }
}

output serverFqdn string = server.properties.fullyQualifiedDomainName
