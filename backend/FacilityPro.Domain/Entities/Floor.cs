namespace FacilityPro.Domain.Entities;

public class Floor
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string BuildingId { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string QrCode { get; set; } = string.Empty;
    public int FloorNumber { get; set; } = 0; // 0 = Ground/Lobby, 1 = Floor 1, etc.

    // Spatial Mapping Fields
    public string? FloorPlanImageUrl { get; set; }  // optional uploaded blueprint
    public double CanvasWidth { get; set; } = 800;
    public double CanvasHeight { get; set; } = 600;

    // Navigation
    public Building? Building { get; set; }
    public ICollection<Room> Rooms { get; set; } = new List<Room>();
    public ICollection<ChecklistMapping> ChecklistMappings { get; set; } = new List<ChecklistMapping>();
}
