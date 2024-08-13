


# DertInfo - Image Resize V4

This is a small function app that uses image sharp .NET to resize images in a blob storage account. This version of the image resize app uses Azure Functions v4 runtime.

This repository is a direct replacement for the [dertinfo-image-resize](https://github.com/dertinfo/dertinfo-image-resize) function app. 

We have a seperate repository as they will both be running at the same time during the transition. 

This project watches for new images in the following locations in the images storage accounts.

- /groupimages/originals-a
- /eventimages/originals-a
- /sheetimages/originals-a

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

This project is a C# .NET API currently running .NET Core 3.1

## Topology

![Application Containers](/docs/images/architecture-dertinfo-image-resize-containerlevel.png)

## Installation

In order to get this project running locally you are going to need.

- Visual Studio Community
- Azurite
- Azure Storage Explorer

## Infrastucture

This project has a folder of /infra at the root of the repository that contains bicep files that will allow this project to be deployed to a resource group within an Azure subscription. 

For this at this time we are deploying manually from the Azure CLI. This can be done either from an Azure CLoud Shell or from a local install. 

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

There are 4 bicep files at this time that are manually deployed and need to be deployed in this order:

- deploy.bicep - the main function app and plan
- configure.bicep - storage account event grid system topic
- automation.bicep - alert action and notification groups and automation logic apps
- montoring.bicep - alerts that trigger automation actions.


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
  }
}
```

This file tells the app where it's state is managed via the storage account "AzureWebJobsStorage" and the storage account where the original images are uploaded to read to be resized "StorageConnection:Images". In development they use the same storage account which can be either a docker asurite or local Azurite running on port 10000, 10001, 10002

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
- 1) Running locally
- 2) Running in docker desktop

## Usage

Add images to the originals folder (/originals-a path) in the Azure Blob Storage Container and those images will be resized. 

## Features

The image resize function app will watch an Azure Blob Storage Account (or emulator) with the following structure:

![BlobStorageStructure](/docs/images/image-resize-folder-structure.png)

it will take any new images added to the orignals folder and create resized images in the given dimensions. 

## Contributing

Please refer to [CONTRIBUTING.md](/CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](/CODE_OF_CONDUCT.md) for information on how others can contribute to the project.

## License

This project is licenced under the GNU_GPLv3 licence. Please refer to the [LICENCE.md](/LICENCE.md) file for more information. 
