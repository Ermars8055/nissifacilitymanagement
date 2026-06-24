namespace FacilityPro.Domain.Entities;

public class AssetChecklistTemplate
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Name { get; set; } = string.Empty; // e.g. "Fire Extinguisher Template"
    
    public ICollection<ChecklistItemTemplate> Items { get; set; } = new List<ChecklistItemTemplate>();
}

public class ChecklistItemTemplate
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string ChecklistTemplateId { get; set; } = string.Empty;
    public string Question { get; set; } = string.Empty; // e.g. "Pressure OK?"
    
    public bool RequiresPhoto { get; set; } = false;
    public bool IsPassFail { get; set; } = true;

    public AssetChecklistTemplate? Template { get; set; }
}
