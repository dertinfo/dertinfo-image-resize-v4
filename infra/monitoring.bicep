/*
Outline: This bicep file configures the monitoring & alerts for the ImageResizeV4 function app.
Author: David Hall
Created: 2024-08-12
Prerequisites:
- deploy.bicep must be run before this is run. This ensures function app is present.
- There must be an action group created to notify on excessive use.
Notes: 
- This deployment will create an action rule to alert on a high number of requests.
Azure CLI Commands:
- az group create --name di-rg-imageresizev4-[env] --location uksouth
- az deployment group create --resource-group di-rg-imageresizev4-[env] --template-file monitoring.bicep --parameters @monitoring-params-[env].json
*/

// #####################################################
// Parameters
// #####################################################

@description('The name of the function app that we are monitoring.')
param functionAppName string = 'di-func-imageresizev4-dev'

@description('The name of the action group that we are notifying.')
param stopWorkloadActionGroupName string = 'di-agrp-stopworkload-stg'

@description('The name of the action group that we are notifying.')
param excessiveUseActionGroupName string = 'di-agrp-excessiveuse-stg'

@description('The resource group that contains the action group.')
param excessiveUseActionGroupResourceGroup string = 'di-rg-monitoring-stg'

@description('Threashhold for the excessive requests.')
param warningThresholdForRequestsPer5mins int = 10

@description('Threashhold for the excessive requests.')
param actionThresholdForRequestsPerDay int = 20000

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

var excessiveUseRuleName = '${functionAppName}-excessiverequests-alert-rule'
var excessiveUseRuleDescription = 'Alert rule for high number of requests. Notifies us of what we deem to be excessive use.'
var thresholdReachedRuleName = '${functionAppName}-thresholdreached-alert-rule'
var thresholdReachedRuleDescription = 'Alert rule for a threshhold being reached such that we want to stop processing requests to protect costs.'

// #####################################################
// References
// #####################################################

// Find the function app
resource functionApp 'Microsoft.Web/sites@2021-03-01' existing = {
  name: functionAppName
}

// Find the excessive use action group
resource excessiveUseActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' existing = {
  name: excessiveUseActionGroupName
  scope: resourceGroup(excessiveUseActionGroupResourceGroup)
}

// Find the stop workload action group
resource stopWorkloadActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' existing = {
  name: stopWorkloadActionGroupName
}

// #####################################################
// Resources
// #####################################################
@description('Create the excessive use rule for the function app. This will alert us when the number of requests is too high.')
resource actionRuleExcessiveRequests 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: excessiveUseRuleName
  location: 'global'
  tags: {
    environment: environmentTag
  }
  properties: {
    description: excessiveUseRuleDescription
    severity: 2
    enabled: true
    scopes: [
      functionApp.id
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          name: 'Excessive Requests 10'
          criterionType: 'StaticThresholdCriterion'
          metricName: 'Requests'
          metricNamespace: 'Microsoft.Web/sites'
          operator: 'GreaterThan'
          threshold: warningThresholdForRequestsPer5mins
          timeAggregation: 'Total' 
          skipMetricValidation: false
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
    actions: [
      {
        actionGroupId: excessiveUseActionGroup.id
      }
    ]
    autoMitigate: true
    targetResourceType: 'Microsoft.Web/sites'
    targetResourceRegion: resourceGroup().location
  }
}

@description('Create the threahold reached rule for the function app. This will take action to stop the app if the threshold is reached.')
resource actionRuleRequestThresholdReached 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: thresholdReachedRuleName
  location: 'global'
  tags: {
    environment: environmentTag
  }
  properties: {
    description: thresholdReachedRuleDescription
    severity: 0
    enabled: true
    scopes: [
      functionApp.id
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          name: 'Excessive Requests 20000'
          criterionType: 'StaticThresholdCriterion'
          metricName: 'Requests'
          metricNamespace: 'Microsoft.Web/sites'
          operator: 'GreaterThan'
          threshold: actionThresholdForRequestsPerDay
          timeAggregation: 'Total' 
          skipMetricValidation: false
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
    actions: [
      {
        actionGroupId: stopWorkloadActionGroup.id
      }
    ]
    autoMitigate: true
    targetResourceType: 'Microsoft.Web/sites'
    targetResourceRegion: resourceGroup().location
  }
}

// #####################################################
// Modules
// #####################################################
