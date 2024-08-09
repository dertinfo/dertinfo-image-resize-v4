using DertInfo.ImageResize.Services;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace DertInfo.ImageResize
{
    internal class ResizeGroupImages
    {
        public const string ImageFolder = "groupimages";
        private readonly ILogger<ResizeGroupImages> _logger;
        private readonly IImageResizeService _imageResizeService;
        private readonly IBlobWriter _blobWriter;

        public ResizeGroupImages(ILogger<ResizeGroupImages> logger, IImageResizeService imageResizeService, IBlobWriter blobWriter)
        {
            _logger = logger;
            _imageResizeService = imageResizeService;
            _blobWriter = blobWriter;
        }

        [Function(nameof(ResizeGroupImages))]
        public async Task Run([BlobTrigger(ImageFolder + "/originals/{name}", Source = BlobTriggerSource.EventGrid, Connection = "StorageConnection:Images")] Stream inputBlob, string name)
        {
            _logger.LogInformation($"Resize {ImageFolder} - Processed blob: {name}");

            // Copy the input blob to a MemoryStream so that we only read it once.
            using var originalStream = new MemoryStream();
            await inputBlob.CopyToAsync(originalStream);

            // Create the target streams for the resized images.
            using var stream100x100 = new MemoryStream();
            using var stream480x360 = new MemoryStream();

            // Resize the images into the new streams
            await _imageResizeService.ResizeImageAsync(originalStream, name, "100x100", stream100x100);
            await _imageResizeService.ResizeImageAsync(originalStream, name, "480x360", stream480x360, true);

            // Write the copy to the 100x100 and 480x360 blobs.
            await _blobWriter.WriteBlobStream(stream100x100, ImageFolder, $"100x100/{name}");
            await _blobWriter.WriteBlobStream(stream480x360, ImageFolder, $"480x360/{name}");
        }
    }
}
