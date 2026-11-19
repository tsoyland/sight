using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;

namespace Sight.Api.Tests;

public class HealthTests(WebApplicationFactory<Program> factory) : IClassFixture<WebApplicationFactory<Program>>
{
    [Theory]
    [InlineData("/health")]
    [InlineData("/health/live")]
    public async Task Health_endpoints_return_ok(string path)
    {
        var response = await factory.CreateClient().GetAsync(path);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Info_returns_app_name()
    {
        var info = await factory.CreateClient().GetFromJsonAsync<AppInfo>("/api/info");

        Assert.Equal("Sight", info?.Name);
    }
}
