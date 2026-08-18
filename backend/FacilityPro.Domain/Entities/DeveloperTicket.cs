namespace FacilityPro.Domain.Entities;

public class DeveloperTicket
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    // The user who submitted the ticket
    public string? UserId { get; set; }
    public User? User { get; set; }

    // Device / Context Information
    public string? DeviceOs { get; set; }
    public string? AppVersion { get; set; }
    public string? ScreenContext { get; set; }

    // User input
    public string Description { get; set; } = string.Empty;
    public string? ScreenshotUrl { get; set; }

    // Status tracking
    public string Status { get; set; } = "Open"; // Open, InProgress, Resolved, Closed

    // History Timeline
    public ICollection<DeveloperTicketHistory> History { get; set; } = new List<DeveloperTicketHistory>();
}
