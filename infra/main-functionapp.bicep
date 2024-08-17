// #####################################################
// Parameters
// #####################################################



@description('The name of the function app.')
param functionAppName string

@description('Location for resources.')
param location string = resourceGroup().location

@description('The images storage account name.')
param imagesStorageAccountName string

@description('The images storage account resource group name.')
param imagesStorageAccountResourceGroupName string

@description('The application insights instumentation key.')
param appInsightsInstumetationKey string

@description('Storage Account type')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
])
param functionAppStorageAccountType string = 'Standard_LRS'

@description('Environment tag for resources.')
@allowed([
  'dev'
  'stg'
  'prod'
])
param environmentTag string = 'dev'


// #####################################################
// Variables
// #####################################################

var functionStoragePrefix = substring(replace(functionAppName,'-',''),0,6)
var functionAppStorageName = '${functionStoragePrefix}funcstorage'
var appServicePlanName = '${functionAppName}-serviceplan'

var functionAppStorageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${functionAppStorageName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${functionAppStorageAccount.listKeys().keys[0].value}'
var imagesStorageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${imagesStorageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${imagesStorageAccount.listKeys().keys[0].value}'

// #####################################################
// References
// #####################################################

resource imagesStorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: imagesStorageAccountName
  scope: resourceGroup(imagesStorageAccountResourceGroupName)
}

// #####################################################
// Resources
// #####################################################

resource hostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: appServicePlanName
  location: location
  tags: {
    environment: environmentTag
  }
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

resource functionAppStorageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: functionAppStorageName
  location: location
  tags: {
    environment: environmentTag
  }
  sku: {
    name: functionAppStorageAccountType
  }
  kind: 'Storage'
  properties: {
    supportsHttpsTrafficOnly: true
    defaultToOAuthAuthentication: true
  }
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  tags: {
    environment: environmentTag
  }
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: functionAppStorageConnectionString
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE' // This ensures that the function app does note replace the code when deploying. 
          value: '1'
        }
        {
          name: 'StorageConnection:Images'
          value: imagesStorageConnectionString
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstumetationKey
        }
        {
          name: 'AzureWebJobs.ResizeDefaultImagesPolling.Disabled'
          value: 'true'
        }
        {
          name: 'AzureWebJobs.ResizeDefaultImagesPolling.Disabled'
          value: 'true'
        }
        {
          name: 'AzureWebJobs.ResizeDefaultImagesPolling.Disabled'
          value: 'true'
        }
        {
          name: 'AzureWebJobs.ResizeDefaultImagesPolling.Disabled'
          value: 'true'
        }
      ]
    }
  }
}
// notes - AzureWebJobs.Resize[Type]ImagesPolling.Disabled is a custom setting that is used to disable the targetted function.
//       - We use this as when developing locally we want to use Azurite which doesn't support event grid triggers.
//       - This is a workaround to disable polling functions when running in Azure.

// #####################################################
// Modules
// #####################################################
// #####################################################
// Outputs
// #####################################################

output functionAppName string = functionApp.name
