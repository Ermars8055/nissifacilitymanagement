using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace FacilityPro.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddAntiSpoofing : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "FloorNumber",
                table: "Floors",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "LobbyQrCode",
                table: "Buildings",
                type: "TEXT",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<double>(
                name: "TargetLat",
                table: "Buildings",
                type: "REAL",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "TargetLng",
                table: "Buildings",
                type: "REAL",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "TaskAppEvents",
                columns: table => new
                {
                    Id = table.Column<string>(type: "TEXT", nullable: false),
                    TaskId = table.Column<string>(type: "TEXT", nullable: false),
                    EventType = table.Column<string>(type: "TEXT", nullable: false),
                    PackageName = table.Column<string>(type: "TEXT", nullable: true),
                    AwaySeconds = table.Column<int>(type: "INTEGER", nullable: false),
                    Timestamp = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TaskAppEvents", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TaskAppEvents_Tasks_TaskId",
                        column: x => x.TaskId,
                        principalTable: "Tasks",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "WorkerSessions",
                columns: table => new
                {
                    Id = table.Column<string>(type: "TEXT", nullable: false),
                    WorkerId = table.Column<string>(type: "TEXT", nullable: false),
                    BuildingId = table.Column<string>(type: "TEXT", nullable: false),
                    StartedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    IsActive = table.Column<bool>(type: "INTEGER", nullable: false),
                    LastScanAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    LastFloorNumber = table.Column<int>(type: "INTEGER", nullable: false),
                    LastAssetId = table.Column<string>(type: "TEXT", nullable: true),
                    ArrivalLat = table.Column<double>(type: "REAL", nullable: true),
                    ArrivalLng = table.Column<double>(type: "REAL", nullable: true),
                    DistanceFromBuilding = table.Column<double>(type: "REAL", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WorkerSessions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_WorkerSessions_Buildings_BuildingId",
                        column: x => x.BuildingId,
                        principalTable: "Buildings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_WorkerSessions_Users_WorkerId",
                        column: x => x.WorkerId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_TaskAppEvents_TaskId",
                table: "TaskAppEvents",
                column: "TaskId");

            migrationBuilder.CreateIndex(
                name: "IX_WorkerSessions_BuildingId",
                table: "WorkerSessions",
                column: "BuildingId");

            migrationBuilder.CreateIndex(
                name: "IX_WorkerSessions_WorkerId",
                table: "WorkerSessions",
                column: "WorkerId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "TaskAppEvents");

            migrationBuilder.DropTable(
                name: "WorkerSessions");

            migrationBuilder.DropColumn(
                name: "FloorNumber",
                table: "Floors");

            migrationBuilder.DropColumn(
                name: "LobbyQrCode",
                table: "Buildings");

            migrationBuilder.DropColumn(
                name: "TargetLat",
                table: "Buildings");

            migrationBuilder.DropColumn(
                name: "TargetLng",
                table: "Buildings");
        }
    }
}
