using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FacilityPro.Infrastructure.Data;
using FacilityPro.Domain.Entities;

namespace FacilityPro.Api.Controllers;

public record TaskStatusDto(string Status);

[ApiController]
[Route("api/[controller]")]
public class TasksController : ControllerBase
{
    private readonly FacilityDbContext _context;

    public TasksController(FacilityDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetTasks(
        [FromQuery] string? buildingId,
        [FromQuery] string? assignedToId,
        [FromQuery] string? entityId)
    {
        var query = _context.Tasks.AsQueryable();
        if (!string.IsNullOrEmpty(buildingId))
            query = query.Where(t => t.BuildingId == buildingId);
        if (!string.IsNullOrEmpty(assignedToId))
            query = query.Where(t => t.AssignedToId == assignedToId);
        if (!string.IsNullOrEmpty(entityId))
            query = query.Where(t => t.EntityId == entityId);
        var tasks = await query.OrderByDescending(t => t.ScheduledTime).ToListAsync();
        return Ok(tasks);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetTask(string id)
    {
        var task = await _context.Tasks.FindAsync(id);
        if (task == null) return NotFound();
        return Ok(task);
    }

    [HttpPost]
    public async Task<IActionResult> CreateTask([FromBody] WorkerTask task)
    {
        _context.Tasks.Add(task);
        await _context.SaveChangesAsync();
        return Ok(task);
    }

    [HttpPut("{id}/complete")]
    public async Task<IActionResult> CompleteTask(string id, [FromBody] WorkerTask completionData)
    {
        var task = await _context.Tasks.FindAsync(id);
        if (task == null) return NotFound();

        task.Status = "Completed";
        task.CompletedTime = DateTime.UtcNow;
        task.QrCodeScanned = completionData.QrCodeScanned;
        task.IsVerified = true;
        task.Notes = completionData.Notes;

        await _context.SaveChangesAsync();
        return Ok(task);
    }

    [HttpPut("{id}/status")]
    public async Task<IActionResult> UpdateStatus(string id, [FromBody] TaskStatusDto dto)
    {
        var task = await _context.Tasks.FindAsync(id);
        if (task == null) return NotFound();
        task.Status = dto.Status;
        if (dto.Status == "Completed") task.CompletedTime = DateTime.UtcNow;
        await _context.SaveChangesAsync();
        return Ok(task);
    }

    [HttpPost("{id}/events")]
    public async Task<IActionResult> LogAppEvent(string id, [FromBody] TaskAppEvent evt)
    {
        var task = await _context.Tasks.FindAsync(id);
        if (task == null) return NotFound();

        evt.TaskId = id;
        evt.Timestamp = DateTime.UtcNow;
        _context.TaskAppEvents.Add(evt);
        await _context.SaveChangesAsync();
        return Ok(new { logged = true });
    }

    [AllowAnonymous]
    [HttpPost("seed")]
    public async Task<IActionResult> SeedTasks()
    {
        if (await _context.Tasks.AnyAsync()) return Ok("Tasks already seeded");

        var room = await _context.Rooms.FirstOrDefaultAsync(r => r.Name == "Washroom A");
        var asset = await _context.Assets.FirstOrDefaultAsync(a => a.Name == "Rooftop HVAC 1");
        
        var building = await _context.Buildings.FirstOrDefaultAsync();
        var buildingId = building?.Id ?? string.Empty;

        var t1 = new WorkerTask {
            Title = "Hourly Washroom Check",
            Description = "Clean floor, check soap, check leakage",
            EntityId = room?.Id ?? "room-1",
            EntityType = "Room",
            EntityName = room?.Name ?? "Washroom A",
            BuildingId = buildingId,
            AssignedToName = "John Doe",
            ScheduledTime = DateTime.UtcNow.Date.AddHours(9),
            Status = "Pending"
        };

        var t2 = new WorkerTask {
            Title = "HVAC Maintenance",
            Description = "Replace 20x20 filter",
            EntityId = asset?.Id ?? "asset-1",
            EntityType = "Asset",
            EntityName = asset?.Name ?? "Rooftop HVAC 1",
            BuildingId = buildingId,
            AssignedToName = "Kumar Tech",
            ScheduledTime = DateTime.UtcNow.Date.AddHours(10),
            Status = "Pending"
        };

        _context.Tasks.AddRange(t1, t2);
        await _context.SaveChangesAsync();
        return Ok("Tasks seeded successfully");
    }
}
