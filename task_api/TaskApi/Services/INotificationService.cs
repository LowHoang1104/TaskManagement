using System.Collections.Generic;
using System.Threading.Tasks;
using TaskApi.DTOs;

namespace TaskApi.Services
{
    public interface INotificationService
    {
        Task<IEnumerable<NotificationDto>> GetUserNotificationsAsync(string userId);
        Task<NotificationDto> MarkAsReadAsync(string notificationId, string userId);
        Task CreateNotificationAsync(string userId, string type, string message, string? relatedId);
    }
}
