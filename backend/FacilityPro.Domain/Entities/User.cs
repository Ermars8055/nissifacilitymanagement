namespace FacilityPro.Domain.Entities;

public class User
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty; // Admin, Supervisor, Manager, Technician
    
    // Navigation property
    public ICollection<UserBuildingMapping> BuildingMappings { get; set; } = new List<UserBuildingMapping>();
}
