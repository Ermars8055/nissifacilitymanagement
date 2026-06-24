using FacilityPro.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace FacilityPro.Infrastructure.Data;

public class FacilityDbContext : DbContext
{
    public FacilityDbContext(DbContextOptions<FacilityDbContext> options) : base(options) { }

    public DbSet<Client> Clients { get; set; } = null!;
    public DbSet<Building> Buildings { get; set; } = null!;
    public DbSet<Floor> Floors { get; set; } = null!;
    public DbSet<Room> Rooms { get; set; } = null!;
    public DbSet<ChecklistMapping> ChecklistMappings { get; set; } = null!;
    
    // Assets
    public DbSet<AssetCategory> AssetCategories { get; set; } = null!;
    public DbSet<AssetCategoryField> AssetCategoryFields { get; set; } = null!;
    public DbSet<Asset> Assets { get; set; } = null!;
    public DbSet<AssetFieldValue> AssetFieldValues { get; set; } = null!;

    // Workflow
    public DbSet<WorkerTask> Tasks { get; set; } = null!;
    public DbSet<Complaint> Complaints { get; set; } = null!;
    public DbSet<PmSchedule> PmSchedules { get; set; } = null!;
    public DbSet<ChecklistTemplate> ChecklistTemplates { get; set; } = null!;
    public DbSet<ChecklistAssignment> ChecklistAssignments { get; set; } = null!;

    // Users
    public DbSet<User> Users { get; set; } = null!;
    public DbSet<UserBuildingMapping> UserBuildingMappings { get; set; } = null!;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        
        // Define explicit relations if needed, EF Core will auto-wire based on navigation properties
        modelBuilder.Entity<Client>()
            .HasMany(c => c.Buildings)
            .WithOne(b => b.Client)
            .HasForeignKey(b => b.ClientId);

        modelBuilder.Entity<Building>()
            .HasMany(b => b.Floors)
            .WithOne(f => f.Building)
            .HasForeignKey(f => f.BuildingId);

        modelBuilder.Entity<Floor>()
            .HasMany(f => f.ChecklistMappings)
            .WithOne(cm => cm.Floor)
            .HasForeignKey(cm => cm.FloorId);

        modelBuilder.Entity<Floor>()
            .HasMany(f => f.Rooms)
            .WithOne(r => r.Floor)
            .HasForeignKey(r => r.FloorId);

        modelBuilder.Entity<Room>()
            .HasMany(r => r.Assets)
            .WithOne(a => a.Room)
            .HasForeignKey(a => a.RoomId);

        modelBuilder.Entity<Room>()
            .HasMany(r => r.ChecklistMappings)
            .WithOne(cm => cm.Room)
            .HasForeignKey(cm => cm.RoomId);
            
        modelBuilder.Entity<Asset>()
            .HasMany(a => a.ChecklistMappings)
            .WithOne(cm => cm.Asset)
            .HasForeignKey(cm => cm.AssetId);

        // Assets Configuration
        modelBuilder.Entity<AssetCategory>()
            .HasOne(ac => ac.ParentCategory)
            .WithMany(ac => ac.SubCategories)
            .HasForeignKey(ac => ac.ParentCategoryId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<AssetCategory>()
            .HasMany(ac => ac.Fields)
            .WithOne(f => f.Category)
            .HasForeignKey(f => f.CategoryId);

        modelBuilder.Entity<AssetCategory>()
            .HasMany(ac => ac.Assets)
            .WithOne(a => a.Category)
            .HasForeignKey(a => a.CategoryId);

        modelBuilder.Entity<Asset>()
            .HasMany(a => a.FieldValues)
            .WithOne(fv => fv.Asset)
            .HasForeignKey(fv => fv.AssetId);

        modelBuilder.Entity<AssetFieldValue>()
            .HasOne(fv => fv.Field)
            .WithMany()
            .HasForeignKey(fv => fv.FieldId);

        // Checklist Templates
        modelBuilder.Entity<ChecklistTemplate>()
            .HasMany(ct => ct.Assignments)
            .WithOne(a => a.Template)
            .HasForeignKey(a => a.ChecklistTemplateId);

        // User Mappings
        modelBuilder.Entity<UserBuildingMapping>()
            .HasOne(um => um.User)
            .WithMany(u => u.BuildingMappings)
            .HasForeignKey(um => um.UserId);

        modelBuilder.Entity<UserBuildingMapping>()
            .HasOne(um => um.Building)
            .WithMany()
            .HasForeignKey(um => um.BuildingId);
    }
}
