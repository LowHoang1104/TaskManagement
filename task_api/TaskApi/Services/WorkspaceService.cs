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
        private readonly INotificationService _notificationService;

        public WorkspaceService(AppDbContext context, IMapper mapper, INotificationService notificationService)
        {
            _context = context;
            _mapper = mapper;
            _notificationService = notificationService;
        }

        public async Task<IEnumerable<WorkspaceDto>> GetWorkspacesAsync(string userId)
        {
            // Only workspaces the user has actually accepted an invite to.
            var workspaces = await _context.Workspaces
                .Where(w => w.Members.Any(m => m.UserId == userId && m.Status == "Accepted")
                            && !w.IsDeleted)
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
                Role = "Owner",
                Status = "Accepted", // the creator is in by definition
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

        public async Task<IEnumerable<WorkspaceMemberDto>> GetWorkspaceMembersAsync(string workspaceId, string actorId)
        {
            var workspace = await _context.Workspaces
                .Include(w => w.Members)
                .ThenInclude(m => m.User)
                .FirstOrDefaultAsync(w => w.Id == workspaceId);

            if (workspace == null || workspace.IsDeleted)
            {
                throw new Exception("Workspace not found");
            }

            if (!workspace.Members.Any(m => m.UserId == actorId && m.Status == "Accepted")
                && workspace.OwnerId != actorId)
            {
                throw new UnauthorizedAccessException("You are not a member of this workspace.");
            }

            return workspace.Members.Select(m => new WorkspaceMemberDto
            {
                Id = m.User.Id,
                Email = m.User.Email,
                FullName = m.User.FullName,
                AvatarUrl = m.User.AvatarUrl,
                Role = m.Role,
                Status = m.Status,
                JoinedAt = m.JoinedAt
            }).ToList();
        }

        public async Task<WorkspaceMemberDto> InviteWorkspaceMemberAsync(string workspaceId, string email, string actorId)
        {
            var workspace = await _context.Workspaces
                .Include(w => w.Members)
                .FirstOrDefaultAsync(w => w.Id == workspaceId);

            if (workspace == null || workspace.IsDeleted)
            {
                throw new Exception("Workspace not found");
            }

            var actorMember = workspace.Members
                .FirstOrDefault(m => m.UserId == actorId && m.Status == "Accepted");
            if (actorMember == null || actorMember.Role != "Owner")
            {
                throw new UnauthorizedAccessException("Only Owners can invite members to the workspace.");
            }

            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
            if (user == null)
            {
                throw new Exception("User not found");
            }

            var existing = workspace.Members.FirstOrDefault(m => m.UserId == user.Id);
            if (existing != null)
            {
                throw new Exception(existing.Status == "Pending"
                    ? "This user already has a pending invite."
                    : "User is already a member of this workspace");
            }

            // Invite-based: the user only joins once they accept.
            var newMember = new WorkspaceMember
            {
                WorkspaceId = workspaceId,
                UserId = user.Id,
                Role = "Member",
                Status = "Pending",
                JoinedAt = DateTime.UtcNow
            };

            workspace.Members.Add(newMember);
            await _context.SaveChangesAsync();

            var actorUser = await _context.Users.FindAsync(actorId);

            // Type "Invite" → the app renders Accept / Decline actions.
            await _notificationService.CreateNotificationAsync(
                userId: user.Id,
                type: "Invite",
                message: $"{actorUser?.FullName ?? "Someone"} invited you to workspace '{workspace.Name}'",
                relatedId: workspace.Id
            );

            return new WorkspaceMemberDto
            {
                Id = user.Id,
                Email = user.Email,
                FullName = user.FullName,
                AvatarUrl = user.AvatarUrl,
                Role = newMember.Role,
                Status = newMember.Status,
                JoinedAt = newMember.JoinedAt
            };
        }

        public async Task<WorkspaceMemberDto> AcceptWorkspaceInvitationAsync(string workspaceId, string userId)
        {
            var member = await _context.Set<WorkspaceMember>()
                .Include(m => m.User)
                .FirstOrDefaultAsync(m => m.WorkspaceId == workspaceId && m.UserId == userId);

            if (member == null) throw new Exception("Invitation not found");
            if (member.Status == "Accepted") throw new Exception("You already joined this workspace.");

            member.Status = "Accepted";
            member.JoinedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return new WorkspaceMemberDto
            {
                Id = member.User.Id,
                Email = member.User.Email,
                FullName = member.User.FullName,
                AvatarUrl = member.User.AvatarUrl,
                Role = member.Role,
                Status = member.Status,
                JoinedAt = member.JoinedAt
            };
        }

        public async Task<bool> DeclineWorkspaceInvitationAsync(string workspaceId, string userId)
        {
            var member = await _context.Set<WorkspaceMember>()
                .FirstOrDefaultAsync(m => m.WorkspaceId == workspaceId && m.UserId == userId);

            if (member == null) throw new Exception("Invitation not found");
            if (member.Status != "Pending")
            {
                throw new Exception("Only pending invitations can be declined.");
            }

            _context.Set<WorkspaceMember>().Remove(member);
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<WorkspaceMemberDto> UpdateWorkspaceMemberRoleAsync(string workspaceId, string userId, string newRole, string actorId)
        {
            var workspace = await _context.Workspaces.FindAsync(workspaceId);
            if (workspace == null || workspace.IsDeleted) throw new Exception("Workspace not found");

            if (workspace.OwnerId != actorId)
            {
                throw new UnauthorizedAccessException("Only the workspace owner can change roles.");
            }

            var member = await _context.Set<WorkspaceMember>()
                .Include(m => m.User)
                .FirstOrDefaultAsync(m => m.WorkspaceId == workspaceId && m.UserId == userId);

            if (member == null) throw new Exception("Member not found in workspace");

            if (workspace.OwnerId == userId)
            {
                throw new InvalidOperationException("Cannot change the role of the workspace owner.");
            }

            member.Role = newRole;
            await _context.SaveChangesAsync();

            return new WorkspaceMemberDto
            {
                Id = member.User.Id,
                Email = member.User.Email,
                FullName = member.User.FullName,
                AvatarUrl = member.User.AvatarUrl,
                Role = member.Role,
                JoinedAt = member.JoinedAt
            };
        }

        public async Task<bool> RemoveWorkspaceMemberAsync(string workspaceId, string userId, string actorId)
        {
            var workspace = await _context.Workspaces.FindAsync(workspaceId);
            if (workspace == null || workspace.IsDeleted) throw new Exception("Workspace not found");

            if (workspace.OwnerId != actorId && userId != actorId)
            {
                throw new UnauthorizedAccessException("Only the workspace owner can remove other members.");
            }

            if (workspace.OwnerId == userId)
            {
                throw new InvalidOperationException("Cannot remove the workspace owner.");
            }

            var member = await _context.Set<WorkspaceMember>()
                .FirstOrDefaultAsync(m => m.WorkspaceId == workspaceId && m.UserId == userId);

            if (member == null) throw new Exception("Member not found in workspace");

            _context.Set<WorkspaceMember>().Remove(member);

            // Also remove them from any projects in this workspace
            var projectMemberships = await _context.Set<ProjectMember>()
                .Include(pm => pm.Project)
                .Where(pm => pm.Project.WorkspaceId == workspaceId && pm.UserId == userId)
                .ToListAsync();
            
            _context.Set<ProjectMember>().RemoveRange(projectMemberships);

            await _context.SaveChangesAsync();
            return true;
        }
    }
}
