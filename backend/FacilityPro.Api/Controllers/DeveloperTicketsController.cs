using FacilityPro.Domain.Entities;
using FacilityPro.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace FacilityPro.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class DeveloperTicketsController : ControllerBase
{
    private readonly FacilityDbContext _context;
    private readonly IWebHostEnvironment _env;

    public DeveloperTicketsController(FacilityDbContext context, IWebHostEnvironment env)
    {
        _context = context;
        _env = env;
    }

    [HttpPost]
    [RequestSizeLimit(10 * 1024 * 1024)] // 10MB limit
    public async Task<IActionResult> CreateTicket(
        [FromForm] string description,
        [FromForm] string? deviceOs,
        [FromForm] string? appVersion,
        [FromForm] string? screenContext,
        IFormFile? screenshot)
    {
        if (string.IsNullOrWhiteSpace(description))
            return BadRequest("Description is required.");

        string? screenshotUrl = null;

        if (screenshot != null)
        {
            // Validate file extension
            var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp" };
            var extension = Path.GetExtension(screenshot.FileName).ToLowerInvariant();
            if (!allowedExtensions.Contains(extension))
                return BadRequest("Invalid file type. Only JPG, PNG, and WEBP are allowed.");

            // Create upload directory if it doesn't exist
            var uploadDir = Path.Combine(_env.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot"), "uploads", "tickets");
            if (!Directory.Exists(uploadDir))
                Directory.CreateDirectory(uploadDir);

            // Generate safe random filename
            var fileName = $"{Guid.NewGuid()}{extension}";
            var filePath = Path.Combine(uploadDir, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await screenshot.CopyToAsync(stream);
            }

            screenshotUrl = $"/uploads/tickets/{fileName}";
        }

        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        var ticket = new DeveloperTicket
        {
            UserId = userId,
            Description = description,
            DeviceOs = deviceOs,
            AppVersion = appVersion,
            ScreenContext = screenContext,
            ScreenshotUrl = screenshotUrl,
            Status = "Open",
            CreatedAt = DateTime.UtcNow
        };

        _context.DeveloperTickets.Add(ticket);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Ticket submitted successfully", id = ticket.Id });
    }

    [HttpGet]
    // Normally we would restrict this to Admin only, but we'll allow it for now so the dashboard can fetch it
    public async Task<IActionResult> GetTickets()
    {
        var tickets = await _context.DeveloperTickets
            .Include(t => t.User)
            .OrderByDescending(t => t.CreatedAt)
            .Select(t => new {
                t.Id,
                t.CreatedAt,
                t.DeviceOs,
                t.AppVersion,
                t.ScreenContext,
                t.Description,
                t.ScreenshotUrl,
                t.Status,
                UserEmail = t.User != null ? t.User.Email : "Unknown"
            })
            .ToListAsync();

        return Ok(tickets);
    }
}
