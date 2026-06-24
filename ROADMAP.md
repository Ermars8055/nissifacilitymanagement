# FacilityPro — Full Audit & Development Roadmap

**Audited:** 2026-06-22
**Stack:** Flutter (mobile/web) · ASP.NET Core .NET 10 (backend) · React + Vite (admin) · SQLite + EF Core
**Auth:** Firebase Authentication + Google Sign-In

---

## Audit Findings Summary

### Critical Bugs
| # | Bug | Location |
|---|---|---|
| C1 | Login is fake — ignores credentials, no real auth | `login_screen.dart` |
| C2 | Add Task button never calls the API — tasks are never saved | `add_task_screen.dart` |
| C3 | No `GET /Tasks/{id}` endpoint — Flutter fetches ALL tasks to show one | `TasksController.cs` |
| C4 | No `GET /Complaints/{id}` endpoint — Flutter fetches ALL complaints to show one | `ComplaintsController.cs` |
| C5 | SessionManager is in-memory only — browser refresh kills the session | `session_manager.dart` |
| C6 | No route guard — unauthenticated users can reach any screen | `app_router.dart` |

### Logic Errors
| # | Error | Location |
|---|---|---|
| L1 | Tasks have no `AssignedToId` — every worker sees ALL building tasks | `WorkerTask` entity + `TasksController` |
| L2 | No "Mark In Progress" action — task jumps Pending → Completed only | `task_details_screen.dart` |
| L3 | Complaint details is read-only — no status update action for worker | `complaint_details_screen.dart` |
| L4 | Asset details shows hardcoded fake maintenance history + fake PDFs | `asset_details_screen.dart` |
| L5 | Dashboard building health score is hardcoded `"96%"` | `DashboardController.cs` line 77 |
| L6 | Integer division bug in complaint resolution rate (C# truncates) | `DashboardController.cs` line 38 |
| L7 | Add Task form missing `scheduledTime` field and `assignedToName` field | `add_task_screen.dart` |
| L8 | Admin floor navigation uses `context.go()` — breaks back stack | `building_details_screen.dart` |

### Screens — Old UI / Stub
| Screen | State |
|---|---|
| `admin_dashboard_screen.dart` | Old blue UI |
| `add_task_screen.dart` | Old blue UI + non-functional |
| `complaint_details_screen.dart` | Raw default Flutter AppBar, no actions |
| `asset_details_screen.dart` | Raw default Flutter AppBar + fake data |
| `work_order_list_screen.dart` | Pure stub — shows EmptyState widget |
| `scheduler_dashboard_screen.dart` | Stub |
| `pm_dashboard_screen.dart` | Stub |
| `reports_dashboard_screen.dart` | Stub |
| `user_list_screen.dart` | Stub |
| `settings_screen.dart` | Stub |
| `notification_center_screen.dart` | Stub |
| `checklist_library_screen.dart` | Stub |
| `client_list_screen.dart` | Old blue UI |

### Backend Missing Endpoints
| Endpoint | Needed For |
|---|---|
| `GET /Tasks/{id}` | Single task fetch (efficiency + correctness) |
| `GET /Complaints/{id}` | Single complaint fetch |
| `GET /Users/by-email?email=X` | Firebase auth link — look up user by Firebase email |
| `PUT /Assets/{id}/status` | Update asset status from app |
| `DELETE /Hierarchy/floors/{id}` | Allow removing floors |
| `DELETE /Hierarchy/rooms/{id}` | Allow removing rooms |
| `DELETE /Assets/{id}` | Allow removing assets |

---

## Phase 1 — Core App: Authentication + Critical Flows
> Goal: App is genuinely usable end-to-end. Login works. Tasks are real. Data persists.

### 1.1 — Firebase Authentication + Google Sign-In

**Flutter packages to add:**
```yaml
firebase_core: latest
firebase_auth: latest
google_sign_in: latest
```

**Flow:**
1. User taps "Continue with Google" on login screen
2. Firebase Google Sign-In popup/redirect launches
3. On success, Firebase returns `UserCredential` with `user.email`
4. Flutter calls `GET /api/Users/by-email?email={email}` to fetch the backend user profile (role, id, assigned buildings)
5. If user not found in backend → show "Account not set up" error (admin must create them first)
6. If found → `SessionManager.setUser(backendUser)` + navigate based on role:
   - Admin / Super Admin → `/admin-dashboard`
   - Manager / Supervisor / Technician → `/select-building`

**Backend changes:**
- Add `GET /api/Users/by-email?email=X` to `UsersController.cs`
- Add `FirebaseUid` field to `User` entity (optional, for future JWT verification)

**Flutter changes:**
- `login_screen.dart` — replace fake `_signIn()` with real Firebase Google Sign-In call
- `role_selector_screen.dart` — DELETE this screen (was dev-only shortcut, replaced by real auth)
- `forgot_password_screen.dart` — wire to `FirebaseAuth.instance.sendPasswordResetEmail()`
- `session_manager.dart` — store Firebase `User` object alongside backend user; add `isLoggedIn` getter
- `app_router.dart` — add redirect guard: if `!SessionManager().isLoggedIn` and route is not `/login`, redirect to `/login`
- Remove `/role-selector` route entirely

**Files to create/modify:**
```
lib/core/services/auth_service.dart          (new — wraps Firebase + backend lookup)
lib/core/session/session_manager.dart        (add isLoggedIn, store firebaseUser)
lib/features/auth/login_screen.dart          (replace _signIn with Google auth)
lib/features/auth/forgot_password_screen.dart (wire Firebase reset)
lib/core/routes/app_router.dart              (add redirect guard, remove role-selector)
backend/FacilityPro.Api/Controllers/UsersController.cs (add by-email endpoint)
```

---

### 1.2 — Fix Task Creation (add_task_screen.dart)

**What's broken:** Button shows fake snackbar, never calls API. Missing required fields.

**Fix:**
- Add `DateTimePicker` for `scheduledTime`
- Add assignee dropdown — fetch users from `GET /Users`, filter by role
- Wire "Create Task" button to `POST /Tasks` with full payload:
  ```json
  {
    "title": "...",
    "buildingId": "...",
    "entityId": "...",
    "entityType": "Asset|Room|Floor|Building",
    "entityName": "...",
    "assignedToName": "...",
    "assignedToId": "...",
    "scheduledTime": "2026-06-22T09:00:00Z",
    "status": "Pending"
  }
  ```
- Retheme to cream/forest green design

---

### 1.3 — Add AssignedToId to Tasks (filter by user)

**Backend:**
- Add `AssignedToId` string property to `WorkerTask` entity
- Add EF migration
- Update `GET /Tasks` to support `?userId=X` query param so workers only see their tasks
- Update `POST /Tasks` to accept `assignedToId`

**Flutter:**
- `task_list_screen.dart` — pass `userId = SessionManager().currentUser['id']` in the tasks fetch

---

### 1.4 — Add Missing Single-Item Backend Endpoints

**`TasksController.cs`:**
```csharp
GET /api/Tasks/{id}   → return single task by id
```

**`ComplaintsController.cs`:**
```csharp
GET /api/Complaints/{id}   → return single complaint by id
```

**Flutter:**
- `task_details_screen.dart` — replace `firstWhere` client-side filter with `GET /Tasks/{id}`
- `complaint_details_screen.dart` — replace client-side filter with `GET /Complaints/{id}`

---

### 1.5 — Retheme + Fix Broken Screens

| Screen | Changes |
|---|---|
| `admin_dashboard_screen.dart` | Full cream/forest green retheme |
| `add_task_screen.dart` | Retheme + wire to API (done in 1.2) |
| `complaint_details_screen.dart` | Retheme + add "Update Status" action (calls `PUT /Complaints/{id}/status`) |
| `asset_details_screen.dart` | Retheme + remove fake data + show real QR code via `qr_flutter` |

---

### 1.6 — Fix Backend Logic Bugs

**`DashboardController.cs`:**
- Fix integer division: `(double)(totalComplaints - openComplaints) / totalComplaints * 100`
- Replace hardcoded `buildingHealth = "96%"` with real calculation:
  ```
  health = 100 - (openComplaints / max(totalAssets, 1) * 100) clamped to 0-100
  ```

---

### 1.7 — Add Route Guard

**`app_router.dart`:**
```dart
redirect: (context, state) {
  final loggedIn = SessionManager().isLoggedIn;
  final onAuth = state.matchedLocation.startsWith('/login') ||
                 state.matchedLocation.startsWith('/forgot');
  if (!loggedIn && !onAuth) return '/login';
  if (loggedIn && onAuth) return '/dashboard';
  return null;
}
```

---

## Phase 2 — Complete Key Flows
> Goal: All existing screens have working actions. No dead-end states.

### 2.1 — Add "Mark In Progress" to Task Details
- Task details screen shows "Start Task" button for `Pending` tasks (no QR needed, just status update)
- "Scan QR & Complete" remains the final step
- Calls `PUT /Tasks/{id}/status` with `{ "status": "In Progress" }`

### 2.2 — Complaint Details — Add Worker Actions
- Field worker can update status: "In Progress" → "Resolved"
- Button: "Mark as Resolved" calls `PUT /Complaints/{id}/status`
- Show assigned technician name if set

### 2.3 — Asset Details — Real Data
- Replace hardcoded maintenance history with tasks linked to this asset's `entityId`
  - Query: `GET /Tasks?entityId=X` (add this filter to backend)
- Remove fake documents section
- Show real QR code using `QrImageView`
- Show real category fields from `fieldValues`

### 2.4 — Delete Support (Swipe to Delete)
- Add `DELETE /Hierarchy/floors/{id}` and `DELETE /Hierarchy/rooms/{id}` to backend
- Add `DELETE /Assets/{id}` to backend
- Add swipe-to-delete gesture on floor cards and room cards

### 2.5 — Settings Screen
- Show current user name, email, role
- "Change Building" button → navigates to `/select-building`
- "Sign Out" button → Firebase signOut + `SessionManager.clear()` + navigate to `/login`

### 2.6 — Admin Dashboard Retheme
- Already in Phase 1.5 but full user management: create user, assign buildings
- Wire `CheckboxListTile` selection to forest green

---

## Phase 3 — Build Out Stub Screens
> Goal: Every screen in the nav is real and useful.

### 3.1 — Reports Dashboard
**Data sources (all from existing API):**
- Tasks completed this week — `GET /Tasks?buildingId=X` group by date
- Complaints by priority — `GET /Complaints?buildingId=X` group by priority
- Asset count by category — `GET /Assets/building/X` group by category
- Open vs Resolved complaints — pie chart

**UI:** Line chart (tasks/week), pie chart (complaints), bar chart (assets by category)
**Package:** `fl_chart` (already used in admin? or add it)

### 3.2 — Work Orders List
- Work orders = tasks with `entityType == "Asset"`
- Reuse task list screen pattern but filter by entity type
- No new backend needed

### 3.3 — Checklist Library
- List checklist templates from `GET /Checklists`
- Allow viewing template items (read-only for workers)
- Admins can create/edit via the React admin panel

### 3.4 — Notification Center
- Simple list of recent activity using the existing `recentActivity` data from `GET /Dashboard`
- Refresh on pull
- Tap a task → navigate to task details; tap a complaint → complaint details

### 3.5 — User List (standalone)
- Move user management out of `admin_dashboard_screen` into this dedicated screen
- `admin_dashboard_screen` becomes a proper stat/KPI overview
- Reuse user list logic from admin dashboard

### 3.6 — PM Scheduler Dashboard
- List `GET /PmSchedules` — show active/inactive schedules
- Toggle active/inactive via `PUT /PmSchedules/{id}/toggle`
- "Generate Tasks" button via `POST /PmSchedules/generate-tasks`

### 3.7 — Client List
- Retheme `client_list_screen.dart` to cream/forest green
- Wire "Add Client" form to `POST /Hierarchy/clients`
- Tap → `client_details_screen.dart` showing client's buildings

---

## Firebase Setup Checklist

Before starting Phase 1.1, complete these steps:

- [ ] Create Firebase project at console.firebase.google.com
- [ ] Enable Authentication → Google Sign-In provider
- [ ] Add Flutter app (iOS + Android + Web) to Firebase project
- [ ] Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
- [ ] Add `firebase_options.dart` via `flutterfire configure`
- [ ] Add SHA-1 fingerprint for Android (debug + release)
- [ ] Add authorized domain for web (localhost + production domain)
- [ ] Add packages: `firebase_core`, `firebase_auth`, `google_sign_in`
- [ ] Initialize Firebase in `main.dart` before `runApp()`

---

## File Change Index (Phase 1 only)

### New Files
```
lib/core/services/auth_service.dart
```

### Modified Files
```
lib/core/session/session_manager.dart       (add isLoggedIn, firebaseUser)
lib/core/routes/app_router.dart             (add redirect guard, remove role-selector)
lib/features/auth/login_screen.dart         (Google Sign-In button)
lib/features/auth/forgot_password_screen.dart (Firebase reset)
lib/features/tasks/add_task_screen.dart     (API wire + date picker + assignee)
lib/features/tasks/task_details_screen.dart (fetch by ID)
lib/features/complaints/complaint_details_screen.dart (fetch by ID + status action)
lib/features/assets/asset_details_screen.dart (real data + QR)
lib/features/admin/admin_dashboard_screen.dart (retheme)
backend/.../Controllers/TasksController.cs  (GET /{id}, AssignedToId filter)
backend/.../Controllers/ComplaintsController.cs (GET /{id})
backend/.../Controllers/UsersController.cs  (GET by-email)
backend/.../Controllers/DashboardController.cs (fix math bugs)
backend/.../Domain/Entities/WorkerTask.cs   (add AssignedToId)
```

### Deleted Files
```
lib/features/auth/role_selector_screen.dart  (replaced by real Firebase auth)
```

---

## Notes

- The React admin dashboard is separate and largely complete — it does not need Firebase auth for now (admin-only internal tool, can use the existing role selector pattern or a separate admin auth)
- `ApiClient.dart` base URL `http://localhost:5294/api` must be updated to a real server URL before production
- SQLite is fine for development but should be migrated to PostgreSQL or SQL Server before production deployment
- All QR codes are already auto-generated by the backend on floor/room/asset creation — the QR flow is correct end-to-end
