using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FacilityPro.Infrastructure.Data;
using FacilityPro.Domain.Entities;

namespace FacilityPro.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AssetsController : ControllerBase
{
    private readonly FacilityDbContext _context;

    public AssetsController(FacilityDbContext context)
    {
        _context = context;
    }

    [HttpGet("categories/{clientId}")]
    public async Task<IActionResult> GetCategories(string clientId)
    {
        // Return only sub-categories (actual trackable items, not group headers)
        var categories = await _context.AssetCategories
            .Include(c => c.Fields)
            .Where(c => c.ClientId == clientId)
            .OrderBy(c => c.Name)
            .ToListAsync();
        return Ok(categories);
    }

    [HttpPost("categories")]
    public async Task<IActionResult> CreateCategory([FromBody] AssetCategory category)
    {
        _context.AssetCategories.Add(category);
        await _context.SaveChangesAsync();
        return Ok(category);
    }

    [HttpGet("building/{buildingId}")]
    public async Task<IActionResult> GetAssetsForBuilding(string buildingId)
    {
        var assets = await _context.Assets
            .Include(a => a.Category)
            .Include(a => a.FieldValues)
            .Include(a => a.Room)
            .Where(a => a.BuildingId == buildingId)
            .ToListAsync();
        return Ok(assets);
    }

