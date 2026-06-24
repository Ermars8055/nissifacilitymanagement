namespace FacilityPro.Domain.Entities;

public class PmSchedule
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Title { get; set; } = string.Empty;
    public string BuildingId { get; set; } = string.Empty;
    public string EntityId { get; set; } = string.Empty;
    public string EntityType { get; set; } = "Room"; // Room, Asset, Floor, Building
    public string EntityName { get; set; } = string.Empty;
    public string Frequency { get; set; } = "Weekly"; // Daily, Weekly, Monthly
    public int DayOfWeek { get; set; } = 1;   // 0=Sun..6=Sat (used for Weekly)
    public int DayOfMonth { get; set; } = 1;  // 1-31 (used for Monthly)
    public int HourOfDay { get; set; } = 8;   // 0-23
    public string AssignedToName { get; set; } = string.Empty;
    public string? ChecklistTemplateId { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? LastGeneratedAt { get; set; }
}
