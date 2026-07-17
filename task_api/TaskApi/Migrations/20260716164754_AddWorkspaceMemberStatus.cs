using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TaskApi.Migrations
{
    /// <inheritdoc />
    public partial class AddWorkspaceMemberStatus : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Backfill existing rows with "Accepted": everyone who was already a
            // workspace member joined before invites required acceptance, so they
            // must stay in (an empty value would hide their workspaces entirely).
            migrationBuilder.AddColumn<string>(
                name: "Status",
                table: "WorkspaceMembers",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "Accepted");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Status",
                table: "WorkspaceMembers");
        }
    }
}
