namespace FacilityPro.Domain.Entities;

public class DeveloperTicketHistory
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    
    // The ticket this history belongs to
    public string TicketId { get; set; } = string.Empty;
    public DeveloperTicket? Ticket { get; set; }
    
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    
    // E.g., "Created", "Comment Added", "Status Changed to Resolved"
    public string Action { get; set; } = string.Empty;
    
    // Detailed comment or note left by the admin
    public string Description { get; set; } = string.Empty;
    
    // The admin/user who performed the action (can be null for system actions)
    public string? PerformedByUserId { get; set; }
    public User? PerformedByUser { get; set; }
}
