using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace FacilityPro.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddDeveloperTicketHistory : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "DeveloperTicketHistories",
                columns: table => new
                {
                    Id = table.Column<string>(type: "TEXT", nullable: false),
                    TicketId = table.Column<string>(type: "TEXT", nullable: false),
                    Timestamp = table.Column<DateTime>(type: "TEXT", nullable: false),
                    Action = table.Column<string>(type: "TEXT", nullable: false),
                    Description = table.Column<string>(type: "TEXT", nullable: false),
                    PerformedByUserId = table.Column<string>(type: "TEXT", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DeveloperTicketHistories", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DeveloperTicketHistories_DeveloperTickets_TicketId",
                        column: x => x.TicketId,
                        principalTable: "DeveloperTickets",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_DeveloperTicketHistories_Users_PerformedByUserId",
                        column: x => x.PerformedByUserId,
                        principalTable: "Users",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateIndex(
                name: "IX_DeveloperTicketHistories_PerformedByUserId",
                table: "DeveloperTicketHistories",
                column: "PerformedByUserId");

            migrationBuilder.CreateIndex(
                name: "IX_DeveloperTicketHistories_TicketId",
                table: "DeveloperTicketHistories",
                column: "TicketId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "DeveloperTicketHistories");
        }
    }
}
