using System.Collections.Generic;
using System.Threading.Tasks;
using TaskApi.DTOs;

namespace TaskApi.Services
{
    public interface ICommentService
    {
        Task<IEnumerable<CommentDto>> GetCommentsAsync(string taskId);
        Task<CommentDto> CreateCommentAsync(string taskId, string userId, CommentCreateDto request);
    }
}
