namespace FacilityPro.Domain.Entities;

public class TaskAppEvent
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string TaskId { get; set; } = string.Empty;

    // "left_app" | "returned" | "step_completed"
    public string EventType { get; set; } = string.Empty;
    public string? PackageName { get; set; }
    public int AwaySeconds { get; set; } = 0;
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    // Navigation
    public WorkerTask? Task { get; set; }
}
