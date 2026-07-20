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
            // Only tasks actually assigned to this user — the dashboard reflects
            // "my own workload", not tasks the user merely reported for others.
            var query = _context.Tasks
                .Where(t => t.AssigneeId == userId);

            // The app stores statuses as its canonical enum names (todo/doing/
            // review/done). Match those, but stay tolerant of older label variants.
            // (SQL Server's default collation makes these comparisons case-insensitive.)
            var totalDone = await query.CountAsync(t => t.Status == "done");
            var totalOngoing = await query.CountAsync(t => t.Status != "done");

            // "This week" = from Monday 00:00 (UTC) of the current week onward,
            // based on when each task was actually completed.
            var now = DateTime.UtcNow;
            var startOfWeek = now.Date.AddDays(-(((int)now.DayOfWeek + 6) % 7));
            var doneThisWeek = await query.CountAsync(
                t => t.Status == "done" &&
                     t.CompletedAt != null &&
                     t.CompletedAt >= startOfWeek);

            var todoCount = await query.CountAsync(t => t.Status == "todo" || t.Status == "To Do");
            var inProgressCount = await query.CountAsync(t => t.Status == "doing" || t.Status == "In Progress" || t.Status == "InProgress");
            var reviewCount = await query.CountAsync(t => t.Status == "review" || t.Status == "In Review");

            return new DashboardDto
            {
                TotalTasksDone = totalDone,
                TasksDoneThisWeek = doneThisWeek,
                TotalTasksOngoing = totalOngoing,
                TasksToDo = todoCount,
                TasksInProgress = inProgressCount,
                TasksReview = reviewCount
            };
        }
    }
}
