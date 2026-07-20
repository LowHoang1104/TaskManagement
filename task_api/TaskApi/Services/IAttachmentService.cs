using Microsoft.AspNetCore.Http;
using System.Collections.Generic;
using System.Threading.Tasks;
using TaskApi.DTOs;

namespace TaskApi.Services
{
    public interface IAttachmentService
    {
        Task<IEnumerable<AttachmentDto>> GetAttachmentsAsync(string taskId);
        Task<AttachmentDto> UploadAttachmentAsync(string taskId, string userId, IFormFile file, string webRootPath, string requestScheme, string requestHost);
        Task<bool> DeleteAttachmentAsync(string attachmentId, string userId, string webRootPath);
    }
}
