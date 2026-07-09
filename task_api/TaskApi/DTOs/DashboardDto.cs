namespace TaskApi.DTOs
{
    public class DashboardDto
    {
        public int TotalTasksDone { get; set; }
        public int TotalTasksOngoing { get; set; }
        public int TasksToDo { get; set; }
        public int TasksInProgress { get; set; }
        public int TasksReview { get; set; }
    }
}
