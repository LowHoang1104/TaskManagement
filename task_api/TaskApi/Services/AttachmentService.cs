using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using TaskApi.Data;
using TaskApi.DTOs;
using TaskApi.Models;

namespace TaskApi.Services
{
    public class AttachmentService : IAttachmentService
    {
        private readonly AppDbContext _context;
        private readonly IMapper _mapper;

        public AttachmentService(AppDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public async Task<IEnumerable<AttachmentDto>> GetAttachmentsAsync(string taskId)
        {
            var attachments = await _context.Attachments
                .Include(a => a.UploadedBy)
                .Where(a => a.TaskId == taskId)
                .OrderByDescending(a => a.UploadedAt)
                .ToListAsync();

            return _mapper.Map<IEnumerable<AttachmentDto>>(attachments);
        }

        public async Task<AttachmentDto> UploadAttachmentAsync(string taskId, string userId, IFormFile file, string webRootPath, string requestScheme, string requestHost)
        {
            if (file == null || file.Length == 0)
                throw new ArgumentException("File is empty.");

            // Create uploads directory if not exists
            var uploadsFolder = Path.Combine(webRootPath, "uploads");
            if (!Directory.Exists(uploadsFolder))
            {
                Directory.CreateDirectory(uploadsFolder);
            }

            // Generate unique filename
            var uniqueFileName = $"{Guid.NewGuid()}_{file.FileName}";
            var filePath = Path.Combine(uploadsFolder, uniqueFileName);

            // Save file
            using (var fileStream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(fileStream);
            }

            // Construct file URL
            var fileUrl = $"{requestScheme}://{requestHost}/uploads/{uniqueFileName}";

            var attachment = new Attachment
            {
                TaskId = taskId,
                FileName = file.FileName,
                FileUrl = fileUrl,
                FileSize = (int)file.Length,
                UploadedById = userId,
                UploadedAt = DateTime.UtcNow
            };

            _context.Attachments.Add(attachment);
            await _context.SaveChangesAsync();

            await _context.Entry(attachment).Reference(a => a.UploadedBy).LoadAsync();

            return _mapper.Map<AttachmentDto>(attachment);
        }

        /// <summary>
        /// Removes an attachment (row + the file on disk). Allowed for the
        /// uploader, or a project Owner/Admin.
        /// </summary>
        public async Task<bool> DeleteAttachmentAsync(string attachmentId, string userId, string webRootPath)
        {
            var attachment = await _context.Attachments
                .Include(a => a.Task)
                .FirstOrDefaultAsync(a => a.Id == attachmentId);

            if (attachment == null) throw new Exception("Attachment not found");

            if (attachment.UploadedById != userId)
            {
                var member = await _context.Set<ProjectMember>().FirstOrDefaultAsync(
                    m => m.ProjectId == attachment.Task.ProjectId && m.UserId == userId);

                if (member == null || (member.Role != "Owner" && member.Role != "Admin"))
                {
                    throw new UnauthorizedAccessException(
                        "Only the uploader or a project Owner/Admin can delete this file.");
                }
            }

            // Best-effort removal of the stored file; the row goes regardless.
            try
            {
                var fileName = Path.GetFileName(new Uri(attachment.FileUrl).LocalPath);
                var filePath = Path.Combine(webRootPath, "uploads", fileName);
                if (File.Exists(filePath)) File.Delete(filePath);
            }
            catch
            {
                // Ignore: a missing/unparsable file must not block deleting the record.
            }

            _context.Attachments.Remove(attachment);
            await _context.SaveChangesAsync();
            return true;
        }
    }
}
