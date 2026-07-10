using AutoMapper;
using TaskApi.Models;

namespace TaskApi.DTOs
{
    public class MappingProfile : Profile
    {
        public MappingProfile()
        {
            // User mappings
            CreateMap<User, UserDto>();
            CreateMap<RegisterRequest, User>();

            // Workspace mappings
            CreateMap<Workspace, WorkspaceDto>();
            CreateMap<WorkspaceCreateDto, Workspace>();

            // Project mappings
            CreateMap<Project, ProjectDto>();
            CreateMap<ProjectCreateDto, Project>();

            // Task mappings
            CreateMap<TaskItem, TaskDto>()
                .ForMember(dest => dest.AssigneeName, opt => opt.MapFrom(src => src.Assignee != null ? src.Assignee.FullName : null))
                .ForMember(dest => dest.ReporterName, opt => opt.MapFrom(src => src.Reporter != null ? src.Reporter.FullName : null));
            CreateMap<TaskItem, TaskUpdateDto>().ReverseMap();
            
            CreateMap<TaskDependency, TaskDependencyDto>()
                .ForMember(dest => dest.PredecessorTaskTitle, opt => opt.MapFrom(src => src.PredecessorTask != null ? src.PredecessorTask.Title : ""));
            CreateMap<TaskCreateDto, TaskItem>();
            CreateMap<TaskUpdateDto, TaskItem>()
                .ForAllMembers(opts => opts.Condition((src, dest, srcMember) => srcMember != null)); // Ignore null values on update

            // Comment mappings
            CreateMap<Comment, CommentDto>()
                .ForMember(dest => dest.UserFullName, opt => opt.MapFrom(src => src.User.FullName))
                .ForMember(dest => dest.UserAvatarUrl, opt => opt.MapFrom(src => src.User.AvatarUrl));
            CreateMap<CommentCreateDto, Comment>();

            // Notification mappings
            CreateMap<Notification, NotificationDto>();

            // Attachment mappings
            CreateMap<Attachment, AttachmentDto>()
                .ForMember(dest => dest.UploaderFullName, opt => opt.MapFrom(src => src.UploadedBy.FullName));
        }
    }
}
