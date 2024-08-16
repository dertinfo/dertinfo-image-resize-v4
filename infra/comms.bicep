/*
Outline: This bicep file is used to setup system topic for event grid and the event grid subscriptions to report on new images uploaded.
Author: David Hall
Created: 2024-08-09
Prerequisites:
- deploy.bicep must be run before this is run. This ensures function app is present. (As we need the key for the blobs_extension)
- The application code must be deployed ahead of this configuration so that the web hook endpoints can be validated.
Notes: 
- This deployment will create a system topic and 3 event grid subscriptions.
- It will need to validate the web hook endpoints as part of the deployment
- The application code must be deployed ahead of this configuration
Azure CLI Commands:
- az group create --name di-rg-imageresizev4-[env] --location uksouth
- az deployment group create --resource-group di-rg-imageresizev4-[env] --template-file configure.bicep --parameters @configure-params-[env].json
*/

// #####################################################
// Parameters
// #####################################################

@description('The name of the function app that you wish to create.')
param functionAppName string

@description('The images storage account name.')
param imagesStorageAccountName string

@description('The images storage account resource group name.')
param imagesStorageAccountResourceGroupName string

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

var systemKeys = functionAppHost.listKeys().systemKeys // Get all the system keys for the function app
var blobExtensionKey = systemKeys.blobs_extension // We want the key with the name blobs_extension
var groupFunctionName = 'ResizeGroupImages'
var eventFunctionName = 'ResizeEventImages'
var sheetFunctionName = 'ResizeSheetImages'
var defaultFunctionName = 'ResizeDefaultImages'
var groupImageResizeWebhookEndpoint = 'https://${functionAppName}.azurewebsites.net/runtime/webhooks/blobs?functionName=Host.Functions.${groupFunctionName}&code=${blobExtensionKey}'
var eventImageResizeWebhookEndpoint = 'https://${functionAppName}.azurewebsites.net/runtime/webhooks/blobs?functionName=Host.Functions.${eventFunctionName}&code=${blobExtensionKey}'
var sheetImageResizeWebhookEndpoint = 'https://${functionAppName}.azurewebsites.net/runtime/webhooks/blobs?functionName=Host.Functions.${sheetFunctionName}&code=${blobExtensionKey}'
var defaultImageResizeWebhookEndpoint = 'https://${functionAppName}.azurewebsites.net/runtime/webhooks/blobs?functionName=Host.Functions.${defaultFunctionName}&code=${blobExtensionKey}'

// #####################################################
// References
// #####################################################

resource functionApp 'Microsoft.Web/sites@2021-03-01' existing = {
  name: functionAppName
}

resource functionAppHost 'Microsoft.Web/sites/host@2022-09-01' existing = {
  name: 'default'
  parent: functionApp
}

// #####################################################
// Resources
// #####################################################

// #####################################################
// Modules
// #####################################################

module eventGridSubscriptionsModule './comms-imagesubs.bicep' = {
  name: 'EventGridSubscriptionsModule'
  scope: resourceGroup(imagesStorageAccountResourceGroupName)
  params: {
    producerStorageAccountName: imagesStorageAccountName
    groupImageResizeWebhookEndpoint: groupImageResizeWebhookEndpoint
    eventImageResizeWebhookEndpoint: eventImageResizeWebhookEndpoint
    sheetImageResizeWebhookEndpoint: sheetImageResizeWebhookEndpoint
    defaultImageResizeWebhookEndpoint: defaultImageResizeWebhookEndpoint
    environmentTag: environmentTag
  }
}

