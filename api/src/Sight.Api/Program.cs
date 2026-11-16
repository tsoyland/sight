using System.Reflection;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHealthChecks();

var app = builder.Build();

// The built React app (web/dist) is copied into wwwroot by the Dockerfile.
app.UseDefaultFiles();
app.UseStaticFiles();

app.MapHealthChecks("/health");

var api = app.MapGroup("/api");
var version = typeof(Program).Assembly
    .GetCustomAttribute<AssemblyInformationalVersionAttribute>()?.InformationalVersion.Split('+')[0] ?? "0.0.0";
api.MapGet("/info", () => new AppInfo("Sight", version));

// Unknown non-API routes fall through to the SPA so client-side routing works.
app.MapFallbackToFile("index.html");

app.Run();

public record AppInfo(string Name, string Version);

// Exposed for WebApplicationFactory in tests.
public partial class Program;
