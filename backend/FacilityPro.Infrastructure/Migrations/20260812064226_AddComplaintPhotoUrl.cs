using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace FacilityPro.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddComplaintPhotoUrl : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "PhotoUrl",
                table: "Complaints",
                type: "TEXT",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "PhotoUrl",
                table: "Complaints");
        }
    }
}
