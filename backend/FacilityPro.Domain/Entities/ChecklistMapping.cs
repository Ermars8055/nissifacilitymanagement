namespace FacilityPro.Domain.Entities;

public class ChecklistMapping
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string? FloorId { get; set; }
    public string? RoomId { get; set; }
    public string? AssetId { get; set; }
    
    public string ChecklistId { get; set; } = string.Empty;
    public string ChecklistName { get; set; } = string.Empty;

    // Navigation
    public Floor? Floor { get; set; }
    public Room? Room { get; set; }
    public Asset? Asset { get; set; }
}
