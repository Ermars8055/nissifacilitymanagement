namespace FacilityPro.Domain.Entities;

public class Client
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Name { get; set; } = string.Empty;
    public string ContactEmail { get; set; } = string.Empty;
    public string Status { get; set; } = "ACTIVE";
    
    // Navigation
    public ICollection<Building> Buildings { get; set; } = new List<Building>();
}
