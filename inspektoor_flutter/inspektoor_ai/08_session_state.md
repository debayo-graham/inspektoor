Session State
Last updated: 2026-03-14

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
  - Inspection execution UI (INSP-01 DONE — 2026-03-11):
    InspectionRunnerView renders all item types: single-check, multi-check,
    multiple-choice, numeric, comment-box, alphanumeric, signature, photo.
    Full feature list:
      · Custom colour tokens + inspInterStyle() text helper
      · Multi-check cards with pass/fail chips, failure note panel, multi-photo
        evidence (PhotoCaptureBox carousel + PhotoPreviewScreen with annotation)
      · Per-sub-check photoRequired and maxPhotos (per-check object, fallback
        to item-level config). Tap-to-toggle (first=pass, second=fail).
      · Comment-box with OCR camera (freeText mode), char count ring, quick-fill
      · Numeric and alphanumeric inputs with OCR camera (rescan always enabled)
      · Photo input type: multi-photo capture with preview/annotation
      · Photo annotation: freehand drawing, bakes strokes on Done (not save),
        label overlay visual-only (never baked into bytes)
      · Progress bar: directional blue overlay animation, multi-check base colors
      · Tablet layout (≥768px): side-by-side summary + step view, no AppBar
      · Deferred first build + memoized defectMap for fast page load
      · LoadingOverlay: animated pill card (waveform bars + bouncing dots +
        blur backdrop), shown pre-navigation for seamless loading UX
      · Back navigation: PopScope + confirm dialog with re-entrancy guard
      · Summary screen with per-item defect detection, pending INSP-02
    Files: lib/features/inspection/*, lib/common/components/*
  - Inspection submission (INSP-02/03/04 DONE — 2026-03-12):
    caSubmitInspection persists draft → inspections + inspection_items +
    inspection_item_values. Photos compressed and uploaded to Supabase Storage.
    Updates asset.last_inspected_at. Wired into summary view submit button.
  - Form flow (FORM-03, IN PROGRESS — 2026-03-14):
    5-screen flow: Landing → Search → Details → Confirmed → SelectAsset.
    · ChooseFormLandingPage: categories from DB, scrollable chips
    · FormSearchPage: live search, category filter, infinite scroll
    · FormDetailsPage: accordion step config panels, Preview button,
      "Use This Form" with ConfirmActionDialog + template duplication
    · FormPreviewScreen: standalone interactive preview (mobile + tablet),
      no FFAppState, reuses InspectionItemStep/SummaryView, purple banner
    · FormConfirmedPage: animated checkmark, "Select Asset & Begin" → SelectAssetPage
    · SelectAssetPage: search + filter + asset cards, sticky footer, overflow/cancel sheets
      Two entry points with context-aware drawer:
        - From drawer "Inspect Asset": hamburger menu + app drawer, standalone mode
        - From FormConfirmedPage flow: back button, form data passed through
      Layout uses Stack + Positioned (not Scaffold.bottomSheet) for sticky footer
    · ConfirmActionDialog: reusable Cancel/Confirm dialog (lib/common/components/)
    Files: lib/features/inspection_form/pages/*, lib/features/asset_selection/pages/*,
           lib/common/components/confirm_action_dialog.dart
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

1. FORM-03 remaining work  [current priority]
   All 5 screens + preview are built. SelectAssetPage done with context-aware drawer.
   Drawer "Inspect Asset" wired to SelectAssetPage. Remaining:
     a. Wire "Edit This Form" on FormConfirmedPage → navigate to form editor
     b. Wire "Go to Dashboard" on FormConfirmedPage + SelectAssetPage → navigate to dashboard
     c. DB fix: UPDATE inspection_templates SET org_id = NULL WHERE is_predefined = true
     d. Update card editor + create form to use category picker (hardcoded 'Vehicles')
     e. QA the full flow end-to-end (see backlog.md checklist)

2. Verify and close partially-built flows
   Before building new modules, confirm:
     - Asset list page actually loads and filters live data
     - Dashboard tiles display real query results, not defaults
     - Inspection form create/edit pages write to the database

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
