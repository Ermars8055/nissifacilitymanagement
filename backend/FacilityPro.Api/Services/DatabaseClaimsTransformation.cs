using System.Security.Claims;
using FacilityPro.Infrastructure.Data;
using Microsoft.AspNetCore.Authentication;
using Microsoft.EntityFrameworkCore;

namespace FacilityPro.Api.Services;

public class DatabaseClaimsTransformation : IClaimsTransformation
{
    private readonly FacilityDbContext _context;

    public DatabaseClaimsTransformation(FacilityDbContext context)
    {
        _context = context;
    }

    public async Task<ClaimsPrincipal> TransformAsync(ClaimsPrincipal principal)
    {
        // If they are not authenticated, or they already have a Role claim, do nothing
        if (!principal.Identity?.IsAuthenticated ?? true)
            return principal;

        if (principal.HasClaim(c => c.Type == ClaimTypes.Role))
            return principal;

        // Firebase JWTs typically store the email in ClaimTypes.Email or just "email"
        var email = principal.FindFirst(ClaimTypes.Email)?.Value 
                 ?? principal.FindFirst("email")?.Value;

        if (string.IsNullOrWhiteSpace(email))
            return principal;

        // Look up the user in the database by email
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == email.ToLower());

        if (user != null && !string.IsNullOrWhiteSpace(user.Role))
        {
            // Clone the principal to avoid mutating the original
            var clone = principal.Clone();
            var newIdentity = (ClaimsIdentity?)clone.Identity;

            // Add the Role claim
            newIdentity?.AddClaim(new Claim(ClaimTypes.Role, user.Role));
            return clone;
        }

        return principal;
    }
}
