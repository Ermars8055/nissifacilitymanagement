namespace FacilityPro.Domain.Entities;

public class UserBuildingMapping
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string UserId { get; set; } = string.Empty;
    public string BuildingId { get; set; } = string.Empty;

    // Navigation properties
    public User? User { get; set; }
    public Building? Building { get; set; }
}
