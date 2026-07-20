using Microsoft.AspNetCore.Http;
using TaskApi.DTOs;

namespace TaskApi.Services
{
    public interface IAuthService
    {
        Task<AuthResponse?> LoginAsync(LoginRequest request);
        Task<AuthResponse> RegisterAsync(RegisterRequest request);
        Task<UserDto> UploadAvatarAsync(string userId, IFormFile avatar);
        Task<AuthResponse> GoogleLoginAsync(GoogleLoginRequest request);
        Task<bool> SendOtpAsync(SendOtpRequest request);
        Task<AuthResponse> VerifyOtpAndRegisterAsync(VerifyOtpRequest request);
        Task<bool> SendPasswordResetOtpAsync(ForgotPasswordRequest request);
        Task<bool> ResetPasswordAsync(ResetPasswordRequest request);
    }
}
