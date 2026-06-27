namespace FacilityPro.Domain.Entities;

public class Room
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string FloorId { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty; // e.g., "Washroom A", "Electrical Room"
    public string QrCode { get; set; } = string.Empty; // e.g., "QR-WSA-001"

    // Spatial Mapping Fields
    public double PosX { get; set; } = 0;       // X position on floor plan
    public double PosY { get; set; } = 0;       // Y position on floor plan
    public double Width { get; set; } = 120;    // pixel width
    public double Height { get; set; } = 80;    // pixel height
    public string Color { get; set; } = "";     // optional custom color

    // Navigation
    public Floor? Floor { get; set; }
    public ICollection<Asset> Assets { get; set; } = new List<Asset>();
    public ICollection<ChecklistMapping> ChecklistMappings { get; set; } = new List<ChecklistMapping>();
}
