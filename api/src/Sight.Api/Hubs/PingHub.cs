using Microsoft.AspNetCore.SignalR;

namespace Sight.Api.Hubs;

/// <summary>
/// Diagnostics hub used to verify that real-time connections survive on the hosting platform.
/// The client calls Ping and gets the server time back.
/// </summary>
public class PingHub : Hub
{
    public PingReply Ping(long clientSentAt) => new(clientSentAt, DateTimeOffset.UtcNow.ToUnixTimeMilliseconds(), Context.ConnectionId);
}

public record PingReply(long ClientSentAt, long ServerTime, string ConnectionId);
