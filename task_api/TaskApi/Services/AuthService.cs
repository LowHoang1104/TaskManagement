using AutoMapper;
using Google.Apis.Auth;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using TaskApi.Data;
using TaskApi.DTOs;
using TaskApi.Models;

namespace TaskApi.Services
{
    public class AuthService : IAuthService
    {
        private readonly AppDbContext _context;
        private readonly IMapper _mapper;
        private readonly IConfiguration _config;
        private readonly IMemoryCache _cache;
        private readonly IEmailService _emailService;

        public AuthService(AppDbContext context, IMapper mapper, IConfiguration config, IMemoryCache cache, IEmailService emailService)
        {
            _context = context;
            _mapper = mapper;
            _config = config;
            _cache = cache;
            _emailService = emailService;
        }

        public async Task<AuthResponse?> LoginAsync(LoginRequest request)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
            
            if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            {
                return null; // Invalid credentials
            }

            var token = GenerateJwtToken(user);

            return new AuthResponse
            {
                Token = token,
                User = _mapper.Map<UserDto>(user)
            };
        }

        public async Task<AuthResponse> RegisterAsync(RegisterRequest request)
        {
            if (await _context.Users.AnyAsync(u => u.Email == request.Email))
            {
                throw new Exception("Email already exists");
            }

            var user = _mapper.Map<User>(request);
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            var token = GenerateJwtToken(user);

            return new AuthResponse
            {
                Token = token,
                User = _mapper.Map<UserDto>(user)
            };
        }

        public async Task<UserDto> UploadAvatarAsync(string userId, IFormFile avatar)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (user == null) throw new Exception("User not found");

            var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", "avatars");
            if (!Directory.Exists(uploadsFolder))
                Directory.CreateDirectory(uploadsFolder);

            var fileExtension = Path.GetExtension(avatar.FileName);
            var uniqueFileName = $"{userId}_{Guid.NewGuid()}{fileExtension}";
            var filePath = Path.Combine(uploadsFolder, uniqueFileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await avatar.CopyToAsync(stream);
            }

            user.AvatarUrl = $"/uploads/avatars/{uniqueFileName}";
            
            _context.Users.Update(user);
            await _context.SaveChangesAsync();

