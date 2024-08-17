FROM mcr.microsoft.com/dotnet/sdk:8.0-preview AS installer-env

COPY . /src/dotnet-function-app
RUN cd /src/dotnet-function-app && \
mkdir -p /home/site/wwwroot && \
dotnet publish *.csproj --output /home/site/wwwroot

# To enable ssh & remote debugging on app service change the base image to the one below
# FROM mcr.microsoft.com/azure-functions/dotnet-isolated:4-dotnet-isolated8.0-appservice
FROM mcr.microsoft.com/azure-functions/dotnet-isolated:4-dotnet-isolated8.0
ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true \
    AzureWebJobsStorage=UseDevelopmentStorage=true \
    FUNCTIONS_WORKER_RUNTIME=dotnet-isolated \
    StorageConnection:Images=UseDevelopmentStorage=true \
    AzureWebJobs.ResizeDefaultImages.Disabled=true \
    AzureWebJobs.ResizeEventImages.Disabled=true \
    AzureWebJobs.ResizeGroupImages.Disabled=true \
    AzureWebJobs.ResizeSheetImages.Disabled=true \
    AzureWebJobs.ResizeDefaultImagesPolling.Disabled=false \
    AzureWebJobs.ResizeEventImagesPolling.Disabled=false \
    AzureWebJobs.ResizeGroupImagesPolling.Disabled=false \
    AzureWebJobs.ResizeSheetImagesPolling.Disabled=false

COPY --from=installer-env ["/home/site/wwwroot", "/home/site/wwwroot"]