namespace FacilityPro.Domain.Entities;

public class Building
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string ClientId { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Location { get; set; } = string.Empty;

    // Geofencing anchor (set by admin during onboarding)
    public double? TargetLat { get; set; }
    public double? TargetLng { get; set; }
    public string LobbyQrCode { get; set; } = string.Empty;

    // Navigation
    public Client? Client { get; set; }
    public ICollection<Floor> Floors { get; set; } = new List<Floor>();
}
