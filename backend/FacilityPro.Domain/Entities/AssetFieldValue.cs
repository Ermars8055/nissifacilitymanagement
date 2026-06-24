namespace FacilityPro.Domain.Entities;

public class AssetFieldValue
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string AssetId { get; set; } = string.Empty;
    public string FieldId { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty;

    // Navigation
    public Asset? Asset { get; set; }
    public AssetCategoryField? Field { get; set; }
}
