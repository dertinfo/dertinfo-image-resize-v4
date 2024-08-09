/*
Outline: This bicep file is used to setup system topic for event grid and the event grid subscriptions.
Author: David Hall
Created: 2024-08-09
Notes: 
- This deployment will create a system topic and 3 event grid subscriptions.
- It will need to validate the web hook endpoints as part of the deployment
- The application code must be deployed ahead of this configuration
Azure CLI Commands:
- az group create --name di-rg-imageresizev4-[env] --location uksouth
- az deployment group create --resource-group di-rg-imageresizev4-[env] --template-file configure.bicep --parameters @configure-params-stg.json
*/

// #####################################################
// Parameters
// #####################################################

@description('The name of the function app that you wish to create.')
param functionAppName string = 'di-func-imageresizev4-dev'

@description('The images storage account name')
param imagesStorageAccountName string

@description('The images storage account resource group name')
param imagesStorageAccountResourceGroup string

// #####################################################
// Variables
// #####################################################

var allKeys = consumerFunctionApp.listKeys().keys // Get all the keys for the function app
var blobExtensionKey = filter(allKeys, key => key.keyName == 'blobs_extension')[0] // We want the key with the name blobs_extension
var groupFunctionName = 'GroupImageResize'
var eventFunctionName = 'EventImageResize'
var sheetFunctionName = 'SheetImageResize'
var groupImageResizeWebhookEndpoint = 'https://${functionAppName}.azurewebsites.net/runtime/webhooks/blobs?functionName=Host.Functions.${groupFunctionName}&code=${blobExtensionKey}'
var eventImageResizeWebhookEndpoint = 'https://${functionAppName}.azurewebsites.net/runtime/webhooks/blobs?functionName=Host.Functions.${eventFunctionName}&code=${blobExtensionKey}'
var sheetImageResizeWebhookEndpoint = 'https://${functionAppName}.azurewebsites.net/runtime/webhooks/blobs?functionName=Host.Functions.${sheetFunctionName}&code=${blobExtensionKey}'

// #####################################################
// References
// #####################################################

resource consumerFunctionApp 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: functionAppName
}

// #####################################################
// Resources
// #####################################################

// #####################################################
// Modules
// #####################################################

module eventGridSubscriptionsModule './configure-subscriptions.bicep' = {
  name: 'eventGridSubscriptionsModule'
  scope: resourceGroup(imagesStorageAccountResourceGroup)
  params: {
    producerStorageAccountName: imagesStorageAccountName
    groupImageResizeWebhookEndpoint: groupImageResizeWebhookEndpoint
    eventImageResizeWebhookEndpoint: eventImageResizeWebhookEndpoint
    sheetImageResizeWebhookEndpoint: sheetImageResizeWebhookEndpoint
  }
}
