namespace FacilityPro.Domain.Entities;

public class Asset
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string CategoryId { get; set; } = string.Empty;
    public string BuildingId { get; set; } = string.Empty;
    public string? FloorId { get; set; }
    public string? RoomId { get; set; }
    
    public string Name { get; set; } = string.Empty;
    public string SerialNumber { get; set; } = string.Empty;
    public string QrCode { get; set; } = string.Empty;
    public string Status { get; set; } = "Active"; // Active, Under Maintenance, Decommissioned
    public DateTime InstallDate { get; set; } = DateTime.UtcNow;

    // Navigation
    public AssetCategory? Category { get; set; }
    public Building? Building { get; set; }
    public Floor? Floor { get; set; }
    public Room? Room { get; set; }
    
    public ICollection<AssetFieldValue> FieldValues { get; set; } = new List<AssetFieldValue>();
    public ICollection<ChecklistMapping> ChecklistMappings { get; set; } = new List<ChecklistMapping>();
}
