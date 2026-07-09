using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using TaskApi.Data;
using TaskApi.DTOs;

namespace TaskApi.Services
{
    public class DashboardService : IDashboardService
    {
        private readonly AppDbContext _context;

        public DashboardService(AppDbContext context)
        {
            _context = context;
        }

        public async Task<DashboardDto> GetDashboardStatsAsync(string userId)
        {
            // Find tasks where user is assigned or is the reporter
            var query = _context.Tasks
                .Where(t => t.AssigneeId == userId || t.ReporterId == userId);

            var totalDone = await query.CountAsync(t => t.Status == "Done");
            var totalOngoing = await query.CountAsync(t => t.Status != "Done");
            
            var todoCount = await query.CountAsync(t => t.Status == "To Do" || t.Status == "Todo");
            var inProgressCount = await query.CountAsync(t => t.Status == "In Progress");
            var reviewCount = await query.CountAsync(t => t.Status == "In Review" || t.Status == "Review");

            return new DashboardDto
            {
                TotalTasksDone = totalDone,
                TotalTasksOngoing = totalOngoing,
                TasksToDo = todoCount,
                TasksInProgress = inProgressCount,
                TasksReview = reviewCount
            };
        }
    }
}
