using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FacilityPro.Infrastructure.Data;
using FacilityPro.Domain.Entities;

namespace FacilityPro.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PmSchedulesController : ControllerBase
{
    private readonly FacilityDbContext _context;

    public PmSchedulesController(FacilityDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] string? buildingId)
    {
        var query = _context.PmSchedules.AsQueryable();
        if (!string.IsNullOrEmpty(buildingId))
            query = query.Where(s => s.BuildingId == buildingId);
        return Ok(await query.OrderBy(s => s.Title).ToListAsync());
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] PmSchedule schedule)
    {
        _context.PmSchedules.Add(schedule);
        await _context.SaveChangesAsync();
        return Ok(schedule);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(string id, [FromBody] PmSchedule dto)
    {
        var schedule = await _context.PmSchedules.FindAsync(id);
        if (schedule == null) return NotFound();
        schedule.Title = dto.Title;
        schedule.EntityId = dto.EntityId;
        schedule.EntityType = dto.EntityType;
        schedule.EntityName = dto.EntityName;
        schedule.Frequency = dto.Frequency;
        schedule.DayOfWeek = dto.DayOfWeek;
        schedule.DayOfMonth = dto.DayOfMonth;
        schedule.HourOfDay = dto.HourOfDay;
        schedule.AssignedToName = dto.AssignedToName;
        schedule.ChecklistTemplateId = dto.ChecklistTemplateId;
        schedule.IsActive = dto.IsActive;
        await _context.SaveChangesAsync();
        return Ok(schedule);
    }

    [HttpPut("{id}/toggle")]
    public async Task<IActionResult> Toggle(string id)
    {
        var schedule = await _context.PmSchedules.FindAsync(id);
        if (schedule == null) return NotFound();
        schedule.IsActive = !schedule.IsActive;
        await _context.SaveChangesAsync();
        return Ok(schedule);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(string id)
    {
        var schedule = await _context.PmSchedules.FindAsync(id);
        if (schedule == null) return NotFound();
        _context.PmSchedules.Remove(schedule);
        await _context.SaveChangesAsync();
        return Ok();
    }

    // Generate WorkerTasks from all active schedules
    [HttpPost("generate-tasks")]
    public async Task<IActionResult> GenerateTasks()
    {
        var schedules = await _context.PmSchedules.Where(s => s.IsActive).ToListAsync();
        var now = DateTime.UtcNow;
        var generated = new List<WorkerTask>();

        foreach (var s in schedules)
        {
            // Skip if already generated today
            if (s.LastGeneratedAt.HasValue && s.LastGeneratedAt.Value.Date == now.Date)
                continue;

            bool shouldGenerate = s.Frequency switch
            {
                "Daily" => true,
                "Weekly" => (int)now.DayOfWeek == s.DayOfWeek,
                "Monthly" => now.Day == s.DayOfMonth,
                _ => false
            };

            if (!shouldGenerate) continue;

            var scheduled = now.Date.AddHours(s.HourOfDay);
            var task = new WorkerTask
            {
                Title = s.Title,
                BuildingId = s.BuildingId,
                EntityId = s.EntityId,
                EntityType = s.EntityType,
                EntityName = s.EntityName,
                AssignedToName = s.AssignedToName,
                ScheduledTime = scheduled,
                Status = "Pending"
            };
            _context.Tasks.Add(task);
            s.LastGeneratedAt = now;
            generated.Add(task);
        }

        await _context.SaveChangesAsync();
        return Ok(new { generated = generated.Count });
    }
}
