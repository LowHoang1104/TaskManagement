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
                .Where(w => w.Members.Any(m => m.UserId == userId))
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
    }
}
