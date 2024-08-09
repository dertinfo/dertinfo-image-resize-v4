/*
Outline: This bicep file is used to deploy the base infrastructure to allow the function app to be deployed.
Author: David Hall
Created: 2024-08-08
Notes: 
- This deployment will create a storage account, app service plan and function app.
- Run this so that the code can be deployed
- Run configure.bicep once the code has been deployed. This will configure the event grid subscriptions.
Azure CLI Commands:
- az group create --name di-rg-imageresizev4-[env] --location uksouth
- az deployment group create --resource-group di-rg-imageresizev4-[env] --template-file deploy-function-app.bicep --parameters @deploy-function-app-params-[env].json
*/

// #####################################################
// Parameters
// #####################################################

@description('The name of the function app that you wish to create.')
param functionAppName string = 'di-func-imageresizev4-dev'

@description('The name of the App Service plan.')
param appServicePlanName string = 'di-asp-imageresizev4-dev'

@description('The images storage account name')
param imagesStorageAccountName string

@description('The images storage account resource group name')
param imagesStorageAccountResourceGroup string

@description('The app insights instance name.')
param applicationInsightsName string

@description('The app insights instance resource group name.')
param applicationInsightsResourceGroup string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Deployment type for the resources. The environment that the resources are being deployed to.')
@allowed([
  'dev'
  'stg'
  'prod'
])
param envTag string = 'dev'

@description('Storage Account type')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
])
param storageAccountType string = 'Standard_LRS'

// #####################################################
// Variables
// #####################################################

// Determine the name of the storage account used by the function app.
var storageAccountName = '${uniqueString(resourceGroup().id)}azfunctions'
var functionAppStorageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
var imagesStorageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${imagesStorageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${imagesStorageAccount.listKeys().keys[0].value}'

// #####################################################
// References
// #####################################################

resource imagesStorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: imagesStorageAccountName
  scope: resourceGroup(imagesStorageAccountResourceGroup)
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
  scope: resourceGroup(applicationInsightsResourceGroup)
}

// #####################################################
// Resources
// #####################################################

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
  properties: {
    supportsHttpsTrafficOnly: true
    defaultToOAuthAuthentication: true
  }
  tags: {
    environment: envTag
  }
}

resource hostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
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
          name: 'StorageConnection:Images'
          value: imagesStorageConnectionString
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
      ]
    }
  }
  tags: {
    environment: envTag
  }
}

// #####################################################
// Modules
// #####################################################


