using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FacilityPro.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;

namespace FacilityPro.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class DashboardController : ControllerBase
{
    private readonly FacilityDbContext _context;

    public DashboardController(FacilityDbContext context)
    {
        _context = context;
    }

    [HttpGet("buildings-health")]
    public async Task<IActionResult> GetBuildingsHealth()
    {
        var buildings = await _context.Buildings.ToListAsync();
        var result = new List<object>();
        foreach (var b in buildings)
        {
            var assets = await _context.Assets.CountAsync(a => a.BuildingId == b.Id);
            var open   = await _context.Complaints.CountAsync(c => c.BuildingId == b.Id && c.Status != "Resolved" && c.Status != "Closed");
            var health = Math.Max(0.0, Math.Min(100.0, 100.0 - (double)open / Math.Max(assets, 1) * 100.0));
            result.Add(new { buildingId = b.Id, buildingName = b.Name, health = $"{health:F1}%" });
        }
        return Ok(result);
    }

    [HttpGet]
    public async Task<IActionResult> GetDashboardData([FromQuery] string? buildingId)
    {
        var totalBuildings = await _context.Buildings.CountAsync();
        
        var assetsQuery = _context.Assets.AsQueryable();
        var complaintsQuery = _context.Complaints.AsQueryable();
        var tasksQuery = _context.Tasks.AsQueryable();

        if (!string.IsNullOrEmpty(buildingId))
        {
            assetsQuery = assetsQuery.Where(a => a.BuildingId == buildingId);
            complaintsQuery = complaintsQuery.Where(c => c.BuildingId == buildingId);
            tasksQuery = tasksQuery.Where(t => t.BuildingId == buildingId);
        }

        var totalAssets = await assetsQuery.CountAsync();
        
        var openComplaints = await complaintsQuery.CountAsync(c => c.Status != "Resolved" && c.Status != "Closed");
        var totalComplaints = await complaintsQuery.CountAsync();
        var complaintResolutionRate = totalComplaints == 0 ? 100.0 : (double)(totalComplaints - openComplaints) / totalComplaints * 100.0;

        var todayTasks = await tasksQuery.Where(t => t.ScheduledTime.Date == DateTime.UtcNow.Date).CountAsync();
        var completedToday = await tasksQuery.Where(t => t.ScheduledTime.Date == DateTime.UtcNow.Date && t.Status == "Completed").CountAsync();
        
        var recentTasks = await tasksQuery
            .OrderByDescending(t => t.ScheduledTime)
            .Take(3)
            .Select(t => new {
                type = "task",
                title = t.Title,
                subtitle = t.EntityName,
                time = t.ScheduledTime.ToString("o"),
                status = t.Status
            })
            .ToListAsync();

        var recentComplaints = await complaintsQuery
            .OrderByDescending(c => c.CreatedAt)
            .Take(2)
            .Select(c => new {
                type = "complaint",
                title = c.Title,
                subtitle = c.EntityName,
                time = c.CreatedAt.ToString("o"),
                status = c.Status
            })
            .ToListAsync();

        var activity = recentTasks.Cast<object>().Concat(recentComplaints.Cast<object>()).ToList();

        var data = new {
            kpi = new {
                totalBuildings,
                totalAssets,
                openComplaints,
                complaintResolutionRate = $"{complaintResolutionRate:F1}%",
                todayTasks,
                completedTasks = completedToday,
                buildingHealth = $"{Math.Max(0.0, Math.Min(100.0, 100.0 - (double)openComplaints / Math.Max(totalAssets, 1) * 100.0)):F1}%"
            },
            recentActivity = activity
        };

        return Ok(data);
    }
}
