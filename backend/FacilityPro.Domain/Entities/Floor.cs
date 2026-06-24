namespace FacilityPro.Domain.Entities;

public class Floor
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string BuildingId { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string QrCode { get; set; } = string.Empty;
    
    // Navigation
    public Building? Building { get; set; }
    public ICollection<Room> Rooms { get; set; } = new List<Room>();
    public ICollection<ChecklistMapping> ChecklistMappings { get; set; } = new List<ChecklistMapping>();
}
