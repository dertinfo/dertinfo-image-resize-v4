using DertInfo.ImageResize.Services;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace DertInfo.ImageResize
{
    internal class ResizeGroupImages
    {
        public const string ImageFolder = "groupimages";
        private readonly ILogger<ResizeGroupImages> _logger;
        private readonly IImageProcessingService _imageProcessingService;

        public ResizeGroupImages(ILogger<ResizeGroupImages> logger, IImageProcessingService imageProcessingService)
        {
            _logger = logger;
            _imageProcessingService = imageProcessingService;
        }

        [Function(nameof(ResizeGroupImages))]
        public async Task RunEventGrid([BlobTrigger(ImageFolder + "/originals/{name}", Source = BlobTriggerSource.EventGrid, Connection = "StorageConnection:Images")] Stream inputBlob, string name)
        {
            _logger.LogInformation($"Resize {ImageFolder} - Processed blob: {name} - EventGrid Trigger");

            await _imageProcessingService.ResizeImageStreamAndSave(inputBlob, name, new List<string>() { "100x100", "480x360" }, ImageFolder);
        }

        [Function(nameof(ResizeGroupImages) + "Polling")]
        public async Task RunPolling([BlobTrigger(ImageFolder + "/originals/{name}", Source = BlobTriggerSource.LogsAndContainerScan, Connection = "StorageConnection:Images")] Stream inputBlob, string name)
        {
            _logger.LogInformation($"Resize {ImageFolder} - Processed blob: {name} - Polling Trigger");

            await _imageProcessingService.ResizeImageStreamAndSave(inputBlob, name, new List<string>() { "100x100", "480x360" }, ImageFolder);
        }
    }
}