    [HttpGet("room/{roomId}")]
    public async Task<IActionResult> GetAssetsForRoom(string roomId)
    {
        var assets = await _context.Assets
            .Include(a => a.Category)
            .Include(a => a.FieldValues)
            .Include(a => a.Room)
            .Where(a => a.RoomId == roomId)
            .ToListAsync();
        return Ok(assets);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetAssetById(string id)
    {
        var asset = await _context.Assets
            .Include(a => a.Category)
            .Include(a => a.FieldValues)
            .Include(a => a.Room)
            .FirstOrDefaultAsync(a => a.Id == id);
            
        if (asset == null) return NotFound();
        return Ok(asset);
    }

    [HttpPost]
    public async Task<IActionResult> CreateAsset([FromBody] Asset asset)
    {
        if (string.IsNullOrEmpty(asset.QrCode))
            asset.QrCode = $"QR-AST-{Guid.NewGuid().ToString().Substring(0, 6).ToUpper()}";
        _context.Assets.Add(asset);
        await _context.SaveChangesAsync();
        return Ok(asset);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteAsset(string id)
    {
        var asset = await _context.Assets.FindAsync(id);
        if (asset == null) return NotFound();
        _context.Assets.Remove(asset);
        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpGet("all")]
    public async Task<IActionResult> GetAllAssets()
    {
        var assets = await _context.Assets
            .Include(a => a.Category)
            .Include(a => a.Room)
            .Include(a => a.Building).ThenInclude(b => b!.Client)
            .Select(a => new {
                a.Id, a.Name, a.SerialNumber, a.QrCode, a.Status, a.BuildingId,
                BuildingName = a.Building != null ? a.Building.Name : "Unknown",
                ClientName   = (a.Building != null && a.Building.Client != null) ? a.Building.Client.Name : "Unknown",
                Category     = a.Category == null ? null : new { a.Category.Id, a.Category.Name },
                Room         = a.Room == null ? null : new { a.Room.Id, a.Room.Name }
            })
            .ToListAsync();
        return Ok(assets);
    }

    [HttpPut("{id}/position")]
    public async Task<IActionResult> UpdateAssetPosition(string id, [FromBody] AssetPositionDto dto)
    {
        var asset = await _context.Assets.FindAsync(id);
        if (asset == null) return NotFound();

        asset.AssetPosX = dto.AssetPosX;
        asset.AssetPosY = dto.AssetPosY;

        await _context.SaveChangesAsync();
        return Ok(asset);
    }

    [AllowAnonymous]
    [HttpPost("seed")]
    public async Task<IActionResult> SeedAssets()
    {
        if (await _context.AssetCategories.AnyAsync()) return Ok("Already seeded");

        var client = await _context.Clients.FirstOrDefaultAsync();
        if (client == null) return BadRequest("No clients found. Seed hierarchy first.");

        var building = await _context.Buildings.FirstOrDefaultAsync();
        if (building == null) return BadRequest("No buildings found.");

        // Create Category "HVAC Unit"
        var hvacCategory = new AssetCategory { ClientId = client.Id, Name = "HVAC Unit", Description = "Heating, Ventilation, and Air Conditioning" };
        var tonnageField = new AssetCategoryField { CategoryId = hvacCategory.Id, FieldName = "Tonnage", DataType = "Number", IsRequired = true };
        var filterSizeField = new AssetCategoryField { CategoryId = hvacCategory.Id, FieldName = "Filter Size", DataType = "Text", IsRequired = true };
        hvacCategory.Fields.Add(tonnageField);
        hvacCategory.Fields.Add(filterSizeField);
        _context.AssetCategories.Add(hvacCategory);

        // Create Category "Elevator"
        var elevatorCategory = new AssetCategory { ClientId = client.Id, Name = "Elevator", Description = "Passenger Elevators" };
        var capacityField = new AssetCategoryField { CategoryId = elevatorCategory.Id, FieldName = "Max Capacity (lbs)", DataType = "Number", IsRequired = true };
        elevatorCategory.Fields.Add(capacityField);
        _context.AssetCategories.Add(elevatorCategory);

        var room = await _context.Rooms.FirstOrDefaultAsync(r => r.Name == "Washroom A");
        if (room == null) return BadRequest("No Washroom A room found. Seed hierarchy first.");

        // Create an Asset instance (Wash Basin)
        var washBasinAsset = new Asset { CategoryId = hvacCategory.Id, BuildingId = building.Id, RoomId = room.Id, Name = "Wash Basin 1", SerialNumber = "SN-WB-001", QrCode = "QR-WB-001" };
        washBasinAsset.FieldValues.Add(new AssetFieldValue { AssetId = washBasinAsset.Id, FieldId = tonnageField.Id, Value = "N/A" });
        _context.Assets.Add(washBasinAsset);

        // Create an Asset instance (Rooftop HVAC) on the building itself, no room
        var hvacAsset = new Asset { CategoryId = hvacCategory.Id, BuildingId = building.Id, Name = "Rooftop HVAC 1", SerialNumber = "SN-HVAC-001", QrCode = "QR-HVAC-001" };
        hvacAsset.FieldValues.Add(new AssetFieldValue { AssetId = hvacAsset.Id, FieldId = tonnageField.Id, Value = "15" });
        hvacAsset.FieldValues.Add(new AssetFieldValue { AssetId = hvacAsset.Id, FieldId = filterSizeField.Id, Value = "20x20x1" });
        _context.Assets.Add(hvacAsset);

        await _context.SaveChangesAsync();
        return Ok("Assets Seeded successfully");
    }

    [AllowAnonymous]
    [HttpPost("seed-categories")]
    public async Task<IActionResult> SeedMoreCategories()
    {
        var client = await _context.Clients.FirstOrDefaultAsync();
        if (client == null) return BadRequest("No clients found.");

        // Remove assets first (FK constraint), then categories
        _context.Assets.RemoveRange(_context.Assets);
        await _context.SaveChangesAsync();
        _context.AssetCategories.RemoveRange(_context.AssetCategories);
        await _context.SaveChangesAsync();

        var groups = new Dictionary<string, List<string>>
        {
            { "Furniture", new List<string> { "Chair", "Table", "Sofa", "Cabinet", "Desk", "Bookshelf" } },
            { "IT & Network", new List<string> { "PC", "Server", "Monitor", "Printer", "Router", "Network Switch", "Laptop" } },
            { "Washroom & Plumbing", new List<string> { "Trash Bin", "Soap Dispenser", "Paper Towel Dispenser", "Mirror", "Wash Basin", "Toilet", "Hand Dryer" } },
            { "HVAC", new List<string> { "Air Conditioner", "Heater", "Ventilation Fan", "Thermostat", "HVAC Unit" } },
            { "Safety & Security", new List<string> { "Fire Extinguisher", "Smoke Detector", "Security Camera", "Access Control Panel", "Alarm System" } },
            { "Electrical & Lighting", new List<string> { "Lighting Fixture", "Electrical Panel", "Power Outlet", "Elevator" } },
            { "Appliances", new List<string> { "Vending Machine", "Water Dispenser", "Microwave", "Refrigerator", "Coffee Machine" } },
            { "Audio/Visual & Office", new List<string> { "Projector", "Whiteboard", "TV Screen", "Shredder", "IP Phone" } }
        };

        var added = 0;
        foreach (var group in groups)
        {
            // Save parent first so its ID is committed
            var parent = new AssetCategory { ClientId = client.Id, Name = group.Key, Description = $"{group.Key} Category" };
            _context.AssetCategories.Add(parent);
            await _context.SaveChangesAsync(); // commit so parent.Id is real
            added++;

            foreach (var name in group.Value)
            {
                _context.AssetCategories.Add(new AssetCategory
                {
                    ClientId = client.Id,
                    Name = name,
                    Description = $"{name} Asset",
                    ParentCategoryId = parent.Id
                });
                added++;
            }
            await _context.SaveChangesAsync();
        }

        return Ok($"Seeded {added} categories in hierarchy.");
    }

}

public class AssetPositionDto
{
    public double? AssetPosX { get; set; }
    public double? AssetPosY { get; set; }
}
