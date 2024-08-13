/*
Outline: Constucts to Action Group fo stopping the workload
Author: David Hall
Created: 2024-08-12
Prerequisites:
- Function app must be deployed.
Notes: 
- This deployment will create:
- A connection to the ARM API
- A logic app that will call the ARM API to stop the function app
- A action group that will trigger the logic app
Azure CLI Commands:
- az group create --name di-rg-imageresizev4-[env] --location uksouth
- az deployment group create --resource-group di-rg-imageresizev4-[env] --template-file automation.bicep --parameters @automation-params-[env].json
Extra
- If you are ever doing this again ensure that you keep the @{encodeURIComponent(\'${subscription().subscriptionId}\') in the invoke resource paths.
  It is required to ensure that the path is correctly formatted. If you are stil having problems validate the Json output between a portal constucted logic App & Conenction
  with the bicep deployed one and look at the differences. 
*/

// #####################################################
// Parameters
// #####################################################

@description('The name of the function app that we are monitoring.')
param functionAppName string = 'di-func-imageresizev4-dev'

@description('The name of the logic app for stopping the workload')
param logicAppName string = 'di-logic-stopworkload-stg'

@description('The name of the stop workload action group.')
param stopWorkloadActionGroupName string = 'di-agrp-stopworkload-stg'

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
var functionAppPath = 'sites/${functionApp.name}'
var functionAppOperation = 'stop'

// #####################################################
// References
// #####################################################

// Find the function app
resource functionApp 'Microsoft.Web/sites@2021-03-01' existing = {
  name: functionAppName
}

// #####################################################
// Resources
// #####################################################

@description('Build the ARM connection for the logic app.')
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

@description('Create the logic app that will trigger the stop workload action on the function app.')
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

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, stopWorkloadLogicApp.name, 'Contributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor role
    principalId: stopWorkloadLogicApp.identity.principalId
    principalType: 'ServicePrincipal'
    scope: resourceGroup().id
  }
}

@description('Create the action group that will trigger the stop workload logic app.')
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
