using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Processing;

namespace DertInfo.ImageResize.Services
{
    /// <summary>
    /// This Service resizes images within a blob that it has access to. 
    /// </summary>
    public interface IImageResizeService
    {
        Task ResizeImageAsync(Stream inputStream, string fileName, string requiredSize, Stream outputStream, bool maintainScale = false);
    }

    public class ImageResizeService : IImageResizeService
    {
        public ImageResizeService()
        {
        }

        public async Task ResizeImageAsync(Stream inputStream, string fileName, string requiredSizeTag, Stream outputStream, bool maintainScale = false)
        {
            try
            {
                await PerformResizeAsync(inputStream, fileName, requiredSizeTag, outputStream, maintainScale);
            }
            catch (Exception ex)
            {
                throw new Exception(ex.ToString());
            }
        }

        private async Task PerformResizeAsync(Stream originalImageStream, string filename, string requiredSizeTag, Stream outputStream, bool maintainScale = false)
        {
            // Read the stream from the beginning
            if (originalImageStream.Position != 0) { originalImageStream.Seek(0, SeekOrigin.Begin); }

            // Identify the file type - default to jpeg
            SixLabors.ImageSharp.Formats.IImageFormat imageFormat = SixLabors.ImageSharp.Formats.Jpeg.JpegFormat.Instance;
            switch (System.IO.Path.GetExtension(filename))
            {
                case "png": imageFormat = SixLabors.ImageSharp.Formats.Png.PngFormat.Instance; break;
                case "bmp": imageFormat = SixLabors.ImageSharp.Formats.Bmp.BmpFormat.Instance; break;
                case "gif": imageFormat = SixLabors.ImageSharp.Formats.Gif.GifFormat.Instance; break;
                default: break;
            }

            // todo - this is quick as we're pushing through this. Come back to it.
            int imageTagDimension = requiredSizeTag == "480x360" ? 480 : 100;

            using (Image<Rgba32> image = Image.Load<Rgba32>(originalImageStream))
            {
                // Just don't make the images bigger than the original
                int targetWidth = image.Width > imageTagDimension ? imageTagDimension : image.Width;
                int targetHeight = image.Height > imageTagDimension ? imageTagDimension : image.Height;

                if (maintainScale)
                {
                    image.Mutate(x => x.Resize(targetWidth, 0));
                }
                else
                {
                    image.Mutate(x => x.Resize(targetWidth, targetHeight));
                }

                await image.SaveAsync(outputStream, imageFormat);
            }
        }
    }
}
