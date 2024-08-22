/*
Outline: IaC for the ImageResizeV4 function app.
Author: David Hall
Created: 2024-08-15
Prerequisites:
- Requires an external image folder which is not included in this deployment.
- Requires an external application insights instance which is not included in this deployment.
- An action group that alerts interetes parties if the system is being overused.
Azure CLI Commands:
- az group create --name di-rg-imageresizev4-[env] --location uksouth
- az deployment group create --resource-group di-rg-imageresizev4-[env] --template-file main.bicep --parameters @parameters-main-[env].json
*/

// #####################################################
// Parameters
// #####################################################

@description('The initials of the owner.')
param ownerInitials string = 'di'

@description('The name of the workload being deployed.')
param workloadName string = 'imageresizev4'

@description('The images storage account name.')
param imagesStorageAccountName string

@description('The images storage account resource group name.')
param imagesStorageAccountResourceGroupName string

@description('The app insights instance name.')
param applicationInsightsName string

@description('The app insights instance resource group name.')
param applicationInsightsResourceGroupName string

@description('The name of the action group that we are notifying.')
param excessiveUseActionGroupName string

@description('The resource group that contains the action group.')
param excessiveUseActionGroupResourceGroup string

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

// Build the names for the resources
var uniqueStr = substring(uniqueString(resourceGroup().id),0,4)
var functionAppName = '${ownerInitials}-${uniqueStr}-func-${workloadName}-${environmentTag}'
var logicAppName = '${ownerInitials}-${uniqueStr}-logic-stopworkload-${environmentTag}'
var stopWorkloadActionGroupName = '${ownerInitials}-${uniqueStr}-agrp-stopworkload-${environmentTag}'

// #####################################################
// References
// #####################################################

// #####################################################
// Resources
// #####################################################

// #####################################################
// Modules
// #####################################################

module functionAppModule './main-functionapp.bicep' = {
  name: 'FunctionAppModule'
  params: {
    functionAppName: functionAppName
    appInsightsInstumetationKey: monitoringModule.outputs.appInsightsInstrumentationKey
    imagesStorageAccountName: imagesStorageAccountName
    imagesStorageAccountResourceGroupName: imagesStorageAccountResourceGroupName
    environmentTag: environmentTag
  }
}

module monitoringModule './main-monitoring.bicep' = {
  name: 'MonitoringModule'
  params: {
    applicationInsightsName: applicationInsightsName // External Resource
    applicationInsightsResourceGroup: applicationInsightsResourceGroupName // External Resource Group
  }
}

module alertingModule './main-alerting.bicep' = {
  name: 'AlertingModule'
  params: {
    excessiveUseActionGroupName: excessiveUseActionGroupName // External Resource
    excessiveUseActionGroupResourceGroup: excessiveUseActionGroupResourceGroup // External Resource Group
    functionAppName: functionAppModule.outputs.functionAppName
    stopWorkloadActionGroupName: automationModule.outputs.stopWorkloadActionGroupName
    environmentTag: environmentTag
  }
}

module automationModule './main-automation.bicep' = {
  name: 'AutomationModule'
  params: {
    functionAppName: functionAppModule.outputs.functionAppName
    logicAppName: logicAppName
    stopWorkloadActionGroupName: stopWorkloadActionGroupName
    environmentTag: environmentTag
  }
}

// #####################################################
// Outputs
// #####################################################

