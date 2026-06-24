# Admin Dashboard Plan

## Analysis: What's Inconsistent

### 1. No real authentication layer
`User` has no `Password` field. Flutter login is just role-selection UI — anyone can pick Admin and walk in. There's no `POST /login` endpoint.

### 2. No "company-level" super admin concept
The current roles are `Admin / Manager / Technician` — all scoped to a building. There's no entity for the facility management company itself. The company needs a `SuperAdmin` who sees everything across all clients and buildings.

### 3. Missing CRUD on Clients & Buildings
`HierarchyController` only has `GET` for clients — you can read them but can't create, edit or delete clients or buildings via the API. The seed endpoint is the only way to add data.

### 4. Asset categories are `ClientId`-scoped but seeded globally
`AssetCategory` has a `ClientId` field, but the seed only creates categories for `client1`. New clients get zero categories. This will break asset onboarding for any second client.

### 5. No cross-building view
`DashboardController` filters by `buildingId`. There's no API that gives totals across all buildings — no god-mode summary.

---

## Proposed Solution

### Track A — Backend gaps to fill (minimal)

| What | Why |
|---|---|
| Add `PasswordHash` to `User` + `POST /api/users/login` | Real auth, even simple |
| Add `POST/PUT/DELETE /api/hierarchy/clients` | Create & manage clients |
| Add `POST/PUT/DELETE /api/hierarchy/buildings` | Create & manage buildings |
| Add `GET /api/hierarchy/buildings` (all, no filter) | God-mode building list |
| Add `SuperAdmin` role | Company-level role, sees all |
| Make asset categories global (no `ClientId`) OR auto-clone on client create | Fix the category inconsistency |
| Add `GET /api/dashboard/global` | Cross-building KPIs |

### Track B — React Admin Dashboard (new app)

A standalone React app at `/admin/` — separate from Flutter, talks to the same API.

**Stack:** Vite + React + TypeScript + Tailwind CSS

**Pages / Sidebar:**
```
SuperAdmin Portal
├── Dashboard        → KPIs: total clients, buildings, assets, open issues
├── Clients          → Table + Create/Edit/Delete
├── Buildings        → Table (all clients), Create, drill into floors/rooms
├── Users            → Table, Create user, assign to buildings, set role
├── Assets           → Cross-building asset table, filter by client/building/category
└── Settings         → Seed controls, category management
```

**Login:** SuperAdmin-only login page before accessing the portal.

---

## Decision Needed Before Building

**Are `AssetCategory` records global or per-client?**

- **Option A — Global categories** (simpler): Remove `ClientId` from `AssetCategory`. All clients share the same 52 categories. The company manages the master list from the React admin.
- **Option B — Per-client categories** (flexible): Keep `ClientId`, auto-seed a fresh copy of the 52 categories when a new client is created. Clients can customize theirs.

Option A is the right call 90% of the time for a CAFM product unless clients need heavily custom schemas.

Also decide: real password auth or a fixed SuperAdmin credential for now?
