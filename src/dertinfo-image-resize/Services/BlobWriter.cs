using Azure.Storage.Blobs;
using Microsoft.Extensions.Configuration;

namespace DertInfo.ImageResize.Services
{
    public interface IBlobWriter
    {
        Task WriteBlobStream(Stream inputStream, string containerName, string fileName);
    }

    internal class BlobWriter : IBlobWriter
    {
        private readonly IConfiguration _configuration;

        public BlobWriter(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public async Task WriteBlobStream(Stream inputStream, string containerName, string blobPathAndName)
        {
            var connectionString = _configuration.GetValue<string>("StorageConnection:Images");

            // Get the target containers and create if they don't exist
            var blobServiceClient = new BlobServiceClient(connectionString);
            var containerClient = blobServiceClient.GetBlobContainerClient(containerName);
            await containerClient.CreateIfNotExistsAsync();

            var blobClient1 = containerClient.GetBlobClient(blobPathAndName);

            inputStream.Position = 0;
            await blobClient1.UploadAsync(inputStream, overwrite: true);
        }
    }
}
