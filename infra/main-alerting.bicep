// #####################################################
// Parameters
// #####################################################

@description('The name of the function app that we are monitoring.')
param functionAppName string

@description('The name of the action group that we are notifying.')
param excessiveUseActionGroupName string

@description('The resource group that contains the action group.')
param excessiveUseActionGroupResourceGroup string

@description('The name of the action group that we are notifying.')
param stopWorkloadActionGroupName string

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

// #####################################################
// References
// #####################################################

resource stopWorkloadActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' existing = {
  name: stopWorkloadActionGroupName
}

// #####################################################
// Resources
// #####################################################

// #####################################################
// Modules
// #####################################################

module excessRequestsRuleModule './main-alerting-rule-excessrequests.bicep' = {
  name: 'ExcessRequestsRuleModule'
  params: {
    functionAppName: functionAppName
    excessiveUseActionGroupName: excessiveUseActionGroupName
    excessiveUseActionGroupResourceGroup: excessiveUseActionGroupResourceGroup
    warningThresholdForRequestsPer5mins: (environmentTag == 'prod') ? 100 : 10 
    environmentTag: environmentTag
  }
}

module threshholdReachedRuleModule './main-alerting-rule-threshholdreached.bicep' = {
  name: 'ThreshholdReachedRuleModule'
  params: {
    functionAppName: functionAppName
    stopWorkloadActionGroupName: stopWorkloadActionGroup.name
    actionThresholdForRequestsPerDay: (environmentTag == 'prod') ? 20000 : 100 
    environmentTag: environmentTag
  }
}

// #####################################################
// Outputs
// #####################################################
