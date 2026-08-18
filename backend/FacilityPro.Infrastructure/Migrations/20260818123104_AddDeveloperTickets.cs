using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace FacilityPro.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddDeveloperTickets : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "DeveloperTickets",
                columns: table => new
                {
                    Id = table.Column<string>(type: "TEXT", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UserId = table.Column<string>(type: "TEXT", nullable: true),
                    DeviceOs = table.Column<string>(type: "TEXT", nullable: true),
                    AppVersion = table.Column<string>(type: "TEXT", nullable: true),
                    ScreenContext = table.Column<string>(type: "TEXT", nullable: true),
                    Description = table.Column<string>(type: "TEXT", nullable: false),
                    ScreenshotUrl = table.Column<string>(type: "TEXT", nullable: true),
                    Status = table.Column<string>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DeveloperTickets", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DeveloperTickets_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateIndex(
                name: "IX_DeveloperTickets_UserId",
                table: "DeveloperTickets",
                column: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "DeveloperTickets");
        }
    }
}
