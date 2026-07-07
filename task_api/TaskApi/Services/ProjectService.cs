using AutoMapper;
using Microsoft.EntityFrameworkCore;
using TaskApi.Data;
using TaskApi.DTOs;
using TaskApi.Models;

namespace TaskApi.Services
{
    public class ProjectService : IProjectService
    {
        private readonly AppDbContext _context;
        private readonly IMapper _mapper;

        public ProjectService(AppDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public async Task<IEnumerable<ProjectDto>> GetProjectsAsync(string workspaceId)
        {
            var projects = await _context.Projects
                .Where(p => p.WorkspaceId == workspaceId)
                .ToListAsync();

            return _mapper.Map<IEnumerable<ProjectDto>>(projects);
        }

        public async Task<ProjectDto> CreateProjectAsync(string workspaceId, ProjectCreateDto request)
        {
            var project = _mapper.Map<Project>(request);
            project.WorkspaceId = workspaceId;

            _context.Projects.Add(project);
            await _context.SaveChangesAsync();

            return _mapper.Map<ProjectDto>(project);
        }
    }
}
