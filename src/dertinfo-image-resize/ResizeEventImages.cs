using DertInfo.ImageResize.Services;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace DertInfo.ImageResize
{
    internal class ResizeEventImages
    {
        public const string ImageFolder = "eventimages";
        private readonly ILogger<ResizeEventImages> _logger;
        private readonly IImageProcessingService _imageProcessingService;

        public ResizeEventImages(ILogger<ResizeEventImages> logger, IImageProcessingService imageProcessingService)
        {
            _logger = logger;
            _imageProcessingService = imageProcessingService;
        }

        [Function(nameof(ResizeEventImages))]
        public async Task RunEventGrid([BlobTrigger(ImageFolder + "/originals/{name}", Source = BlobTriggerSource.EventGrid, Connection = "StorageConnection:Images")] Stream inputBlob, string name)
        {
            _logger.LogInformation($"Resize {ImageFolder} - Processed blob: {name} - EventGrid Trigger");

            await _imageProcessingService.ResizeImageStreamAndSave(inputBlob, name, new List<string>() { "100x100", "480x360" }, ImageFolder);
        }

        [Function(nameof(ResizeEventImages) + "Polling")]
        public async Task RunPolling([BlobTrigger(ImageFolder + "/originals/{name}", Source = BlobTriggerSource.LogsAndContainerScan, Connection = "StorageConnection:Images")] Stream inputBlob, string name)
        {
            _logger.LogInformation($"Resize {ImageFolder} - Processed blob: {name} - Polling Trigger");

            await _imageProcessingService.ResizeImageStreamAndSave(inputBlob, name, new List<string>() { "100x100", "480x360" }, ImageFolder);
        }

        
    }
}
