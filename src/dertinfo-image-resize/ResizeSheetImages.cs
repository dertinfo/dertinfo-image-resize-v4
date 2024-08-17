using DertInfo.ImageResize.Services;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace DertInfo.ImageResize
{
    internal class ResizeSheetImages
    {
        public const string ImageFolder = "sheetimages";
        private readonly ILogger<ResizeSheetImages> _logger;
        private readonly IImageProcessingService _imageProcessingService;

        public ResizeSheetImages(ILogger<ResizeSheetImages> logger, IImageProcessingService imageProcessingService)
        {
            _logger = logger;
            _imageProcessingService = imageProcessingService;
        }

        [Function(nameof(ResizeSheetImages))]
        public async Task RunEventGrid([BlobTrigger(ImageFolder + "/originals/{name}", Source = BlobTriggerSource.EventGrid, Connection = "StorageConnection:Images")] Stream inputBlob, string name)
        {
            _logger.LogInformation($"Resize {ImageFolder} - Processed blob: {name} - EventGrid Trigger");

            await _imageProcessingService.ResizeImageStreamAndSave(inputBlob, name, new List<string>() { "100x100", "480x360" }, ImageFolder);
        }

        [Function(nameof(ResizeSheetImages) + "Polling")]
        public async Task RunPolling([BlobTrigger(ImageFolder + "/originals/{name}", Source = BlobTriggerSource.LogsAndContainerScan, Connection = "StorageConnection:Images")] Stream inputBlob, string name)
        {
            _logger.LogInformation($"Resize {ImageFolder} - Processed blob: {name} - Polling Trigger");

            await _imageProcessingService.ResizeImageStreamAndSave(inputBlob, name, new List<string>() { "100x100", "480x360" }, ImageFolder);
        }
    }
}
