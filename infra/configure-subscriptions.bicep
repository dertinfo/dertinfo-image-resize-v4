// #####################################################
// Parameters
// #####################################################

@description('The name of the storage account that we want to listen to.')
param producerStorageAccountName string

@description('Webhook endpoint for group images resize function.')
param groupImageResizeWebhookEndpoint string 

@description('Webhook endpoint for event images resize function.')
param eventImageResizeWebhookEndpoint string 

@description('Webhook endpoint for sheet images resize function.')
param sheetImageResizeWebhookEndpoint string 

@description('Webhook endpoint for sheet images resize function.')
param location string = resourceGroup().location

@description('Envionment tag for resources.')
@allowed([
  'dev'
  'stg'
  'prod'
])
param environmentTag string = 'dev'

// #####################################################
// Variables
// #####################################################

// System Topic Name
var systemTopicName = '${producerStorageAccountName}-system-topic'

// Subscription Names
var groupOriginalImagesSubscriptionName = 'di-evgs-group-originals'
var eventOriginalImagesSubscriptionName = 'di-evgs-event-originals'
var sheetOriginalImagesSubscriptionName = 'di-evgs-sheet-originals'

// Blob Paths for filtering events
var groupOriginalImagesFilterPath = 'groupimages/blobs/originals/'
var eventOriginalImagesFilterPath = 'eventimages/blobs/originals/'
var sheetOriginalImagesFilterPath = 'sheetimages/blobs/originals/'

// #####################################################
// References
// #####################################################

resource producerStorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: producerStorageAccountName
}

// #####################################################
// Resources
// #####################################################

resource systemTopic 'Microsoft.EventGrid/systemTopics@2023-12-15-preview' = {
  name: systemTopicName
  location: location
  tags: {
    environment: environmentTag
  }
  properties: {
    source: producerStorageAccount.id
    topicType: 'Microsoft.Storage.StorageAccounts'
  }
}

resource eventSubscriptionGroupImages 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2023-12-15-preview' = {
  name: groupOriginalImagesSubscriptionName
  parent: systemTopic
  properties: {
    destination: {
      endpointType: 'WebHook'
      properties: {
        endpointUrl: groupImageResizeWebhookEndpoint
      }
    }
    filter: {
      includedEventTypes: [
        'Microsoft.Storage.BlobCreated'
      ]
      subjectBeginsWith: '/blobServices/default/containers/${groupOriginalImagesFilterPath}'
    }
  }
}

resource eventSubscriptionSheetImages 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2023-12-15-preview' = {
  name: eventOriginalImagesSubscriptionName
  parent: systemTopic
  properties: {
    destination: {
      endpointType: 'WebHook'
      properties: {
        endpointUrl: eventImageResizeWebhookEndpoint
      }
    }
    filter: {
      includedEventTypes: [
        'Microsoft.Storage.BlobCreated'
      ]
      subjectBeginsWith: '/blobServices/default/containers/${eventOriginalImagesFilterPath}'
    }
  }
}

resource sheetSubscriptionSheetImages 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2023-12-15-preview' = {
  name: sheetOriginalImagesSubscriptionName
  parent: systemTopic
  properties: {
    destination: {
      endpointType: 'WebHook'
      properties: {
        endpointUrl: sheetImageResizeWebhookEndpoint
      }
    }
    filter: {
      includedEventTypes: [
        'Microsoft.Storage.BlobCreated'
      ]
      subjectBeginsWith: '/blobServices/default/containers/${sheetOriginalImagesFilterPath}'
    }
  }
}

// #####################################################
// Modules
// #####################################################

