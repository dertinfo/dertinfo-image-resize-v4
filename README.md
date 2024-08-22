


# DertInfo - Image Resize V4

This is a small function app that uses image sharp .NET to resize images in a blob storage account. This version of the image resize app uses Azure Functions v4 runtime.

This repository is a direct replacement for the [dertinfo-image-resize](https://github.com/dertinfo/dertinfo-image-resize) function app. 

We have a seperate repository as they will both be running at the same time during the transition. 

This project watches for new images in the following locations in the images storage accounts.

- /groupimages/originals
- /eventimages/originals
- /sheetimages/originals

This is in order that images previously uploaded (to originals) are not reprocessed by this function app.

> **Note:** If you are unfamilar with the collection of services that are part of DertInfo please refer to the repository dertinfo/dertinfo.

## Table of Contents

- [Technology](#technology)
- [Topology](#topology)
- [Installation](#installation)
- [Infrastucture](#infrastructure)
- [Usage](#usage)
- [Features](#features)
- [Contributing](#contributing)
- [License](#license)

## Technology

This project is a C# .NET API currently running .NET8

## Topology

![Application Containers](/docs/images/architecture-dertinfo-image-resize-containerlevel.png)

## Installation

### Local Development

In order to get this project running locally you are going to need.

- Visual Studio Community
- Azurite
- Azure Storage Explorer
- Docker Desktop

### Docker

To run this function in docker then you can:

Run the file located at infra/docker/docker-compose.yml
From the root of the repository execute the folowing command: 

```
docker-compose -f infra/docker/docker-compose.yml up

```
This will create 2 containers. One with Azurite and one with the Image Resize Function App. It will alos bind a docker volume for the persistance of the iamge data. 

# How To Use 

Once you have the solution running:

1) Open Azure Storage Explorer and connect to Azurite on ports 10000
2) Create new Blob containers of "groupimages,eventimages,defaultimages,sheetimages"
3) Create a new blob at the path "originals/" (In the emulator it'll call this a folder)
4) Watch the function app will create 2 new folders at the root of the cotnainer "100x100", "480x360"
5) It will then resize the orignal iamge and place it in those folders with the same file name as the original. 

## Infrastucture

This project has a folder of /infra at the root of the repository that contains bicep files that will allow this project to be deployed to a resource group within an Azure subscription. 

### Deployments To the hosted site
There are Azure DevOps pipelines that watch the main branch of this repository and run on commits to code into either the /src or /infra folders

### Deploying to your own subscription
Use the following commands to setup the infrastucture for this project: 

- env - values of stg,prod
- tenantId - the id of the Azure tenant used to host the application
- subsriptionId - the id of the Azure subscription that contains the resources.

```
az login --tenant [TenantId]
az account set --subscription [SubscriptionId]
az group create --name di-rg-imageresizev4-[env] --location uksouth
az deployment group create --resource-group di-rg-imageresizev4-[env] --template-file deploy.bicep --parameters @deploy-params-[env].json
```

There are 2 bicep files that can be manually deployed and need to be deployed in this order:

- deploy.bicep - the main function app and service plan, alerting and other items
- You must then deploy the code so that the endpoints for event grid are available. 
- comms.bicep - this is the setup of event grid against a storage account that contains the images.

## Running The Project

To get the project running you will need to setup: 
- You user secrets
- Your storage emulator

Once these have been done then simply run the project in Visual Studio. 

**local.settings.json**
You will need to add this file "local.settings.json" to the root of the project as it is ommitted from source control. It should sit just next to host.json

Fill it with the following:

```
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
    "StorageConnection:Images": "UseDevelopmentStorage=true"
    "AzureWebJobs.ResizeDefaultImages.Disabled": "true",
    "AzureWebJobs.ResizeEventImages.Disabled": "true",
    "AzureWebJobs.ResizeGroupImages.Disabled": "true",
    "AzureWebJobs.ResizeSheetImages.Disabled": "true",
    "AzureWebJobs.ResizeDefaultImagesPolling.Disabled": "false",
    "AzureWebJobs.ResizeEventImagesPolling.Disabled": "false",
    "AzureWebJobs.ResizeGroupImagesPolling.Disabled": "false",
    "AzureWebJobs.ResizeSheetImagesPolling.Disabled": "false"
  }
}
```

This file tells the app where it's state is managed via the storage account "AzureWebJobsStorage" and the storage account where the original images are uploaded to read to be resized "StorageConnection:Images". In development they use the same storage account which can be either a docker asurite or local Azurite running on port 10000, 10001, 10002

Note where we are disabling some functions in development. In the project we have functions that'll trigger by either event grid or by polling the storage account. Event Grid will only work when deployed in Azure with approprate configution so we use polling in local development to ease developemnt.

Note that we have 8 functions. The result in the same excecution however in local development the triggers are fired due to polling the storage account for changes. In staging and production they utilise event grid to notify the app of changes. 

**User Secrets**
```
{
}
```
You do not need to use user secrets for this repository. We use "UseDevelopmentStorage=true" as the connection string to connect to Azurite either running locally or on a docker container on ports :10000, 10001, 10002

### To run the Image Resize Function

#### Running the Function

Open the solution in Visual Studion Community and run the function

#### Emulating the Blob Storage Account

Launch Azure Storage Emulator or Azurite. Connect to the Storage Using Azure Storage Explorer. 

#### From Visual Studio
You can run the Function App locally from Visual Studio in 2 ways. 
- 1) Running from visual studio
- 2) Running in docker using the docker file

## Usage

Add images to the originals folder (/originals path) in the Azure Blob Storage Container and those images will be resized. 

## Features

The image resize function app will watch an Azure Blob Storage Account (or emulator) with the following structure:

![BlobStorageStructure](/docs/images/image-resize-folder-structure.png)

it will take any new images added to the orignals folder and create resized images in the given dimensions. 

## Contributing

Please refer to [CONTRIBUTING.md](/CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](/CODE_OF_CONDUCT.md) for information on how others can contribute to the project.

## License

This project is licenced under the GNU_GPLv3 licence. Please refer to the [LICENCE.md](/LICENCE.md) file for more information. 
