// #####################################################
// Parameters
// #####################################################

@description('The name of the function app that we are monitoring.')
param functionAppName string

@description('The name of the action group that we are notifying.')
param stopWorkloadActionGroupName string

@description('Threashhold for the excessive requests.')
param actionThresholdForRequestsPerDay int

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

var thresholdReachedRuleName = '${functionAppName}-thresholdreached-alert-rule'
var thresholdReachedRuleDescription = 'Alert rule for a threshhold being reached such that we want to stop processing requests to protect costs.'

// #####################################################
// References
// #####################################################

resource functionApp 'Microsoft.Web/sites@2021-03-01' existing = {
  name: functionAppName
}

resource stopWorkloadActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' existing = {
  name: stopWorkloadActionGroupName
}

// #####################################################
// Resources
// #####################################################

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
          metricName: 'FunctionExecutionCount'
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

// #####################################################
// Outputs
// #####################################################
