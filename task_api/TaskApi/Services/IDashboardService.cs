using System.Threading.Tasks;
using TaskApi.DTOs;

namespace TaskApi.Services
{
    public interface IDashboardService
    {
        Task<DashboardDto> GetDashboardStatsAsync(string userId);
    }
}
