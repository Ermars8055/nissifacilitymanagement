namespace FacilityPro.Domain.Entities;

public class WorkerSession
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string WorkerId { get; set; } = string.Empty;
    public string BuildingId { get; set; } = string.Empty;

    // Session lifecycle
    public DateTime StartedAt { get; set; } = DateTime.UtcNow;
    public DateTime ExpiresAt { get; set; }
    public bool IsActive { get; set; } = true;

    // Rolling breadcrumb state
    public DateTime LastScanAt { get; set; } = DateTime.UtcNow;
    public int LastFloorNumber { get; set; } = 0;
    public string? LastAssetId { get; set; }

    // GPS capture from lobby scan
    public double? ArrivalLat { get; set; }
    public double? ArrivalLng { get; set; }
    public double? DistanceFromBuilding { get; set; } // metres, stored for audit

    // Navigation
    public User? Worker { get; set; }
    public Building? Building { get; set; }
}
