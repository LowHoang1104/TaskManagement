using AutoMapper;
using Microsoft.EntityFrameworkCore;
using TaskApi.Data;
using TaskApi.DTOs;
using TaskApi.Models;

namespace TaskApi.Services
{
    public class WorkspaceService : IWorkspaceService
    {
        private readonly AppDbContext _context;
        private readonly IMapper _mapper;

        public WorkspaceService(AppDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public async Task<IEnumerable<WorkspaceDto>> GetWorkspacesAsync(string userId)
        {
            var workspaces = await _context.Workspaces
                .Where(w => w.Members.Any(m => m.UserId == userId) && !w.IsDeleted)
                .ToListAsync();

            return _mapper.Map<IEnumerable<WorkspaceDto>>(workspaces);
        }

        public async Task<WorkspaceDto> CreateWorkspaceAsync(string userId, WorkspaceCreateDto request)
        {
            var workspace = _mapper.Map<Workspace>(request);
            workspace.OwnerId = userId;

            // Add owner as a member
            workspace.Members.Add(new WorkspaceMember
            {
                UserId = userId,
                Role = "Owner"
            });

            _context.Workspaces.Add(workspace);
            await _context.SaveChangesAsync();

            return _mapper.Map<WorkspaceDto>(workspace);
        }

        public async Task DeleteWorkspaceAsync(string id, string actorId)
        {
            var workspace = await _context.Workspaces.FindAsync(id);
            if (workspace == null || workspace.IsDeleted)
            {
                throw new Exception("Workspace not found");
            }

            if (workspace.OwnerId != actorId)
            {
                throw new UnauthorizedAccessException("Only the workspace owner can delete the workspace.");
            }

            workspace.IsDeleted = true;
            workspace.UpdatedAt = DateTime.UtcNow;
            
            await _context.SaveChangesAsync();
        }
    }
}
