Session State
Last updated: 2026-03-11

--------------------------------------------------
What the system currently is
--------------------------------------------------

Inspektoor is a Flutter + Supabase SaaS mobile application for asset
inspection management. It is built on FlutterFlow (generated scaffold)
with hand-written custom actions in lib/custom_code/.

The backend is a single Supabase project with a well-structured PostgreSQL
schema (24 tables/views), Row Level Security via JWT org_id claims, a
bootstrap RPC, an error-logging Edge Function, and server-side triggers
for auditing, timestamping, and asset limit enforcement.

The app is multi-tenant: every user belongs to an org, and org membership
and role are enforced at the database level. Billing and onboarding are
handled externally (out of scope for in-app development).

--------------------------------------------------
What major pieces exist
--------------------------------------------------

Working end-to-end:
  - Email/password authentication (login, create account)
  - Session bootstrap: resolves org and entitlement on login, populates
    global app state (org id, asset limit, entitlement status, plan)
  - Asset create and edit: full insert/update to the database including
    smart sync of attached inspection form templates
  - Inspection form schema manipulation: wrap/unwrap, card builder,
    add/replace/delete/reorder items — all in custom actions
  - In-memory inspection draft: init, step through items, GPS stamp, undo
  - Inspection execution UI (INSP-01 DONE): InspectionRunnerView renders
    all item types (single-check, multi-check, multiple-choice, numeric,
    comment-box, alphanumeric, signature). Photo type still stubbed.
    UI modernisation complete: custom colour tokens (inspection_tokens.dart),
    inspInterStyle() text helper, coloured multi-check cards with pass/fail
    chips, failure note panel with camera-only photo evidence (4:3 aspect
    ratio, dashed border empty state, full image display), context-aware
    multi-check footer (grey/blue/amber), "SECTION QUESTION" body label.
    Per-sub-check photoRequired and maxPhotos (each check object carries its
    own values, falls back to item-level config for old templates).
    Tap-to-toggle on sub-check cards (first tap = pass, second = fail).
    Hard reset of failure notes/photos when toggling back to pass.
    Title bar shows "INSPECTION" label above asset name.
    Back navigation guarded against double confirm dialog.
    Comment-box input with OCR camera (freeText mode, preserves case,
    collapses newlines), char count ring (amber warning at 90%), maxLength
    from config (default 500), quick-fill chips. OCR camera icon always
    allows rescan on all input types.
    Progress bar directional animation: blue overlay sweeps left-to-right
    on forward, right-to-left on backward. Multi-check current step shows
    sub-check pass/fail colors as base layer under blue overlay.
    Summary screen shown on completion with per-item defect detection,
    pending submission (INSP-02).
    File: lib/features/inspection/inspection_runner_view.dart
  - Global error logging: crashes sent to Supabase Edge Function → app_errors
  - Theme and UI system: Inter font, brand blue (#27AAE2), light mode only,
    responsive navigation (bottom bar on phone, vertical sidebar on tablet)

Partially built:
  - Asset list page (shell + search field, data query unconfirmed)
  - Dashboard (user greeting works, tile data source unconfirmed)
  - Inspection form template management (create page heavily wired,
    DB write path not confirmed in custom code)
  - Navigation component (tabs 1+2 routed, tabs 3+4 are placeholders)
  - OTP authentication (actions and DB table exist, page not confirmed)

--------------------------------------------------
What should be worked on next
--------------------------------------------------

1. Inspection execution  [highest priority]
   INSP-01 (page UI) is DONE as of 2026-03-10. Next steps:
     a. INSP-02: Write caSubmitInspection to persist the draft to inspections,
        inspection_items, and inspection_item_values
     b. INSP-03: Wire submission action into the summary view
     c. INSP-04: Update asset.last_inspected_at on submit

2. Verify and close partially-built flows
   Before building new modules, confirm:
     - Asset list page actually loads and filters live data
     - Dashboard tiles display real query results, not defaults
     - Inspection form create/edit pages write to the database
     - Choose-form page correctly calls initInspectionDraft and
       navigates to inspect_asset

3. Wire nav tabs 3 and 4
   Tab 3 (forms) and tab 4 (notifications) route to placeholder pages.
   Tab 3 should route to the inspection forms list once confirmed.
   Tab 4 is reserved for the notifications inbox (built last).

4. Defects, Operators, Consumption Logs, People Management
   These modules are entirely not started. Each has a schema and
   backlog tasks (DEF, OPR, CON, PPL) in 07_backlog.md.
   Suggested order: Defects first (tied to inspection completion),
   then Operators, then Consumption Logs, then People/roles.

5. Reminders and Notifications  [last]
   Requires schema design for reminders and notifications tables,
   a scheduled server-side delivery mechanism, an email provider
   (not yet present), an inbox page, and a nav badge.
   Blocked until the roles/permissions UI (PPL-02) is complete.

--------------------------------------------------
Reference files in this folder
--------------------------------------------------

  00_mission.md          Product intent and AI operating rules source
  01_rules.md            AI session rules
  02_architecture_map.md lib/ folder structure and feature groupings
  03_ui_system.md        Theme, colors, typography, reusable components
  04_schema_baseline.sql Full Supabase schema snapshot
  05_data_model_map.md   What tables are read/written from Flutter and what is not
  06_module_inventory.md Every module classified: implemented / partial / placeholder / not started
  07_backlog.md          Gap-based task list grouped by module
  08_session_state.md    This file
