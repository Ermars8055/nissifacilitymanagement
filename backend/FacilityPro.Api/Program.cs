using FacilityPro.Api.Services;
using FacilityPro.Infrastructure.Data;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

const string FirebaseProjectId = "facilitypro-3f693";

// ── Authentication (Firebase JWT) ─────────────────────────────
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.Authority = $"https://securetoken.google.com/{FirebaseProjectId}";
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer   = true,
            ValidIssuer      = $"https://securetoken.google.com/{FirebaseProjectId}",
            ValidateAudience = true,
            ValidAudience    = FirebaseProjectId,
            ValidateLifetime = true,
        };
    });

builder.Services.AddAuthorization();

// ── Controllers ────────────────────────────────────────────────
builder.Services.AddControllers().AddJsonOptions(options =>
{
    options.JsonSerializerOptions.ReferenceHandler =
        System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles;
});
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// ── Database ───────────────────────────────────────────────────
builder.Services.AddDbContext<FacilityDbContext>(options =>
    options.UseSqlite("Data Source=facility.db"));

// ── CORS ───────────────────────────────────────────────────────
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
});

// ── Background Services ────────────────────────────────────────
builder.Services.AddHostedService<PmSchedulerService>();

var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI();

// Serve uploaded files (e.g. /uploads/abc123.jpg and .apk)
var provider = new Microsoft.AspNetCore.StaticFiles.FileExtensionContentTypeProvider();
provider.Mappings[".apk"] = "application/vnd.android.package-archive";
app.UseStaticFiles(new StaticFileOptions
{
    ContentTypeProvider = provider
});

app.UseCors("AllowAll");
app.UseAuthentication();
app.UseAuthorization();

// All controller routes require auth by default; seeds use [AllowAnonymous]
app.MapControllers().RequireAuthorization();

// Auto-migrate on startup
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<FacilityDbContext>();
    db.Database.Migrate();
}

app.Run();
