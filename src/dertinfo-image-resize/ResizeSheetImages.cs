using DertInfo.ImageResize.Services;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace DertInfo.ImageResize
{
    internal class ResizeSheetImages
    {
        public const string ImageFolder = "sheetimages";
        private readonly ILogger<ResizeSheetImages> _logger;
        private readonly IImageResizeService _imageResizeService;
        private readonly IBlobWriter _blobWriter;

        public ResizeSheetImages(ILogger<ResizeSheetImages> logger, IImageResizeService imageResizeService, IBlobWriter blobWriter)
        {
            _logger = logger;
            _imageResizeService = imageResizeService;
            _blobWriter = blobWriter;
        }

        [Function(nameof(ResizeSheetImages))]
        public async Task Run([BlobTrigger(ImageFolder + "/originals-a/{name}", Source = BlobTriggerSource.EventGrid, Connection = "StorageConnection:Images")] Stream inputBlob, string name)
        {
            _logger.LogInformation($"Resize {ImageFolder} - Processed blob: {name}");

            // Create the target streams for the resized images.
            using var stream480x360 = new MemoryStream();

            // Resize the images into the new streams
            await _imageResizeService.ResizeImageAsync(inputBlob, name, "480x360", stream480x360, true);

            // Write the copy to the 100x100 blobs.
            await _blobWriter.WriteBlobStream(stream480x360, ImageFolder, $"480x360/{name}");
        }
    }
}
