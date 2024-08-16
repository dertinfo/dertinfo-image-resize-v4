// #####################################################
// Parameters
// #####################################################

@description('The name of the function app that we are monitoring.')
param functionAppName string

@description('The name of the action group that we are notifying.')
param excessiveUseActionGroupName string

@description('The resource group that contains the action group.')
param excessiveUseActionGroupResourceGroup string

@description('Threshhold for the excessive requests.')
param warningThresholdForRequestsPer5mins int

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

// #####################################################
// Resources
// #####################################################

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

// #####################################################
// Modules
// #####################################################

// #####################################################
// Outputs
// #####################################################
