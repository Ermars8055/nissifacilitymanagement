namespace FacilityPro.Domain.Entities;

public class WorkerTask
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    
    // Assigned Entity (Building/Floor/Room/Asset)
    public string EntityId { get; set; } = string.Empty;
    public string EntityType { get; set; } = string.Empty; // "Building", "Floor", "Room", "Asset"
    public string EntityName { get; set; } = string.Empty; // Denormalized name for UI
    public string BuildingId { get; set; } = string.Empty; // To associate task directly with a building
    
    // Assignment
    public string AssignedToId { get; set; } = string.Empty; // User ID
    public string AssignedToName { get; set; } = string.Empty; // Denormalized worker name
    
    // Status & Timing
    public string Status { get; set; } = "Pending"; // "Pending", "In Progress", "Completed", "Missed"
    public DateTime ScheduledTime { get; set; }
    public DateTime? CompletedTime { get; set; }
    
    // Completion metadata
    public string QrCodeScanned { get; set; } = string.Empty;
    public bool IsVerified { get; set; } = false;
    public string Notes { get; set; } = string.Empty;
}
