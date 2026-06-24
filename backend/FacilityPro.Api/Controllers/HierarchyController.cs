using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FacilityPro.Infrastructure.Data;
using FacilityPro.Domain.Entities;

namespace FacilityPro.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class HierarchyController : ControllerBase
{
    private readonly FacilityDbContext _context;

    public HierarchyController(FacilityDbContext context)
    {
        _context = context;
    }

    [HttpGet("clients")]
    public async Task<IActionResult> GetClients()
    {
        var clients = await _context.Clients.ToListAsync();
        return Ok(clients);
    }

    [HttpGet("buildings/{clientId}")]
    public async Task<IActionResult> GetBuildings(string clientId)
    {
        var buildings = await _context.Buildings.Where(b => b.ClientId == clientId).ToListAsync();
        return Ok(buildings);
    }

    [HttpGet("building/{buildingId}")]
    public async Task<IActionResult> GetBuilding(string buildingId)
    {
        var building = await _context.Buildings.FirstOrDefaultAsync(b => b.Id == buildingId);
        if (building == null) return NotFound();
        return Ok(building);
    }

    [HttpGet("floors/{buildingId}")]
    public async Task<IActionResult> GetFloors(string buildingId)
    {
        var floors = await _context.Floors
            .Include(f => f.ChecklistMappings)
            .Where(f => f.BuildingId == buildingId)
            .ToListAsync();
        return Ok(floors);
    }

    [HttpPost("clients")]
    public async Task<IActionResult> CreateClient([FromBody] Client client)
    {
        _context.Clients.Add(client);
        await _context.SaveChangesAsync();
        return Ok(client);
    }

    [HttpPost("buildings")]
    public async Task<IActionResult> CreateBuilding([FromBody] Building building)
    {
        _context.Buildings.Add(building);
        await _context.SaveChangesAsync();
        return Ok(building);
    }

    [HttpPost("floors")]
    public async Task<IActionResult> CreateFloor([FromBody] Floor floor)
    {
        floor.QrCode = $"QR-FLR-{Guid.NewGuid().ToString().Substring(0, 5).ToUpper()}";
        _context.Floors.Add(floor);
        await _context.SaveChangesAsync();
        return Ok(floor);
    }

    [HttpGet("rooms/{floorId}")]
    public async Task<IActionResult> GetRooms(string floorId)
    {
        var rooms = await _context.Rooms
            .Include(r => r.Assets)
            .Where(r => r.FloorId == floorId)
            .ToListAsync();
        return Ok(rooms);
    }

    [HttpPost("rooms")]
    public async Task<IActionResult> CreateRoom([FromBody] Room room)
    {
        room.QrCode = $"QR-RM-{Guid.NewGuid().ToString().Substring(0, 5).ToUpper()}";
        _context.Rooms.Add(room);
        await _context.SaveChangesAsync();
        return Ok(room);
    }

    [HttpPut("clients/{id}")]
    public async Task<IActionResult> UpdateClient(string id, [FromBody] Client updated)
    {
        var client = await _context.Clients.FindAsync(id);
        if (client == null) return NotFound();
        client.Name = updated.Name;
        client.ContactEmail = updated.ContactEmail;
        await _context.SaveChangesAsync();
        return Ok(client);
    }

    [HttpDelete("clients/{id}")]
    public async Task<IActionResult> DeleteClient(string id)
    {
        var client = await _context.Clients.FindAsync(id);
        if (client == null) return NotFound();
        _context.Clients.Remove(client);
        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpPut("buildings/{id}")]
    public async Task<IActionResult> UpdateBuilding(string id, [FromBody] Building updated)
    {
        var building = await _context.Buildings.FindAsync(id);
        if (building == null) return NotFound();
        building.Name = updated.Name;
        building.Location = updated.Location;
        await _context.SaveChangesAsync();
        return Ok(building);
    }

    [HttpDelete("buildings/{id}")]
    public async Task<IActionResult> DeleteBuilding(string id)
    {
        var building = await _context.Buildings.FindAsync(id);
        if (building == null) return NotFound();
        _context.Buildings.Remove(building);
        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("floor/{id}")]
    public async Task<IActionResult> DeleteFloor(string id)
    {
        var floor = await _context.Floors.FindAsync(id);
        if (floor == null) return NotFound();
        _context.Floors.Remove(floor);
        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("room/{id}")]
    public async Task<IActionResult> DeleteRoom(string id)
    {
        var room = await _context.Rooms.FindAsync(id);
        if (room == null) return NotFound();
        _context.Rooms.Remove(room);
        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpGet("all-buildings")]
    public async Task<IActionResult> GetAllBuildings()
    {
        var buildings = await _context.Buildings
            .Include(b => b.Client)
            .Select(b => new { b.Id, b.Name, b.Location, b.ClientId, ClientName = b.Client!.Name })
            .ToListAsync();
        return Ok(buildings);
    }

    [AllowAnonymous]
    [HttpPost("seed")]
    public async Task<IActionResult> Seed()
    {
        if (await _context.Clients.AnyAsync()) return Ok("Already seeded");

        var client1 = new Client { Name = "Apex Industries", ContactEmail = "contact@apex.com" };
        var client2 = new Client { Name = "Mercy Health", ContactEmail = "admin@mercy.com" };
        
        _context.Clients.AddRange(client1, client2);

        var b1 = new Building { ClientId = client1.Id, Name = "Grand Tower", Location = "New York" };
        var b2 = new Building { ClientId = client1.Id, Name = "Apex HQ", Location = "Chicago" };
        
        _context.Buildings.AddRange(b1, b2);

        var f1 = new Floor { BuildingId = b1.Id, Name = "Floor 1", QrCode = "QR-FLR-001" };
        var f2 = new Floor { BuildingId = b1.Id, Name = "Floor 2", QrCode = "QR-FLR-002" };
        var gFloor = new Floor { BuildingId = b1.Id, Name = "Ground Floor", QrCode = "QR-FLR-000" };

        _context.Floors.AddRange(f1, f2, gFloor);

        // Phase 2: Room Setup
        var washroomA = new Room { FloorId = f1.Id, Name = "Washroom A", QrCode = "QR-WSA-001" };
        var elecRoom = new Room { FloorId = f1.Id, Name = "Electrical Room", QrCode = "QR-ELE-001" };
        var reception = new Room { FloorId = gFloor.Id, Name = "Reception", QrCode = "QR-REC-001" };

        _context.Rooms.AddRange(washroomA, elecRoom, reception);

        var mapping1 = new ChecklistMapping { RoomId = washroomA.Id, ChecklistId = "cl-wash-01", ChecklistName = "Washroom Template" };
        _context.ChecklistMappings.Add(mapping1);

        await _context.SaveChangesAsync();
        return Ok("Seeded successfully");
    }
}
