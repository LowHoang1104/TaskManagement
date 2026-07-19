using Microsoft.AspNetCore.SignalR;
using System.Threading.Tasks;

namespace TaskApi.Hubs
{
    // TODO: Uncomment [Authorize] once the frontend passes the JWT token.
    // [Authorize]
    public class NotificationHub : Hub
    {
        public async Task SendNotificationToUser(string userId, string message)
        {
            // In production, map userId to its ConnectionId; for now this
            // broadcasts to all connected clients as a placeholder.
            await Clients.All.SendAsync("ReceiveNotification", message);
        }

        public override Task OnConnectedAsync()
        {
            // var userId = Context.UserIdentifier;
            return base.OnConnectedAsync();
        }
    }
}
