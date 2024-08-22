// #####################################################
// Parameters
// #####################################################

@description('The name of the function app that we are monitoring.')
param functionAppName string

@description('The name of the logic app for stopping the workload')
param logicAppName string

@description('The name of the stop workload action group.')
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

var armConnectionName = '${logicAppName}-arm-connection'
var azureManagedConnectorResourceId = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${resourceGroup().location}/managedApis/arm'
var functionAppPath = 'sites/${functionAppName}'
var functionAppOperation = 'stop'

// #####################################################
// References
// #####################################################

// #####################################################
// Resources
// #####################################################

resource armConnection 'Microsoft.Web/connections@2018-07-01-preview' = {
  name: armConnectionName
  location: resourceGroup().location
  tags: {
    environment: environmentTag
  }
  properties: {
    displayName: 'arm-connection'
    authenticatedUser: {}
    parameterValueType: 'Alternative' // Important for managed identity authentication
    api: {
      name: 'arm'
      displayName: 'Azure Resource Manager'
      category: 'Standard'
      type: 'Microsoft.Web/locations/managedApis'
      id: azureManagedConnectorResourceId
    }
  }
}
// notes - Kind: V2 warning is raised here https://github.com/Azure/bicep/issues/3512. 
//         We need kind V1 for consuption logic apps with single authentication.
//         The V2 kind is for multi-authentication logic apps.  
//         Using @2018-07-01-preview as reduces warnings. 

resource stopWorkloadLogicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: resourceGroup().location
  tags: {
    environment: environmentTag
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        When_a_HTTP_request_is_received: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            method: 'POST'
          }
        }
      }
      actions: {
        Invoke_resource_operation: {
          runAfter: {}
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'arm\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/subscriptions/@{encodeURIComponent(\'${subscription().subscriptionId}\')}/resourcegroups/@{encodeURIComponent(\'${resourceGroup().name}\')}/providers/@{encodeURIComponent(\'Microsoft.Web\')}/@{encodeURIComponent(\'${functionAppPath}\')}/@{encodeURIComponent(\'${functionAppOperation}\')}'
            queries: {
              'x-ms-api-version': '2021-03-01'
            }
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          arm: {
            id: azureManagedConnectorResourceId
            connectionId: armConnection.id
            connectionName: armConnectionName
            connectionProperties: {
              authentication: {
                type: 'ManagedServiceIdentity'
              }
            }
          }
        }
      }
    }
  }
}

resource customRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' = {
  name: guid(resourceGroup().id, stopWorkloadLogicApp.name, 'FunctionStopRole')
  properties: {
    roleName: '${stopWorkloadLogicApp.name}-stopfunctionapp-role'
    description: 'Custom role to allow stopping a function app'
    permissions: [
      {
        actions: [
          'Microsoft.Web/sites/stop/action'
        ]
        notActions: []
      }
    ]
    assignableScopes: [
      resourceGroup().id
    ]
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, stopWorkloadLogicApp.name, 'FunctionStopRoleAssignement')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', customRole.name)
    principalId: stopWorkloadLogicApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
// note - from documentation this gets assigned at the deployment scope which in this instance is going to be the resource group.

resource stopWorkloadActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: stopWorkloadActionGroupName
  location: 'global'
  tags: {
    environment: environmentTag
  }
  properties: {
    groupShortName: 'ThresholdHit'
    enabled: true
    logicAppReceivers: [
      {
        name: 'StopWorkload'
        resourceId: stopWorkloadLogicApp.id
        // callbackUrl: stopWorkloadLogicApp.listCallbackUrl().value
        callbackUrl: listCallbackURL('${stopWorkloadLogicApp.id}/triggers/When_a_HTTP_request_is_received', '2019-05-01').value
        useCommonAlertSchema: true
      }
    ]
  }
}

// #####################################################
// Modules
// #####################################################

// #####################################################
// Outputs
// #####################################################

output stopWorkloadActionGroupName string = stopWorkloadActionGroup.name
