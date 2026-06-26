using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FacilityPro.Infrastructure.Data;
using FacilityPro.Domain.Entities;

namespace FacilityPro.Api.Controllers;

public record StartSessionDto(
    string WorkerId,
    string BuildingId,
    string LobbyQrCode,
    double UserLat,
    double UserLng,
    bool IsMockLocation
);

public record VerifySessionDto(
    string WorkerId,
    string EntityId,        // assetId, roomId, or floorId
    string EntityType,      // "Asset", "Room", "Floor"
    string QrCode
);

[ApiController]
[Route("api/[controller]")]
public class SessionsController : ControllerBase
{
    private readonly FacilityDbContext _context;

    // Geofence radius in metres
    private const double GeofenceMetres = 40.0;
    // Session expiry
    private const int SessionExpiryMinutes = 30;

    public SessionsController(FacilityDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Lobby QR scan — establishes attendance session after GPS + geofence check.
    /// </summary>
    [HttpPost("start")]
    public async Task<IActionResult> StartSession([FromBody] StartSessionDto dto)
    {
        // 1. Block fake GPS apps immediately
        if (dto.IsMockLocation)
            return BadRequest(new { error = "mock_location", message = "Fake GPS detected. Disable mock location and try again." });

        // 2. Verify the building exists and has a lobby QR configured
        var building = await _context.Buildings.FindAsync(dto.BuildingId);
        if (building == null) return NotFound(new { error = "building_not_found" });

        if (!string.IsNullOrEmpty(building.LobbyQrCode) && building.LobbyQrCode != dto.LobbyQrCode)
            return BadRequest(new { error = "wrong_qr", message = "Wrong lobby QR code scanned." });

        // 3. Geofence check (only when building coordinates are configured)
        double distance = 0;
        if (building.TargetLat.HasValue && building.TargetLng.HasValue)
        {
            distance = Haversine(dto.UserLat, dto.UserLng, building.TargetLat.Value, building.TargetLng.Value);
            if (distance > GeofenceMetres)
                return BadRequest(new
                {
                    error = "outside_geofence",
                    message = $"You are {distance:F0}m from the building. Must be within {GeofenceMetres}m.",
                    distanceMetres = distance
                });
        }

        // 4. Expire any existing active session for this worker
        var existing = await _context.WorkerSessions
            .Where(s => s.WorkerId == dto.WorkerId && s.IsActive)
            .ToListAsync();
        foreach (var s in existing) s.IsActive = false;

        // 5. Create new session
        var session = new WorkerSession
        {
            WorkerId = dto.WorkerId,
            BuildingId = dto.BuildingId,
            StartedAt = DateTime.UtcNow,
            LastScanAt = DateTime.UtcNow,
            LastFloorNumber = 0,
            ExpiresAt = DateTime.UtcNow.AddMinutes(SessionExpiryMinutes),
            IsActive = true,
            ArrivalLat = dto.UserLat,
            ArrivalLng = dto.UserLng,
            DistanceFromBuilding = distance
        };
        _context.WorkerSessions.Add(session);
        await _context.SaveChangesAsync();

        return Ok(new
        {
            sessionId = session.Id,
            expiresAt = session.ExpiresAt,
            distanceMetres = distance,
            message = "Attendance confirmed. Session started."
        });
    }

    /// <summary>
    /// Asset/Floor/Room QR scan — Time-of-Flight verification using breadcrumb chain.
    /// </summary>
    [HttpPost("verify")]
    public async Task<IActionResult> VerifySession([FromBody] VerifySessionDto dto)
    {
        // 1. Find active session
        var session = await _context.WorkerSessions
            .Where(s => s.WorkerId == dto.WorkerId && s.IsActive)
            .OrderByDescending(s => s.StartedAt)
            .FirstOrDefaultAsync();

        if (session == null)
            return BadRequest(new { error = "no_session", message = "No active attendance session. Scan the lobby QR first." });

        // 2. Check session expiry
        if (DateTime.UtcNow > session.ExpiresAt)
        {
            session.IsActive = false;
            await _context.SaveChangesAsync();
            return BadRequest(new { error = "session_expired", message = "Session expired (30 min). Re-scan the lobby QR to continue." });
        }

        // 3. Resolve floor number from entity
        int currentFloorNumber = await ResolveFloorNumber(dto.EntityId, dto.EntityType);

        // 4. Time-of-Flight check (breadcrumb: check against last scan, not lobby)
        var elapsed = (DateTime.UtcNow - session.LastScanAt).TotalSeconds;
        int floorDelta = Math.Abs(currentFloorNumber - session.LastFloorNumber);

        // Minimum transit time:
        // Same floor: 5s | Each additional floor: +15s (elevator baseline)
        double minSeconds = floorDelta == 0 ? 5.0 : 15.0 + (floorDelta * 15.0);

        if (elapsed < minSeconds)
            return BadRequest(new
            {
                error = "tof_violation",
                message = $"Too fast! Physically impossible to travel {floorDelta} floor(s) in {elapsed:F0}s. Minimum is {minSeconds:F0}s.",
                elapsedSeconds = elapsed,
                minSeconds = minSeconds,
                floorDelta = floorDelta
            });

        // 5. Approved — update rolling breadcrumb
        session.LastScanAt = DateTime.UtcNow;
        session.LastFloorNumber = currentFloorNumber;
        session.LastAssetId = dto.EntityId;
        session.ExpiresAt = DateTime.UtcNow.AddMinutes(SessionExpiryMinutes);

        await _context.SaveChangesAsync();

        return Ok(new
        {
            verified = true,
            elapsedSeconds = elapsed,
            currentFloor = currentFloorNumber,
            message = "Location verified."
        });
    }

    private async Task<int> ResolveFloorNumber(string entityId, string entityType)
    {
        return entityType switch
        {
            "Floor" => (await _context.Floors.FindAsync(entityId))?.FloorNumber ?? 0,
            "Room"  => (await _context.Rooms
                            .Include(r => r.Floor)
                            .FirstOrDefaultAsync(r => r.Id == entityId))?.Floor?.FloorNumber ?? 0,
            "Asset" => (await _context.Assets
                            .Include(a => a.Room).ThenInclude(r => r!.Floor)
                            .FirstOrDefaultAsync(a => a.Id == entityId))?.Room?.Floor?.FloorNumber ?? 0,
            _       => 0
        };
    }

    /// <summary>
    /// GET active session for a worker (so Flutter can restore session after app restart).
    /// </summary>
    [HttpGet("active/{workerId}")]
    public async Task<IActionResult> GetActiveSession(string workerId)
    {
        var session = await _context.WorkerSessions
            .Where(s => s.WorkerId == workerId && s.IsActive && s.ExpiresAt > DateTime.UtcNow)
            .OrderByDescending(s => s.StartedAt)
            .FirstOrDefaultAsync();

        if (session == null) return Ok(new { hasSession = false });

        return Ok(new
        {
            hasSession = true,
            sessionId = session.Id,
            startedAt = session.StartedAt,
            expiresAt = session.ExpiresAt,
            lastFloorNumber = session.LastFloorNumber,
            distanceMetres = session.DistanceFromBuilding
        });
    }

    // ── Haversine Formula ────────────────────────────────────────────────────
    private static double Haversine(double lat1, double lng1, double lat2, double lng2)
    {
        const double R = 6_371_000; // Earth radius in metres
        var phi1 = lat1 * Math.PI / 180;
        var phi2 = lat2 * Math.PI / 180;
        var dPhi = (lat2 - lat1) * Math.PI / 180;
        var dLambda = (lng2 - lng1) * Math.PI / 180;

        var a = Math.Sin(dPhi / 2) * Math.Sin(dPhi / 2)
              + Math.Cos(phi1) * Math.Cos(phi2)
              * Math.Sin(dLambda / 2) * Math.Sin(dLambda / 2);
        var c = 2 * Math.Asin(Math.Sqrt(a));
        return R * c;
    }
}
