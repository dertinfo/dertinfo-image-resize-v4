// #####################################################
// Parameters
// #####################################################

@description('The app insights instance name.')
param applicationInsightsName string

@description('The app insights instance resource group name.')
param applicationInsightsResourceGroup string

// #####################################################
// Variables
// #####################################################

// #####################################################
// References
// #####################################################

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
  scope: resourceGroup(applicationInsightsResourceGroup)
}

// #####################################################
// Resources
// #####################################################

// #####################################################
// Modules
// #####################################################

// #####################################################
// Outputs
// #####################################################

output appInsightsInstrumentationKey string = applicationInsights.properties.InstrumentationKey
