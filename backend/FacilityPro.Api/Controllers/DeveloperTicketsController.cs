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

        var email = User.FindFirst(ClaimTypes.Email)?.Value ?? User.FindFirst("email")?.Value;
        string? userId = null;

        if (!string.IsNullOrWhiteSpace(email))
        {
            var dbUser = await _context.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == email.ToLower());
            if (dbUser != null)
            {
                userId = dbUser.Id;
            }
        }

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

        ticket.History.Add(new DeveloperTicketHistory
        {
            Action = "Ticket Created",
            Description = "User reported the issue.",
            PerformedByUserId = userId
        });

        _context.DeveloperTickets.Add(ticket);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Ticket submitted successfully", id = ticket.Id });
    }

    [HttpGet]
    [Authorize(Roles = "Admin, Super Admin")]
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
                UserEmail = t.User != null ? t.User.Email : "Unknown",
                UserRole = t.User != null ? t.User.Role : "Unknown"
            })
            .ToListAsync();

        return Ok(tickets);
    }

    [HttpGet("{id}")]
    [Authorize(Roles = "Admin, Super Admin")]
    public async Task<IActionResult> GetTicket(string id)
    {
        var ticket = await _context.DeveloperTickets
            .Include(t => t.User)
            .Include(t => t.History)
                .ThenInclude(h => h.PerformedByUser)
            .FirstOrDefaultAsync(t => t.Id == id);

        if (ticket == null) return NotFound();

        return Ok(new {
            ticket.Id,
            ticket.CreatedAt,
            ticket.DeviceOs,
            ticket.AppVersion,
            ticket.ScreenContext,
            ticket.Description,
            ticket.ScreenshotUrl,
            ticket.Status,
            UserEmail = ticket.User?.Email ?? "Unknown",
            UserRole = ticket.User?.Role ?? "Unknown",
            History = ticket.History.OrderByDescending(h => h.Timestamp).Select(h => new {
                h.Id,
                h.Timestamp,
                h.Action,
                h.Description,
                PerformedBy = h.PerformedByUser?.Name ?? h.PerformedByUser?.Email ?? "System"
            })
        });
    }

    public class ResolveRequest
    {
        public string Status { get; set; } = string.Empty;
        public string Comment { get; set; } = string.Empty;
    }

    [HttpPost("{id}/resolve")]
    [Authorize(Roles = "Admin, Super Admin")]
    public async Task<IActionResult> ResolveTicket(string id, [FromBody] ResolveRequest req)
    {
        var ticket = await _context.DeveloperTickets.FindAsync(id);
        if (ticket == null) return NotFound();

        ticket.Status = req.Status;

        // Find current admin's email
        var email = User.FindFirst(ClaimTypes.Email)?.Value ?? User.FindFirst("email")?.Value;
        string? adminId = null;
        if (!string.IsNullOrWhiteSpace(email))
        {
            var dbUser = await _context.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == email.ToLower());
            adminId = dbUser?.Id;
        }

        var history = new DeveloperTicketHistory
        {
            TicketId = ticket.Id,
            Action = $"Status changed to {req.Status}",
            Description = req.Comment,
            PerformedByUserId = adminId
        };

        _context.DeveloperTicketHistories.Add(history);
        await _context.SaveChangesAsync();

        return Ok();
    }
}
