using TaskApi.Models;

namespace TaskApi.Data
{
    /// <summary>
    /// Seeds a rich, representative dataset so the app has real rows to render:
    /// several users, two workspaces, projects in every state, tasks covering
    /// every status / priority / deadline case (overdue, today, upcoming, none),
    /// comments, an attachment, checklist items, a task dependency (blocked-by),
    /// tags and notifications (including a pending project invite).
    ///
    /// Idempotent: does nothing if any users already exist. To re-seed, empty the
    /// tables (or drop &amp; re-create the DB) and restart the API.
    ///
    /// All seeded users share the password below so you can sign in immediately.
    /// </summary>
    public static class DbSeeder
    {
        public const string DefaultPassword = "Password123!";
        public const string PrimaryEmail = "an.nguyen@acme.co";

        public static void Seed(AppDbContext db, string? webRootPath = null)
        {
            // Idempotent on the demo dataset specifically: seed runs even if the
            // DB already has other (e.g. manually-registered) users, but never
            // duplicates the demo data once the primary user exists.
            if (db.Users.Any(u => u.Email == PrimaryEmail)) return;

            var now = DateTime.UtcNow;
            var today = now.Date;
            string hash = BCrypt.Net.BCrypt.HashPassword(DefaultPassword);

            // ── Users ──────────────────────────────────────────────────────
            User NewUser(string name, string email) => new()
            {
                Id = Guid.NewGuid().ToString(),
                FullName = name,
                Email = email,
                PasswordHash = hash,
                CreatedAt = now,
                UpdatedAt = now,
            };

            var an = NewUser("An Nguyen", "an.nguyen@acme.co");     // ← primary login user
            var kim = NewUser("Kim Pham", "kim.pham@acme.co");
            var tran = NewUser("Tran Le", "tran.le@acme.co");
            var minh = NewUser("Minh Duong", "minh.duong@acme.co");
            var le = NewUser("Le Hoang", "le.hoang@acme.co");
            db.Users.AddRange(an, kim, tran, minh, le);
            db.SaveChanges();

            // ── Workspaces ─────────────────────────────────────────────────
            var wsAcme = new Workspace
            {
                Id = Guid.NewGuid().ToString(),
                Name = "Acme Studio",
                Description = "Product & brand team workspace.",
                OwnerId = an.Id,
                CreatedAt = now,
                UpdatedAt = now,
            };
            var wsSide = new Workspace
            {
                Id = Guid.NewGuid().ToString(),
                Name = "Side Projects",
                Description = "Personal experiments.",
                OwnerId = an.Id,
                CreatedAt = now,
                UpdatedAt = now,
            };
            // Owned by Kim — An has a PENDING invite here, to demo the
            // invite → accept flow (it stays hidden until An accepts).
            var wsBeta = new Workspace
            {
                Id = Guid.NewGuid().ToString(),
                Name = "Beta Labs",
                Description = "Kim's research workspace.",
                OwnerId = kim.Id,
                CreatedAt = now,
                UpdatedAt = now,
            };
            db.Workspaces.AddRange(wsAcme, wsSide, wsBeta);
            db.SaveChanges();

            WorkspaceMember WM(string wsId, string userId, string role,
                string status = "Accepted") => new()
            {
                WorkspaceId = wsId,
                UserId = userId,
                Role = role,
                Status = status,
                JoinedAt = now,
            };
            db.WorkspaceMembers.AddRange(
                WM(wsAcme.Id, an.Id, "Owner"),
                WM(wsAcme.Id, kim.Id, "Admin"),
                WM(wsAcme.Id, tran.Id, "Member"),
                WM(wsAcme.Id, minh.Id, "Member"),
                WM(wsAcme.Id, le.Id, "Member"),
                WM(wsSide.Id, an.Id, "Owner"),
                WM(wsSide.Id, kim.Id, "Member"),
                WM(wsBeta.Id, kim.Id, "Owner"),
                WM(wsBeta.Id, an.Id, "Member", "Pending") // ← invite awaiting accept
            );

            // ── Projects ───────────────────────────────────────────────────
            Project NewProject(string wsId, string name, string desc, string status) => new()
            {
                Id = Guid.NewGuid().ToString(),
                WorkspaceId = wsId,
                Name = name,
                Description = desc,
                Status = status,
                CreatedAt = now,
                UpdatedAt = now,
            };

            var pWeb = NewProject(wsAcme.Id, "Website Revamp",
                "Rebuild the marketing site on the new design system.", "Active");
            var pMobile = NewProject(wsAcme.Id, "Mobile App v2",
                "Ship the redesigned Flutter app.", "Active");
            var pQ2 = NewProject(wsAcme.Id, "Q2 Campaign",
                "Spring product launch campaign.", "Completed");
            var pDesign = NewProject(wsAcme.Id, "Design Ops 2026",
                "Standardise tokens, handoff & QA across squads.", "Active"); // An is invited (pending)
            var pPersonal = NewProject(wsSide.Id, "Personal Backlog",
                "Bits and bobs.", "Active");
            db.Projects.AddRange(pWeb, pMobile, pQ2, pDesign, pPersonal);
            db.SaveChanges();

            ProjectMember PM(string projId, string userId, string role, string status = "Accepted") => new()
            {
                ProjectId = projId,
                UserId = userId,
                Role = role,
                Status = status,
                JoinedAt = now,
            };
            db.ProjectMembers.AddRange(
                // Website Revamp — full team (drives the +N avatar stack)
                PM(pWeb.Id, an.Id, "Owner"),
                PM(pWeb.Id, kim.Id, "Admin"),
                PM(pWeb.Id, tran.Id, "Member"),
                PM(pWeb.Id, minh.Id, "Member"),
                PM(pWeb.Id, le.Id, "Member"),
                // Mobile App v2
                PM(pMobile.Id, an.Id, "Owner"),
                PM(pMobile.Id, minh.Id, "Member"),
                // Q2 Campaign (done)
                PM(pQ2.Id, an.Id, "Owner"),
                PM(pQ2.Id, kim.Id, "Member"),
                // Design Ops — owned by Kim (An sees it as the workspace owner)
                PM(pDesign.Id, kim.Id, "Owner"),
                PM(pDesign.Id, tran.Id, "Member"),
                // Personal
                PM(pPersonal.Id, an.Id, "Owner")
            );

            // ── Tasks ──────────────────────────────────────────────────────
            // Status strings are the app's canonical enum names: todo/doing/review/done.
            // Priorities: low/medium/high/critical.
            var order = 0;
            TaskItem T(string projId, string title, string? desc, string status,
                string priority, DateTime? deadline, string? assigneeId, string reporterId)
                => new()
                {
                    Id = Guid.NewGuid().ToString(),
                    ProjectId = projId,
                    Title = title,
                    Description = desc,
                    Status = status,
                    Priority = priority,
                    Order = order++,
                    Deadline = deadline,
                    AssigneeId = assigneeId,
                    ReporterId = reporterId,
                    CreatedAt = now,
                    UpdatedAt = now,
                };

            // Website Revamp — a full board across every status/priority/deadline
            var tMigrate = T(pWeb.Id, "Migrate CMS content to new schema",
                "Move all legacy pages onto the new content model.", "todo", "critical",
                today.AddDays(5).AddHours(17), kim.Id, an.Id);
            var tAudit = T(pWeb.Id, "Audit legacy icon set", null, "todo", "low",
                today.AddDays(14).AddHours(17), an.Id, an.Id);
            var tPhoto = T(pWeb.Id, "Collect brand photography", null, "todo", "medium",
                today.AddDays(8).AddHours(17), tran.Id, an.Id);
            var tCheckout = T(pWeb.Id, "Fix checkout validation bug",
                "Card errors are swallowed silently on submit.", "todo", "critical",
                today.AddDays(-3).AddHours(17), an.Id, kim.Id); // OVERDUE, assigned to An
            var tPr = T(pWeb.Id, "Review PR #212 — nav refactor", null, "todo", "medium",
                today.AddHours(18).AddMinutes(30), an.Id, tran.Id); // due today
            var tPalette = T(pWeb.Id, "Brand palette",
                "Lock the neutral ramp before header work.", "doing", "high",
                today.AddDays(-1).AddHours(17), kim.Id, an.Id); // overdue, blocks tokens
            var tTokens = T(pWeb.Id, "Design system tokens",
                "Define color, spacing & type tokens as a shared source of truth. " +
                "Export to both Figma variables and the Flutter theme.", "doing", "high",
                today.AddHours(17), an.Id, kim.Id); // due today 17:00, assigned to An
            var tNav = T(pWeb.Id, "Build responsive nav bar", null, "doing", "medium",
                today.AddDays(3).AddHours(17), minh.Id, an.Id);
            var tHero = T(pWeb.Id, "Homepage hero animation", null, "review", "high",
                today.AddDays(2).AddHours(17), tran.Id, an.Id);
            var tApiDocs = T(pWeb.Id, "Write API docs", null, "review", "low",
                null, an.Id, kim.Id);
            var tOnboard = T(pWeb.Id, "Update onboarding copy", null, "done", "medium",
                null, an.Id, an.Id);
            var tCi = T(pWeb.Id, "Set up CI pipeline", null, "done", "high",
                null, minh.Id, an.Id);

            // Mobile App v2
            var mPush = T(pMobile.Id, "Push notifications setup", null, "doing", "high",
                today.AddDays(4).AddHours(17), an.Id, an.Id);
            var mOnboard = T(pMobile.Id, "Onboarding screens", null, "todo", "medium",
                today.AddDays(6).AddHours(17), minh.Id, an.Id);
            var mAssets = T(pMobile.Id, "App store assets", null, "todo", "low",
                today.AddDays(10).AddHours(17), an.Id, an.Id);
            var mCrash = T(pMobile.Id, "Crash on login (Android)",
                "NPE on cold start when token expired.", "review", "critical",
                today.AddDays(-2).AddHours(17), an.Id, minh.Id); // overdue

            // Q2 Campaign — all done (→ 100% progress)
            var qEmail = T(pQ2.Id, "Launch email campaign", null, "done", "high", null, kim.Id, an.Id);
            var qLanding = T(pQ2.Id, "Landing page A/B test", null, "done", "medium", null, an.Id, an.Id);
            var qReport = T(pQ2.Id, "Post-campaign report", null, "done", "low", null, an.Id, an.Id);

            var allTasks = new[]
            {
                tMigrate, tAudit, tPhoto, tCheckout, tPr, tPalette, tTokens, tNav,
                tHero, tApiDocs, tOnboard, tCi, mPush, mOnboard, mAssets, mCrash,
                qEmail, qLanding, qReport,
            };
            db.Tasks.AddRange(allTasks);
            db.SaveChanges();

            // ── Comments (on Design system tokens) ─────────────────────────
            db.Comments.AddRange(
                new Comment
                {
                    Id = Guid.NewGuid().ToString(),
                    TaskId = tTokens.Id,
                    UserId = kim.Id,
                    Content = "Can we lock the neutrals first? Blocks the header work.",
                    CreatedAt = now.AddHours(-2),
                    UpdatedAt = now.AddHours(-2),
                },
                new Comment
                {
                    Id = Guid.NewGuid().ToString(),
                    TaskId = tTokens.Id,
                    UserId = an.Id,
                    Content = "On it — pushing the ramp this afternoon.",
                    CreatedAt = now.AddMinutes(-3),
                    UpdatedAt = now.AddMinutes(-3),
                },
                new Comment
                {
                    Id = Guid.NewGuid().ToString(),
                    TaskId = tCheckout.Id,
                    UserId = kim.Id,
                    Content = "This is blocking the release — can you prioritise today?",
                    CreatedAt = now.AddHours(-5),
                    UpdatedAt = now.AddHours(-5),
                }
            );

            // ── Attachment ─────────────────────────────────────────────────
            // Write a real file to wwwroot/uploads, otherwise the row would point
            // at a URL that 404s and the download button would look broken.
            const string demoFileName = "tokens-spec.txt";
            long demoFileSize = 0;
            if (!string.IsNullOrWhiteSpace(webRootPath))
            {
                try
                {
                    var uploadsDir = Path.Combine(webRootPath, "uploads");
                    Directory.CreateDirectory(uploadsDir);
                    var demoPath = Path.Combine(uploadsDir, demoFileName);
                    File.WriteAllText(demoPath,
                        "TaskFlow — design tokens spec (demo attachment)\n\n" +
                        "Color scales, spacing scale and the typography ramp live here.\n");
                    demoFileSize = new FileInfo(demoPath).Length;
                }
                catch
                {
                    // Non-fatal: seeding must not fail because of the filesystem.
                }
            }

            db.Attachments.Add(new Attachment
            {
                Id = Guid.NewGuid().ToString(),
                TaskId = tTokens.Id,
                FileName = demoFileName,
                // Relative — the app resolves it against the API host.
                FileUrl = $"/uploads/{demoFileName}",
                FileSize = demoFileSize,
                UploadedById = an.Id,
                UploadedAt = now.AddHours(-6),
            });

            // ── Checklist items ────────────────────────────────────────────
            ChecklistItem CL(string taskId, string title, bool done) => new()
            {
                Id = Guid.NewGuid().ToString(),
                TaskId = taskId,
                Title = title,
                IsCompleted = done,
            };
            db.ChecklistItems.AddRange(
                CL(tTokens.Id, "Color scales", true),
                CL(tTokens.Id, "Spacing scale", true),
                CL(tTokens.Id, "Typography ramp", false),
                CL(tMigrate.Id, "Inventory legacy pages", true),
                CL(tMigrate.Id, "Map fields to new schema", true),
                CL(tMigrate.Id, "Write migration script", false),
                CL(tMigrate.Id, "Dry run on staging", false),
                CL(tMigrate.Id, "Verify redirects", false),
                CL(tMigrate.Id, "Cutover", false)
            );

            // ── Tags ───────────────────────────────────────────────────────
            Tag NewTag(string name, string color) => new()
            {
                Id = Guid.NewGuid().ToString(),
                WorkspaceId = wsAcme.Id,
                Name = name,
                Color = color,
            };
            var tagDesign = NewTag("Design", "#2F6BFF");
            var tagBackend = NewTag("Backend", "#22A35B");
            var tagBug = NewTag("Bug", "#E5484D");
            var tagMarketing = NewTag("Marketing", "#E08A13");
            db.Tags.AddRange(tagDesign, tagBackend, tagBug, tagMarketing);
            db.SaveChanges();

            db.TaskTags.AddRange(
                new TaskTag { TaskId = tTokens.Id, TagId = tagDesign.Id },
                new TaskTag { TaskId = tHero.Id, TagId = tagDesign.Id },
                new TaskTag { TaskId = tMigrate.Id, TagId = tagBackend.Id },
                new TaskTag { TaskId = tCheckout.Id, TagId = tagBug.Id },
                new TaskTag { TaskId = mCrash.Id, TagId = tagBug.Id },
                new TaskTag { TaskId = qEmail.Id, TagId = tagMarketing.Id }
            );

            // ── Task dependency: "Design system tokens" is blocked by "Brand palette"
            db.TaskDependencies.Add(new TaskDependency
            {
                Id = Guid.NewGuid().ToString(),
                PredecessorTaskId = tPalette.Id, // blocks
                SuccessorTaskId = tTokens.Id,    // blocked
                DependencyType = "FS",
            });

            // ── Notifications for An (unread count = 3: invite, comment, assign)
            Notification N(string type, string message, bool isRead, string? relatedId, DateTime createdAt) => new()
            {
                Id = Guid.NewGuid().ToString(),
                UserId = an.Id,
                Type = type,
                Message = message,
                IsRead = isRead,
                RelatedId = relatedId,
                CreatedAt = createdAt,
            };
            db.Notifications.AddRange(
                // Workspace invite → Accept/Decline in the Inbox; "Beta Labs" only
                // shows up in the workspace switcher once accepted.
                N("Invite", "Kim Pham invited you to workspace 'Beta Labs'", false, wsBeta.Id, now.AddMinutes(-5)),
                N("Comment", "Kim Pham commented on Design system tokens", false, tTokens.Id, now.AddHours(-2)),
                N("Assign", "Tran Le assigned you Review PR #212 — nav refactor", false, tPr.Id, now.AddHours(-4)),
                N("TaskCompleted", "You completed Update onboarding copy", true, tOnboard.Id, now.AddDays(-1)),
                N("Deadline", "Deadline moved on Q2 Campaign", true, pQ2.Id, now.AddDays(-1))
            );

            db.SaveChanges();
        }
    }
}
