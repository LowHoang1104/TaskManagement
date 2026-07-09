using Microsoft.AspNetCore.SignalR;
using System.Threading.Tasks;

namespace TaskApi.Hubs
{
    // TODO: Bỏ comment [Authorize] sau khi Frontend hoàn thành việc truyền JWT Token
    // [Authorize]
    public class NotificationHub : Hub
    {
        public async Task SendNotificationToUser(string userId, string message)
        {
            // Trong thực tế, bạn cần mapping từ userId sang ConnectionId
            // Ở đây gửi tạm một hàm mô phỏng tới tất cả client
            await Clients.All.SendAsync("ReceiveNotification", message);
        }

        public override Task OnConnectedAsync()
        {
            // var userId = Context.UserIdentifier;
            return base.OnConnectedAsync();
        }
    }
}