            return _mapper.Map<UserDto>(user);
        }

        public async Task<AuthResponse> GoogleLoginAsync(GoogleLoginRequest request)
        {
            var settings = new GoogleJsonWebSignature.ValidationSettings()
            {
                Audience = new List<string>() { _config["GoogleClientId"] ?? string.Empty }
            };

            GoogleJsonWebSignature.Payload payload;
            try
            {
                payload = await GoogleJsonWebSignature.ValidateAsync(request.IdToken, settings);
            }
            catch (Exception ex)
            {
                throw new Exception("Invalid Google Token.", ex);
            }

            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == payload.Email);
            if (user == null)
            {
                user = new User
                {
                    Id = Guid.NewGuid().ToString(),
                    Email = payload.Email,
                    FullName = payload.Name,
                    AvatarUrl = payload.Picture,
                    PasswordHash = string.Empty
                };
                _context.Users.Add(user);
                await _context.SaveChangesAsync();
            }

            var token = GenerateJwtToken(user);
            return new AuthResponse
            {
                Token = token,
                User = _mapper.Map<UserDto>(user)
            };
        }

        public async Task<bool> SendOtpAsync(SendOtpRequest request)
        {
            if (await _context.Users.AnyAsync(u => u.Email == request.Email))
            {
                throw new Exception("Email already exists");
            }

            var otp = new Random().Next(100000, 999999).ToString();
            var cacheKey = $"OTP_{request.Email}";
            
            _cache.Set(cacheKey, otp, TimeSpan.FromMinutes(5));

            string htmlBody = $@"
                <div style='font-family: Arial, sans-serif; padding: 20px; color: #333;'>
                    <h2>Verify Your Email</h2>
                    <p>Thank you for signing up for TaskFlow!</p>
                    <p>Your one-time password (OTP) is:</p>
                    <h1 style='color: #4F46E5; letter-spacing: 5px;'>{otp}</h1>
                    <p>This code will expire in 5 minutes.</p>
                </div>";

            try
            {
                await _emailService.SendEmailAsync(request.Email, "TaskFlow - Your OTP Code", htmlBody);
                Console.WriteLine($"\n[OTP] Sent real email to {request.Email} with code {otp}\n");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"\n[OTP ERROR] Failed to send email: {ex.Message}\n");
                // For development fallback if email fails, we still let them proceed using console
                Console.WriteLine($"\n[OTP FALLBACK] {otp} generated for {request.Email}\n");
            }

            return true;
        }

        public async Task<AuthResponse> VerifyOtpAndRegisterAsync(VerifyOtpRequest request)
        {
            var cacheKey = $"OTP_{request.Email}";
            if (!_cache.TryGetValue(cacheKey, out string? storedOtp) || storedOtp != request.Otp)
            {
                throw new Exception("Invalid or expired OTP.");
            }

            if (await _context.Users.AnyAsync(u => u.Email == request.Email))
            {
                throw new Exception("Email already exists");
            }

            var user = new User
            {
                Id = Guid.NewGuid().ToString(),
                FullName = request.FullName,
                Email = request.Email,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password)
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            _cache.Remove(cacheKey);

            var token = GenerateJwtToken(user);

            return new AuthResponse
            {
                Token = token,
                User = _mapper.Map<UserDto>(user)
            };
        }

        private string GenerateJwtToken(User user)
        {
            var jwtSettings = _config.GetSection("Jwt");
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings["Key"] ?? "super_secret_key_needs_to_be_long_enough_12345!"));

            var claims = new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.Id),
                new Claim(JwtRegisteredClaimNames.Email, user.Email),
                new Claim("FullName", user.FullName),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };

            var token = new JwtSecurityToken(
                issuer: jwtSettings["Issuer"] ?? "TaskApi",
                audience: jwtSettings["Audience"] ?? "TaskApiUser",
                claims: claims,
                expires: DateTime.UtcNow.AddDays(7),
                signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256)
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        public async Task<bool> SendPasswordResetOtpAsync(ForgotPasswordRequest request)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
            if (user == null)
            {
                throw new Exception("Email not found");
            }

            var otp = new Random().Next(100000, 999999).ToString();
            var cacheKey = $"RESET_OTP_{request.Email}";
            
            _cache.Set(cacheKey, otp, TimeSpan.FromMinutes(15));

            string htmlBody = $@"
                <div style='font-family: Arial, sans-serif; padding: 20px; color: #333;'>
                    <h2>Reset Your Password</h2>
                    <p>We received a request to reset your password for TaskFlow.</p>
                    <p>Your password reset code is:</p>
                    <h1 style='color: #4F46E5; letter-spacing: 5px;'>{otp}</h1>
                    <p>This code will expire in 15 minutes. If you did not request a password reset, please ignore this email.</p>
                </div>";

            try
            {
                await _emailService.SendEmailAsync(request.Email, "TaskFlow - Password Reset Code", htmlBody);
                Console.WriteLine($"\n[RESET OTP] Sent real email to {request.Email} with code {otp}\n");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"\n[RESET OTP ERROR] Failed to send email: {ex.Message}\n");
                Console.WriteLine($"\n[RESET OTP FALLBACK] {otp} generated for {request.Email}\n");
            }

            return true;
        }

        public async Task<bool> ResetPasswordAsync(ResetPasswordRequest request)
        {
            var cacheKey = $"RESET_OTP_{request.Email}";
            if (!_cache.TryGetValue(cacheKey, out string? storedOtp) || storedOtp != request.Otp)
            {
                throw new Exception("Invalid or expired OTP.");
            }

            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
            if (user == null)
            {
                throw new Exception("User not found.");
            }

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
            _context.Users.Update(user);
            await _context.SaveChangesAsync();

            _cache.Remove(cacheKey);

            return true;
        }
    }
}
