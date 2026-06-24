using FacilityPro.Domain.Entities;
using FacilityPro.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace FacilityPro.Api.Services;

public class PmSchedulerService : BackgroundService
{
    private readonly IServiceProvider _services;
    private readonly ILogger<PmSchedulerService> _logger;

    public PmSchedulerService(IServiceProvider services, ILogger<PmSchedulerService> logger)
    {
        _services = services;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        // Run once shortly after startup, then every hour
        await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await GenerateDueTasks();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "PM Scheduler encountered an error");
            }

            await Task.Delay(TimeSpan.FromHours(1), stoppingToken);
        }
    }

    private async Task GenerateDueTasks()
    {
        using var scope = _services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<FacilityDbContext>();

        var now = DateTime.UtcNow;
        var schedules = await context.PmSchedules.Where(s => s.IsActive).ToListAsync();
        var generated = 0;

        foreach (var s in schedules)
        {
            // Skip if already generated today for this schedule
            if (s.LastGeneratedAt.HasValue && s.LastGeneratedAt.Value.Date == now.Date)
                continue;

            bool isDue = s.Frequency switch
            {
                "Daily"   => true,
                "Weekly"  => (int)now.DayOfWeek == s.DayOfWeek,
                "Monthly" => now.Day == s.DayOfMonth,
                _         => false
            };

            if (!isDue) continue;

            var scheduledTime = now.Date.AddHours(s.HourOfDay);

            context.Tasks.Add(new WorkerTask
            {
                Title          = s.Title,
                BuildingId     = s.BuildingId,
                EntityId       = s.EntityId,
                EntityType     = s.EntityType,
                EntityName     = s.EntityName,
                AssignedToName = s.AssignedToName,
                ScheduledTime  = scheduledTime,
                Status         = "Pending"
            });

            s.LastGeneratedAt = now;
            generated++;
        }

        if (generated > 0)
        {
            await context.SaveChangesAsync();
            _logger.LogInformation("PM Scheduler: auto-generated {count} tasks at {time}", generated, now);
        }
    }
}
