namespace TaskApi.DTOs
{
    public class DashboardDto
    {
        public int TotalTasksDone { get; set; }      // all-time completed
        public int TasksDoneThisWeek { get; set; }   // completed since Monday
        public int TotalTasksOngoing { get; set; }
        public int TasksToDo { get; set; }
        public int TasksInProgress { get; set; }
        public int TasksReview { get; set; }
    }
}
