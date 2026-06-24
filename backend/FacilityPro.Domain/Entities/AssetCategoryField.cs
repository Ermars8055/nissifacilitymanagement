namespace FacilityPro.Domain.Entities;

public class AssetCategoryField
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string CategoryId { get; set; } = string.Empty;
    public string FieldName { get; set; } = string.Empty;
    public string DataType { get; set; } = "Text"; // "Text", "Number", "Date"
    public bool IsRequired { get; set; } = false;

    // Navigation
    public AssetCategory? Category { get; set; }
}
