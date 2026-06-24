namespace FacilityPro.Domain.Entities;

public class ChecklistTemplate
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Name { get; set; } = string.Empty;
    public string BuildingId { get; set; } = string.Empty;
    public string ItemsJson { get; set; } = "[]"; // JSON: [{id, text, type: checkbox|number|text|photo}]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    public ICollection<ChecklistAssignment> Assignments { get; set; } = new List<ChecklistAssignment>();
}

public class ChecklistAssignment
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string ChecklistTemplateId { get; set; } = string.Empty;
    public string EntityId { get; set; } = string.Empty;
    public string EntityType { get; set; } = "Room"; // Room, Asset
    public string EntityName { get; set; } = string.Empty;
    public DateTime AssignedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    public ChecklistTemplate? Template { get; set; }
}
