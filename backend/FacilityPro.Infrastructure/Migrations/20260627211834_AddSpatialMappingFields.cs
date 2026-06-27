using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace FacilityPro.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddSpatialMappingFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Color",
                table: "Rooms",
                type: "TEXT",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<double>(
                name: "Height",
                table: "Rooms",
                type: "REAL",
                nullable: false,
                defaultValue: 0.0);

            migrationBuilder.AddColumn<double>(
                name: "PosX",
                table: "Rooms",
                type: "REAL",
                nullable: false,
                defaultValue: 0.0);

            migrationBuilder.AddColumn<double>(
                name: "PosY",
                table: "Rooms",
                type: "REAL",
                nullable: false,
                defaultValue: 0.0);

            migrationBuilder.AddColumn<double>(
                name: "Width",
                table: "Rooms",
                type: "REAL",
                nullable: false,
                defaultValue: 0.0);

            migrationBuilder.AddColumn<double>(
                name: "CanvasHeight",
                table: "Floors",
                type: "REAL",
                nullable: false,
                defaultValue: 0.0);

            migrationBuilder.AddColumn<double>(
                name: "CanvasWidth",
                table: "Floors",
                type: "REAL",
                nullable: false,
                defaultValue: 0.0);

            migrationBuilder.AddColumn<string>(
                name: "FloorPlanImageUrl",
                table: "Floors",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "AssetPosX",
                table: "Assets",
                type: "REAL",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "AssetPosY",
                table: "Assets",
                type: "REAL",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Color",
                table: "Rooms");

            migrationBuilder.DropColumn(
                name: "Height",
                table: "Rooms");

            migrationBuilder.DropColumn(
                name: "PosX",
                table: "Rooms");

            migrationBuilder.DropColumn(
                name: "PosY",
                table: "Rooms");

            migrationBuilder.DropColumn(
                name: "Width",
                table: "Rooms");

            migrationBuilder.DropColumn(
                name: "CanvasHeight",
                table: "Floors");

            migrationBuilder.DropColumn(
                name: "CanvasWidth",
                table: "Floors");

            migrationBuilder.DropColumn(
                name: "FloorPlanImageUrl",
                table: "Floors");

            migrationBuilder.DropColumn(
                name: "AssetPosX",
                table: "Assets");

            migrationBuilder.DropColumn(
                name: "AssetPosY",
                table: "Assets");
        }
    }
}
