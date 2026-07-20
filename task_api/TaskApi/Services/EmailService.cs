using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Configuration;
using MimeKit;
using System.Threading.Tasks;

namespace TaskApi.Services
{
    public class EmailService : IEmailService
    {
        private readonly IConfiguration _config;

        public EmailService(IConfiguration config)
        {
            _config = config;
        }

        public async Task SendEmailAsync(string to, string subject, string htmlBody)
        {
            var emailSettings = _config.GetSection("SmtpSettings");
            var senderEmail = emailSettings["SenderEmail"] ?? "your-email@gmail.com";
            var senderName = emailSettings["SenderName"] ?? "TaskFlow App";
            var password = emailSettings["Password"] ?? "your-app-password";
            var host = emailSettings["Host"] ?? "smtp.gmail.com";
            var portString = emailSettings["Port"] ?? "587";
            
            if (!int.TryParse(portString, out int port))
            {
                port = 587;
            }

            var message = new MimeMessage();
            message.From.Add(new MailboxAddress(senderName, senderEmail));
            message.To.Add(new MailboxAddress("", to));
            message.Subject = subject;

            var bodyBuilder = new BodyBuilder { HtmlBody = htmlBody };
            message.Body = bodyBuilder.ToMessageBody();

            using var client = new SmtpClient();
            try
            {
                await client.ConnectAsync(host, port, SecureSocketOptions.StartTls);
                await client.AuthenticateAsync(senderEmail, password);
                await client.SendAsync(message);
            }
            finally
            {
                await client.DisconnectAsync(true);
            }
        }
    }
}
