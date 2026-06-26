using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FacilityPro.Infrastructure.Data;

namespace FacilityPro.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ReportsController : ControllerBase
{
    private readonly FacilityDbContext _context;

    public ReportsController(FacilityDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Worker activity report: away time, switch count, and session history.
    /// GET /api/Reports/worker-activity?buildingId=&workerId=&from=&to=
    /// </summary>
    [HttpGet("worker-activity")]
    public async Task<IActionResult> GetWorkerActivity(
        [FromQuery] string? buildingId,
        [FromQuery] string? workerId,
        [FromQuery] DateTime? from,
        [FromQuery] DateTime? to)
    {
        var fromDate = from ?? DateTime.UtcNow.AddDays(-7);
        var toDate = to ?? DateTime.UtcNow;

        // Get tasks in range
        var taskQuery = _context.Tasks.AsQueryable();
        if (!string.IsNullOrEmpty(buildingId)) taskQuery = taskQuery.Where(t => t.BuildingId == buildingId);
        if (!string.IsNullOrEmpty(workerId)) taskQuery = taskQuery.Where(t => t.AssignedToId == workerId);
        taskQuery = taskQuery.Where(t => t.ScheduledTime >= fromDate && t.ScheduledTime <= toDate);

        var tasks = await taskQuery.ToListAsync();
        var taskIds = tasks.Select(t => t.Id).ToList();

        // Get all app events for those tasks
        var events = await _context.TaskAppEvents
            .Where(e => taskIds.Contains(e.TaskId))
            .ToListAsync();

        // Build per-task summary
        var taskSummaries = tasks.Select(t =>
        {
            var taskEvents = events.Where(e => e.TaskId == t.Id).OrderBy(e => e.Timestamp).ToList();
            var totalAway = taskEvents.Where(e => e.EventType == "returned").Sum(e => e.AwaySeconds);
            var switchCount = taskEvents.Count(e => e.EventType == "left_app");
            var flagged = totalAway > 300; // flag if away > 5 min

            return new
            {
                taskId = t.Id,
                taskTitle = t.Title,
                workerId = t.AssignedToId,
                workerName = t.AssignedToName,
                scheduledTime = t.ScheduledTime,
                status = t.Status,
                totalAwaySeconds = totalAway,
                switchCount = switchCount,
                flagged = flagged,
                events = taskEvents.Select(e => new
                {
                    e.EventType,
                    e.AwaySeconds,
                    e.PackageName,
                    e.Timestamp
                })
            };
        }).ToList();

        // Attendance sessions in range
        var sessionQuery = _context.WorkerSessions.AsQueryable();
        if (!string.IsNullOrEmpty(buildingId)) sessionQuery = sessionQuery.Where(s => s.BuildingId == buildingId);
        if (!string.IsNullOrEmpty(workerId)) sessionQuery = sessionQuery.Where(s => s.WorkerId == workerId);
        sessionQuery = sessionQuery.Where(s => s.StartedAt >= fromDate && s.StartedAt <= toDate);
        var sessions = await sessionQuery.OrderByDescending(s => s.StartedAt).ToListAsync();

        return Ok(new
        {
            period = new { from = fromDate, to = toDate },
            totalTasks = tasks.Count,
            flaggedTasks = taskSummaries.Count(t => t.flagged),
            tasks = taskSummaries,
            attendanceSessions = sessions.Select(s => new
            {
                s.Id,
                s.WorkerId,
                s.BuildingId,
                s.StartedAt,
                s.ExpiresAt,
                s.IsActive,
                s.DistanceFromBuilding,
                s.ArrivalLat,
                s.ArrivalLng
            })
        });
    }
}
