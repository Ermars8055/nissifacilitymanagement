using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FacilityPro.Domain.Entities;
using FacilityPro.Infrastructure.Data;

namespace FacilityPro.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly FacilityDbContext _context;

    public UsersController(FacilityDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetUsers()
    {
        var users = await _context.Users
            .Include(u => u.BuildingMappings)
            .ThenInclude(m => m.Building)
            .ToListAsync();
            
        return Ok(users.Select(u => new {
            u.Id,
            u.Name,
            u.Email,
            u.Role,
            Buildings = u.BuildingMappings.Select(m => m.Building?.Name).ToList(),
            BuildingIds = u.BuildingMappings.Select(m => m.BuildingId).ToList()
        }));
    }

    [HttpGet("by-email")]
    public async Task<IActionResult> GetByEmail([FromQuery] string email)
    {
        if (string.IsNullOrWhiteSpace(email))
            return BadRequest("Email is required.");

        var user = await _context.Users
            .Include(u => u.BuildingMappings)
            .ThenInclude(m => m.Building)
            .FirstOrDefaultAsync(u => u.Email.ToLower() == email.ToLower());

        if (user == null)
            return NotFound("User not found.");

        return Ok(new {
            user.Id,
            user.Name,
            user.Email,
            user.Role,
            Buildings = user.BuildingMappings.Select(m => m.Building?.Name).ToList(),
            BuildingIds = user.BuildingMappings.Select(m => m.BuildingId).ToList()
        });
    }

    [HttpPost]
    public async Task<IActionResult> CreateUser([FromBody] User user)
    {
        user.Id = Guid.NewGuid().ToString();
        _context.Users.Add(user);
        await _context.SaveChangesAsync();
        return Ok(user);
    }

    [HttpGet("{id}/buildings")]
    public async Task<IActionResult> GetUserBuildings(string id)
    {
        var mappings = await _context.UserBuildingMappings
            .Include(m => m.Building)
            .Where(m => m.UserId == id)
            .Select(m => m.Building)
            .ToListAsync();
            
        return Ok(mappings);
    }

    [HttpPut("{id}/role")]
    public async Task<IActionResult> UpdateRole(string id, [FromBody] UpdateRoleDto dto)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound();
        user.Role = dto.Role;
        await _context.SaveChangesAsync();
        return Ok(new { user.Id, user.Name, user.Email, user.Role });
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteUser(string id)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound();
        var mappings = await _context.UserBuildingMappings.Where(m => m.UserId == id).ToListAsync();
        _context.UserBuildingMappings.RemoveRange(mappings);
        _context.Users.Remove(user);
        await _context.SaveChangesAsync();
        return Ok();
    }

    [HttpPost("{id}/buildings")]
    public async Task<IActionResult> AssignBuildings(string id, [FromBody] List<string> buildingIds)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound("User not found");

        // Remove existing mappings
        var existing = await _context.UserBuildingMappings.Where(m => m.UserId == id).ToListAsync();
        _context.UserBuildingMappings.RemoveRange(existing);

        // Add new mappings
        foreach (var bId in buildingIds)
        {
            _context.UserBuildingMappings.Add(new UserBuildingMapping
            {
                Id = Guid.NewGuid().ToString(),
                UserId = id,
                BuildingId = bId
            });
        }

        await _context.SaveChangesAsync();
        return Ok();
    }

    [HttpPut("{id}/buildings")]
    public async Task<IActionResult> UpdateUserBuildings(string id, [FromBody] List<string> buildingIds)
    {
        return await AssignBuildings(id, buildingIds);
    }

    [AllowAnonymous]
    [HttpPost("seed")]
    public async Task<IActionResult> Seed()
    {
        if (await _context.Users.AnyAsync())
            return Ok(new { message = "Users already seeded" });

        var admin = new User { Id = Guid.NewGuid().ToString(), Name = "Super Admin", Email = "admin@facility.com", Role = "Admin" };
        var worker = new User { Id = Guid.NewGuid().ToString(), Name = "John Worker", Email = "worker@facility.com", Role = "Technician" };
        var manager = new User { Id = Guid.NewGuid().ToString(), Name = "Facility Manager", Email = "manager@facility.com", Role = "Manager" };

        _context.Users.AddRange(admin, worker, manager);
        await _context.SaveChangesAsync();

        var building = await _context.Buildings.FirstOrDefaultAsync();
        if (building != null)
        {
            _context.UserBuildingMappings.Add(new UserBuildingMapping { UserId = admin.Id, BuildingId = building.Id });
            _context.UserBuildingMappings.Add(new UserBuildingMapping { UserId = worker.Id, BuildingId = building.Id });
            _context.UserBuildingMappings.Add(new UserBuildingMapping { UserId = manager.Id, BuildingId = building.Id });
            await _context.SaveChangesAsync();
        }

        return Ok(new { message = "Users seeded successfully" });
    }
}

public record UpdateRoleDto(string Role);
