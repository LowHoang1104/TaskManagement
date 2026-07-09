using AutoMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using TaskApi.Data;
using TaskApi.DTOs;
using TaskApi.Models;

namespace TaskApi.Services
{
    public class CommentService : ICommentService
    {
        private readonly AppDbContext _context;
        private readonly IMapper _mapper;
        private readonly INotificationService _notificationService;

        public CommentService(AppDbContext context, IMapper mapper, INotificationService notificationService)
        {
            _context = context;
            _mapper = mapper;
            _notificationService = notificationService;
        }

        public async Task<IEnumerable<CommentDto>> GetCommentsAsync(string taskId)
        {
            var comments = await _context.Comments
                .Include(c => c.User)
                .Where(c => c.TaskId == taskId)
                .OrderByDescending(c => c.CreatedAt) // Newest first
                .ToListAsync();

            return _mapper.Map<IEnumerable<CommentDto>>(comments);
        }

        public async Task<CommentDto> CreateCommentAsync(string taskId, string userId, CommentCreateDto request)
        {
            var comment = _mapper.Map<Comment>(request);
            comment.TaskId = taskId;
            comment.UserId = userId;
            comment.CreatedAt = DateTime.UtcNow;
            comment.UpdatedAt = DateTime.UtcNow;

            _context.Comments.Add(comment);
            await _context.SaveChangesAsync();

            // Load user data for the return DTO
            await _context.Entry(comment).Reference(c => c.User).LoadAsync();

            var task = await _context.Tasks.FirstOrDefaultAsync(t => t.Id == taskId);
            if (task != null && !string.IsNullOrEmpty(task.AssigneeId) && task.AssigneeId != userId)
            {
                await _notificationService.CreateNotificationAsync(
                    userId: task.AssigneeId,
                    type: "Comment",
                    message: $"{comment.User?.FullName ?? "Someone"} commented on task '{task.Title}'",
                    relatedId: taskId
                );
            }

            return _mapper.Map<CommentDto>(comment);
        }
    }
}
