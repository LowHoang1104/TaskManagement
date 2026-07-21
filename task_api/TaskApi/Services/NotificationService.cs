using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.SignalR;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using TaskApi.Data;
using TaskApi.DTOs;
using TaskApi.Models;
using TaskApi.Hubs;

namespace TaskApi.Services
{
    public class NotificationService : INotificationService
    {
        private readonly AppDbContext _context;
        private readonly IMapper _mapper;
        private readonly IHubContext<NotificationHub> _hubContext;

        public NotificationService(AppDbContext context, IMapper mapper, IHubContext<NotificationHub> hubContext)
        {
            _context = context;
            _mapper = mapper;
            _hubContext = hubContext;
        }

        public async Task<IEnumerable<NotificationDto>> GetUserNotificationsAsync(string userId)
        {
            var notifications = await _context.Notifications
                .Where(n => n.UserId == userId)
                .OrderByDescending(n => n.CreatedAt)
                .ToListAsync();

            return _mapper.Map<IEnumerable<NotificationDto>>(notifications);
        }

        public async Task<NotificationDto> MarkAsReadAsync(string notificationId, string userId)
        {
            var notification = await _context.Notifications.FirstOrDefaultAsync(n => n.Id == notificationId && n.UserId == userId);
            if (notification == null)
            {
                throw new Exception("Notification not found.");
            }

            notification.IsRead = true;
            await _context.SaveChangesAsync();

            return _mapper.Map<NotificationDto>(notification);
        }

        public async Task CreateNotificationAsync(string userId, string type, string message, string? relatedId)
        {
            var notification = new Notification
            {
                UserId = userId,
                Type = type,
                Message = message,
                RelatedId = relatedId,
                CreatedAt = DateTime.UtcNow,
                IsRead = false
            };

            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();
            
            await _hubContext.Clients.User(userId).SendAsync("ReceiveNotification", "New Notification");
        }
    }
}
