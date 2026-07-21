using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.SignalR;
using TaskApi.Data;
using TaskApi.DTOs;
using TaskApi.Models;
using TaskApi.Hubs;

namespace TaskApi.Services
{
    public class ProjectService : IProjectService
    {
        private readonly AppDbContext _context;
        private readonly IMapper _mapper;
        private readonly INotificationService _notificationService;
        private readonly IHubContext<NotificationHub> _hubContext;

        public ProjectService(AppDbContext context, IMapper mapper, INotificationService notificationService, IHubContext<NotificationHub> hubContext)
        {
            _context = context;
            _mapper = mapper;
            _notificationService = notificationService;
            _hubContext = hubContext;
        }

        public async Task<IEnumerable<ProjectDto>> GetProjectsAsync(string workspaceId, string userId)
        {
            var workspace = await _context.Workspaces.FindAsync(workspaceId);
            if (workspace == null)
            {
                throw new Exception("Workspace not found");
            }
            bool isWorkspaceOwner = workspace.OwnerId == userId;

            var query = _context.Projects
                .Include(p => p.Tasks)
                .Include(p => p.Members)
                .Where(p => p.WorkspaceId == workspaceId);

            if (!isWorkspaceOwner)
            {
                query = query.Where(p => p.Members.Any(m => m.UserId == userId));
            }

            var projects = await query.ToListAsync();

            var projectDtos = _mapper.Map<List<ProjectDto>>(projects);
            
            // Task counts + progress for each project
            foreach (var dto in projectDtos)
            {
                var proj = projects.First(p => p.Id == dto.Id);
                int totalTasks = proj.Tasks.Count;
                int doneTasks = proj.Tasks.Count(t => t.Status.Equals("done", StringComparison.OrdinalIgnoreCase));

                dto.TaskCount = totalTasks;
                dto.DoneTaskCount = doneTasks;
                dto.Progress = totalTasks == 0
                    ? 0
                    : (int)Math.Round((double)doneTasks / totalTasks * 100);
            }

            return projectDtos;
        }

        public async Task<ProjectDto> CreateProjectAsync(string workspaceId, string userId, ProjectCreateDto request)
        {
            var workspaceMember = await _context.Set<WorkspaceMember>()
                .FirstOrDefaultAsync(m => m.WorkspaceId == workspaceId && m.UserId == userId);

            if (workspaceMember == null || workspaceMember.Role != "Owner")
            {
                throw new UnauthorizedAccessException("Only the workspace owner can create projects.");
            }

            var project = _mapper.Map<Project>(request);
            project.WorkspaceId = workspaceId;

            _context.Projects.Add(project);
            await _context.SaveChangesAsync();

            // The creator becomes the owner/leader
            var ownerMember = new ProjectMember
            {
                ProjectId = project.Id,
                UserId = userId,
                Role = "Owner",
                JoinedAt = DateTime.UtcNow
            };
            
            _context.Set<ProjectMember>().Add(ownerMember);
            await _context.SaveChangesAsync();
            
            await _hubContext.Clients.All.SendAsync("RefreshWorkspace", workspaceId);

            return _mapper.Map<ProjectDto>(project);
        }

        public async Task DeleteProjectAsync(string id, string actorId)
        {
            var project = await _context.Projects.FindAsync(id);
            if (project == null)
            {
                throw new Exception("Project not found");
            }

            var workspaceMember = await _context.Set<WorkspaceMember>()
                .FirstOrDefaultAsync(m => m.WorkspaceId == project.WorkspaceId && m.UserId == actorId);

            if (workspaceMember == null || workspaceMember.Role != "Owner")
            {
                throw new UnauthorizedAccessException("Only the workspace owner can delete the project.");
            }

            var workspaceId = project.WorkspaceId;
            _context.Projects.Remove(project);
            await _context.SaveChangesAsync();
            
            await _hubContext.Clients.All.SendAsync("RefreshWorkspace", workspaceId);
        }

        public async Task<IEnumerable<ProjectMemberDto>> GetProjectMembersAsync(string projectId)
        {
            var project = await _context.Projects
                .Include(p => p.Members)
                .ThenInclude(m => m.User)
                .FirstOrDefaultAsync(p => p.Id == projectId);

            if (project == null)
            {
                throw new Exception("Project not found");
            }

            var members = project.Members.Select(m => new ProjectMemberDto
            {
                Id = m.User.Id,
                Email = m.User.Email,
                FullName = m.User.FullName,
                AvatarUrl = m.User.AvatarUrl,
                Role = m.Role,
                Status = m.Status,
                JoinedAt = m.JoinedAt
            }).ToList();

            return members;
        }

