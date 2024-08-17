using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection.Metadata;
using System.Text;
using System.Threading.Tasks;

namespace DertInfo.ImageResize.Services
{

    public interface IImageProcessingService
    {
        Task ResizeImageStreamAndSave(Stream inputStream, string fileName, List<string> sizes, string imageFolder);
    }

    public class ImageProcessingService : IImageProcessingService
    {

        IImageResizeService _imageResizeService;
        IBlobWriter _blobWriter;

        public ImageProcessingService(IImageResizeService imageResizeService, IBlobWriter blobWriter)
        {
            _imageResizeService = imageResizeService;
            _blobWriter = blobWriter;
        }

        public async Task ResizeImageStreamAndSave(Stream inputStream, string fileName, List<string> sizes, string imageFolder)
        {
            foreach (var size in sizes)
            {
                await WriteResizedImage(inputStream, fileName, size, imageFolder);
            }
        }

        private async Task WriteResizedImage(Stream inputBlob, string name, string size, string imageFolder)
        {
            // Create the target streams for the resized images.
            using var outputStream = new MemoryStream();
            using var stream480x360 = new MemoryStream();

            // Resize the images into the new streams
            await _imageResizeService.ResizeImageAsync(inputBlob, name, size, outputStream);

            // Write the copy to the 100x100 blobs.
            await _blobWriter.WriteBlobStream(outputStream, imageFolder, $"{size}/{name}");
        }
    }
}
