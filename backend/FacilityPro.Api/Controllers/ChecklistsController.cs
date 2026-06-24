using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FacilityPro.Infrastructure.Data;
using FacilityPro.Domain.Entities;

namespace FacilityPro.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ChecklistsController : ControllerBase
{
    private readonly FacilityDbContext _context;

    public ChecklistsController(FacilityDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] string? buildingId)
    {
        var query = _context.ChecklistTemplates
            .Include(ct => ct.Assignments)
            .AsQueryable();
        if (!string.IsNullOrEmpty(buildingId))
            query = query.Where(ct => ct.BuildingId == buildingId);
        return Ok(await query.OrderBy(ct => ct.Name).ToListAsync());
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(string id)
    {
        var template = await _context.ChecklistTemplates
            .Include(ct => ct.Assignments)
            .FirstOrDefaultAsync(ct => ct.Id == id);
        if (template == null) return NotFound();
        return Ok(template);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] ChecklistTemplate template)
    {
        _context.ChecklistTemplates.Add(template);
        await _context.SaveChangesAsync();
        return Ok(template);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(string id, [FromBody] ChecklistTemplate dto)
    {
        var template = await _context.ChecklistTemplates.FindAsync(id);
        if (template == null) return NotFound();
        template.Name = dto.Name;
        template.ItemsJson = dto.ItemsJson;
        await _context.SaveChangesAsync();
        return Ok(template);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(string id)
    {
        var template = await _context.ChecklistTemplates.FindAsync(id);
        if (template == null) return NotFound();
        _context.ChecklistTemplates.Remove(template);
        await _context.SaveChangesAsync();
        return Ok();
    }

    [HttpPost("{id}/assign")]
    public async Task<IActionResult> Assign(string id, [FromBody] ChecklistAssignment assignment)
    {
        var template = await _context.ChecklistTemplates.FindAsync(id);
        if (template == null) return NotFound();

        // Remove existing assignment for same entity if any
        var existing = await _context.ChecklistAssignments
            .FirstOrDefaultAsync(a => a.ChecklistTemplateId == id && a.EntityId == assignment.EntityId);
        if (existing != null) _context.ChecklistAssignments.Remove(existing);

        assignment.ChecklistTemplateId = id;
        _context.ChecklistAssignments.Add(assignment);
        await _context.SaveChangesAsync();
        return Ok(assignment);
    }

    [HttpDelete("{id}/assign/{entityId}")]
    public async Task<IActionResult> Unassign(string id, string entityId)
    {
        var assignment = await _context.ChecklistAssignments
            .FirstOrDefaultAsync(a => a.ChecklistTemplateId == id && a.EntityId == entityId);
        if (assignment == null) return NotFound();
        _context.ChecklistAssignments.Remove(assignment);
        await _context.SaveChangesAsync();
        return Ok();
    }
}
