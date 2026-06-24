namespace FacilityPro.Domain.Entities;

public class AssetCategory
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string ClientId { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string? ParentCategoryId { get; set; }

    // Navigation
    public Client? Client { get; set; }
    public AssetCategory? ParentCategory { get; set; }
    public ICollection<AssetCategory> SubCategories { get; set; } = new List<AssetCategory>();
    public ICollection<AssetCategoryField> Fields { get; set; } = new List<AssetCategoryField>();
    public ICollection<Asset> Assets { get; set; } = new List<Asset>();
}
