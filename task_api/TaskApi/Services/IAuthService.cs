using Microsoft.AspNetCore.Http;
using TaskApi.DTOs;

namespace TaskApi.Services
{
    public interface IAuthService
    {
        Task<AuthResponse?> LoginAsync(LoginRequest request);
        Task<AuthResponse> RegisterAsync(RegisterRequest request);
        Task<UserDto> UploadAvatarAsync(string userId, IFormFile avatar);
    }
}
