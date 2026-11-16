using System.Reflection;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Sight.Api.Hubs;

var builder = WebApplication.CreateBuilder(args);

var connectionString = builder.Configuration.GetConnectionString("Sight");
var healthChecks = builder.Services.AddHealthChecks();
// Without a connection string (local runs without Postgres, tests) the database check is skipped.
if (!string.IsNullOrWhiteSpace(connectionString))
{
    healthChecks.AddNpgSql(connectionString, name: "database", tags: ["ready"]);
}

builder.Services.AddSignalR();

var app = builder.Build();

// The built React app (web/dist) is copied into wwwroot by the Dockerfile.
app.UseDefaultFiles();
app.UseStaticFiles();

// Liveness: the process is up. Used by Scaleway's probes, so a database blip doesn't restart the container.
app.MapHealthChecks("/health/live", new HealthCheckOptions { Predicate = _ => false });
// Readiness: everything including the database.
app.MapHealthChecks("/health");

var version = typeof(Program).Assembly
    .GetCustomAttribute<AssemblyInformationalVersionAttribute>()?.InformationalVersion.Split('+')[0] ?? "0.0.0";

var api = app.MapGroup("/api");
api.MapGet("/info", () => new AppInfo("Sight", version));

app.MapHub<PingHub>("/hubs/ping");

// Unknown non-API routes fall through to the SPA so client-side routing works.
app.MapFallbackToFile("index.html");

app.Run();

public record AppInfo(string Name, string Version);

// Exposed for WebApplicationFactory in tests.
public partial class Program;
