using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using System.Threading.Tasks;
using TaskApi.DTOs;
using TaskApi.Services;

namespace TaskApi.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/tasks/{taskId}/[controller]")]
    public class CommentsController : ControllerBase
    {
        private readonly ICommentService _commentService;

        public CommentsController(ICommentService commentService)
        {
            _commentService = commentService;
        }

        private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier)!;

        [HttpGet]
        public async Task<IActionResult> GetComments(string taskId)
        {
            var comments = await _commentService.GetCommentsAsync(taskId);
            return Ok(comments);
        }

        [HttpPost]
        public async Task<IActionResult> CreateComment(string taskId, CommentCreateDto request)
        {
            var comment = await _commentService.CreateCommentAsync(taskId, GetUserId(), request);
            return CreatedAtAction(nameof(GetComments), new { taskId = taskId, id = comment.Id }, comment);
        }
    }
}