        public async Task<ProjectMemberDto> AddProjectMemberAsync(string projectId, string email, string actorId)
        {
            var project = await _context.Projects
                .Include(p => p.Members)
                .Include(p => p.Workspace)
                .FirstOrDefaultAsync(p => p.Id == projectId);

            if (project == null)
            {
                throw new Exception("Project not found");
            }

            bool isWorkspaceOwner = project.Workspace.OwnerId == actorId;
            var actorMember = await _context.Set<ProjectMember>().FirstOrDefaultAsync(m => m.ProjectId == projectId && m.UserId == actorId);
            bool isProjectAdmin = actorMember != null && (actorMember.Role == "Owner" || actorMember.Role == "Admin");

            if (!isWorkspaceOwner && !isProjectAdmin)
            {
                throw new UnauthorizedAccessException("Only Project Admins/Owners or Workspace Owners can invite members.");
            }

            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
            if (user == null)
            {
                throw new Exception("User not found");
            }

            if (project.Members.Any(m => m.UserId == user.Id))
            {
                throw new Exception("User is already a member of this project");
            }

            // Must have actually joined the workspace (a pending invite doesn't count).
            var isWorkspaceMember = await _context.Set<WorkspaceMember>()
                .AnyAsync(wm => wm.WorkspaceId == project.WorkspaceId
                                && wm.UserId == user.Id
                                && wm.Status == "Accepted");

            if (!isWorkspaceMember && user.Id != project.Workspace.OwnerId)
            {
                throw new UnauthorizedAccessException("This user is not a member of the workspace.");
            }

            var newMember = new ProjectMember
            {
                ProjectId = projectId,
                UserId = user.Id,
                Role = "Member",
                Status = "Accepted",
                JoinedAt = DateTime.UtcNow
            };

            project.Members.Add(newMember);
            await _context.SaveChangesAsync();

            var actorUser = await _context.Users.FindAsync(actorId);

            await _notificationService.CreateNotificationAsync(
                userId: user.Id,
                type: "Project",
                message: $"You have been added to project '{project.Name}' by {actorUser?.FullName ?? "someone"}",
                relatedId: project.Id
            );
            
            await _hubContext.Clients.All.SendAsync("ReceiveNotification", "New Project Invite");
            await _hubContext.Clients.All.SendAsync("RefreshWorkspace", project.WorkspaceId);

            return new ProjectMemberDto
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

        public async Task<ProjectMemberDto> UpdateProjectMemberRoleAsync(string projectId, string userId, string newRole, string actorId)
        {
            var actor = await _context.Set<ProjectMember>().FirstOrDefaultAsync(m => m.ProjectId == projectId && m.UserId == actorId);
            if (actor == null || actor.Role != "Owner")
            {
                throw new UnauthorizedAccessException("Only Owners can change roles.");
            }

            var member = await _context.Set<ProjectMember>()
                .Include(m => m.User)
                .FirstOrDefaultAsync(m => m.ProjectId == projectId && m.UserId == userId);

            if (member == null)
            {
                throw new Exception("Member not found in project");
            }

            if (member.Role == "Owner" && newRole != "Owner")
            {
                var ownerCount = await _context.Set<ProjectMember>().CountAsync(m => m.ProjectId == projectId && m.Role == "Owner");
                if (ownerCount <= 1)
                {
                    throw new InvalidOperationException("Cannot demote the last Owner of the project.");
                }
            }

            member.Role = newRole;
            await _context.SaveChangesAsync();
            
            var project = await _context.Projects.FindAsync(projectId);
            if (project != null)
            {
                await _hubContext.Clients.All.SendAsync("RefreshWorkspace", project.WorkspaceId);
            }

            return new ProjectMemberDto
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

        public async Task<ProjectMemberDto> AcceptProjectInvitationAsync(string projectId, string userId)
        {
            var member = await _context.Set<ProjectMember>()
                .Include(m => m.User)
                .FirstOrDefaultAsync(m => m.ProjectId == projectId && m.UserId == userId);

            if (member == null)
            {
                throw new Exception("Invitation not found");
            }

            member.Status = "Accepted";
            await _context.SaveChangesAsync();
            
            var project = await _context.Projects.FindAsync(projectId);
            if (project != null)
            {
                await _hubContext.Clients.All.SendAsync("RefreshWorkspace", project.WorkspaceId);
            }

            return new ProjectMemberDto
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

        public async Task<bool> DeclineProjectInvitationAsync(string projectId, string actorId)
        {
            var member = await _context.Set<ProjectMember>()
                .FirstOrDefaultAsync(pm => pm.ProjectId == projectId && pm.UserId == actorId);

            if (member == null)
            {
                throw new Exception("You are not a member of this project or invitation not found.");
            }

            if (member.Status != "Pending")
            {
                throw new Exception("Only pending invitations can be declined.");
            }

            _context.Set<ProjectMember>().Remove(member);
            await _context.SaveChangesAsync();
            
            var project = await _context.Projects.FindAsync(projectId);
            if (project != null)
            {
                await _hubContext.Clients.All.SendAsync("RefreshWorkspace", project.WorkspaceId);
            }

            return true;
        }

        public async Task<bool> LeaveProjectAsync(string projectId, string actorId)
        {
            var project = await _context.Projects.FindAsync(projectId);
            if (project == null) throw new Exception("Project not found");

            var member = await _context.Set<ProjectMember>()
                .FirstOrDefaultAsync(pm => pm.ProjectId == projectId && pm.UserId == actorId);

            if (member == null || member.Status != "Accepted")
            {
                throw new Exception("You are not an active member of this project.");
            }

            // Cannot leave if you are the only owner
            if (member.Role == "Owner")
            {
                var ownerCount = await _context.Set<ProjectMember>().CountAsync(m => m.ProjectId == projectId && m.Role == "Owner");
                if (ownerCount <= 1)
                {
                    throw new InvalidOperationException("Cannot leave the project because you are the only Owner.");
                }
            }

            _context.Set<ProjectMember>().Remove(member);
            
            // Check if user is in any other project in the same workspace
            var isInOtherProjects = await _context.Set<ProjectMember>()
                .Include(m => m.Project)
                .AnyAsync(m => m.UserId == actorId && m.Project.WorkspaceId == project.WorkspaceId && m.ProjectId != projectId);

            if (!isInOtherProjects)
            {
                var workspaceMember = await _context.Set<WorkspaceMember>()
                    .FirstOrDefaultAsync(wm => wm.WorkspaceId == project.WorkspaceId && wm.UserId == actorId);
                
                if (workspaceMember != null)
                {
                    _context.Set<WorkspaceMember>().Remove(workspaceMember);
                }
            }

            await _context.SaveChangesAsync();
            
            await _hubContext.Clients.All.SendAsync("RefreshWorkspace", project.WorkspaceId);
            
            return true;
        }

        public async Task<bool> RemoveProjectMemberAsync(string projectId, string userId, string actorId)
        {
            var project = await _context.Projects.FindAsync(projectId);
            if (project == null) throw new Exception("Project not found");

            var actorMember = await _context.Set<ProjectMember>().FirstOrDefaultAsync(m => m.ProjectId == projectId && m.UserId == actorId);
            bool isWorkspaceOwner = false; // We can check if needed, but project Admin/Owner is sufficient
            
            // Allow if actor is project Admin/Owner
            if (actorMember == null || (actorMember.Role != "Owner" && actorMember.Role != "Admin"))
            {
                var workspace = await _context.Workspaces.FindAsync(project.WorkspaceId);
                if (workspace?.OwnerId != actorId)
                {
                    throw new UnauthorizedAccessException("Only Project Admins/Owners or Workspace Owners can remove members.");
                }
                isWorkspaceOwner = true;
            }

            var targetMember = await _context.Set<ProjectMember>().FirstOrDefaultAsync(m => m.ProjectId == projectId && m.UserId == userId);
            if (targetMember == null) throw new Exception("Member not found in project");

            if (targetMember.Role == "Owner" && !isWorkspaceOwner && actorMember?.Role != "Owner")
            {
                throw new UnauthorizedAccessException("Only the Workspace Owner or another Project Owner can remove a Project Owner.");
            }

            if (targetMember.Role == "Owner")
            {
                var ownerCount = await _context.Set<ProjectMember>().CountAsync(m => m.ProjectId == projectId && m.Role == "Owner");
                if (ownerCount <= 1)
                {
                    throw new InvalidOperationException("Cannot remove the only Owner of the project.");
                }
            }

            _context.Set<ProjectMember>().Remove(targetMember);
            await _context.SaveChangesAsync();
            
            await _hubContext.Clients.All.SendAsync("RefreshWorkspace", project.WorkspaceId);
            
            return true;
        }
    }
}
