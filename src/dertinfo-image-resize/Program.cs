using DertInfo.ImageResize.Services;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

var host = new HostBuilder()
    .ConfigureFunctionsWebApplication()
    .ConfigureServices(services =>
    {
        services.AddApplicationInsightsTelemetryWorkerService();
        services.ConfigureFunctionsApplicationInsights();

        // Register Services
        services.AddTransient<IBlobWriter, BlobWriter>();
        services.AddTransient<IImageResizeService, ImageResizeService>();
    })
    .Build();

host.Run();
