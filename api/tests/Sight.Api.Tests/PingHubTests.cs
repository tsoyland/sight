using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.SignalR.Client;
using Sight.Api.Hubs;

namespace Sight.Api.Tests;

public class PingHubTests(WebApplicationFactory<Program> factory) : IClassFixture<WebApplicationFactory<Program>>
{
    [Fact]
    public async Task Ping_echoes_client_time()
    {
        var server = factory.Server;
        await using var connection = new HubConnectionBuilder()
            .WithUrl(new Uri(server.BaseAddress, "/hubs/ping"), o => o.HttpMessageHandlerFactory = _ => server.CreateHandler())
            .Build();
        await connection.StartAsync();

        var reply = await connection.InvokeAsync<PingReply>("Ping", 42L);

        Assert.Equal(42L, reply.ClientSentAt);
        Assert.False(string.IsNullOrEmpty(reply.ConnectionId));
    }
}
