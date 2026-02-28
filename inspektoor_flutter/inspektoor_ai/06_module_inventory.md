Module Inventory
Generated: 2026-02-28
Classification based on: pages, custom actions, backend tables, and app state
as found in the repository. No intent is assumed.

Status definitions:
  implemented          — page UI exists, data wired, actions functional
  partially implemented — page or logic exists but flow is incomplete
  placeholder only     — file exists but contains no real UI or logic
  not started          — no page, no custom action, no wiring exists

--------------------------------------------------
IMPLEMENTED
--------------------------------------------------

Authentication — Login
  Page:    pages/authentication/login/
  Action:  custom_code/actions/ca_login.dart
  Detail:  Email/password sign-in via supa.auth.signInWithPassword().
           Client-side validation, normalized error codes, friendly messages.
           Session populated automatically by FlutterFlow auth layer.

Authentication — Create Account
  Page:    pages/authentication/create_account/
  Action:  custom_code/actions/ca_create_account.dart
  Detail:  Email/password sign-up via supa.auth.signUp().
           Validates email format, password match, minimum length.
           Server trigger handle_new_auth_user creates app_users row.

Session Bootstrap
  Page:    pages/authentication/bootstrap_page/
  Action:  custom_code/actions/ca_bootstrap.dart
  Detail:  Runs on every login. Calls bootstrap() RPC which returns orgs
           and active entitlements. Populates FFAppState (currentOrgId,
           entitlementStatus, assetLimit, features, planId, stripeSubId).
           Routes to HomePage on success, shows error if no org/entitlement.

App Initialization
  Page:    pages/init/splash_page/
  Action:  custom_code/actions/init_global_error_logging.dart
  Detail:  Splash screen displayed at startup.
           Global error hooks installed: FlutterError.onError,
           PlatformDispatcher.onError. Errors sent to log-error Edge Function
           which writes to app_errors table.

Asset Management — Create and Edit
  Pages:   pages/assets/add_asset_page/, pages/assets/edit_asset_page/
  Action:  custom_code/actions/upsert_asset.dart
  Detail:  INSERT: name, category, make, model, org_id, picUrl → assets table.
           UPDATE: same fields by asset id.
           Smart sync of form template associations:
             INSERT new rows into asset_inspection_templates.
             DELETE removed rows from asset_inspection_templates.
           stamp_assets trigger handles created_by, updated_by, updated_at.
           enforce_asset_limit trigger enforced server-side on insert.

Inspection Form Template Search
  Action:  custom_code/actions/rpc_search_form_templates.dart
  Detail:  Calls search_inspection_templates() RPC.
           Params: org id, scope (org_created / predefined / all), search text.
           Returns list of matching templates including creator names.
           Sort, limit, and offset not yet passed — server defaults apply.

Inspection Form Schema Manipulation
  Actions: wrap_schema.dart, unwrap_schema.dart, build_card.dart,
           add_or_replace_by_key.dart, delete_card_item_by_key.dart,
           move_card_item.dart
  Detail:  JSON-based operations on the form template schema stored in
           FFAppState.templateJson. Wrap/unwrap serializes the schema between
           the stored format and the editor's working representation.
           build_card creates a new form card/item structure.
           The remaining actions add, replace, delete, and reorder items.

Inspection Draft — In-Memory Build
  Actions: init_inspection_draft.dart, add_or_update_item_value.dart,
           build_values_for_pass_all_sub_checks.dart, undo_last_step.dart,
           update_inspection_draft_g_p_s.dart
  Detail:  initInspectionDraft writes a JSON draft to FFAppState.inspectionDraftJson:
             { asset_id, template_id, started_at, gps, items[] }
           addOrUpdateItemValue adds or replaces an item by template_item_key.
           buildValuesForPassAllSubChecks and undoLastStep support the step flow.
           updateInspectionDraftGPS stamps GPS coordinates into the draft.
           NOTE: This is entirely in-memory. See Inspection Execution below.

Error Logging
  Action:  custom_code/actions/init_global_error_logging.dart
  Detail:  Described above under App Initialization.
           Confirmed wired. app_errors table receives data via Edge Function.

Session Utilities
  Actions: refresh_supabase_session.dart, generate_uuid_action.dart,
           hide_keyboard.dart, open_in_external_browser.dart,
           trigger_snackbar.dart
  Detail:  Supporting utilities confirmed to exist. Session refresh keeps
           the auth token alive. Snackbar trigger updates FFAppState snackbar
           fields which the snackbar component observes.

--------------------------------------------------
PARTIALLY IMPLEMENTED
--------------------------------------------------

Asset List
  Page:    pages/assets/asset_list_page/
  Detail:  Page shell exists with search text controller and navigation
           component. Assets are queried (via FlutterFlow query, cached in
           FFAppState.assetDahbosrdCache). The list body content is not
           confirmed as fully built — import set is minimal.

Dashboard (Home Page)
  Page:    pages/dashboard/home_page/
  Detail:  Working shell: app bar with drawer, "Hello [name]" greeting
           (reads app_users_v on load, stores in FFAppState.displayName),
           all four DashboardTileLg* components imported.
           The tile data source is unknown without reading further — tiles
           may display static/default values rather than live query results.
           The sliding period control widget is imported (custom_widgets).
           Two _copy variants exist (home_page_copy, home_page_copy2) whose
           relationship to the primary page is not confirmed.

Inspection Form Template Management
  Pages:   pages/inspection_forms/create_inspection_form_page/
           pages/inspection_forms/edit_inspection_form_page/
           pages/inspection_forms/choose_inspection_form_page/
           pages/inspection_forms/preview_inspection_form_page/
           pages/inspection_forms/inspection_gallery_page/
  Detail:  create_inspection_form_page: actively wired — imports card_editor_sheet,
           custom actions (wrap/unwrap/build/etc.), animations, drop-downs,
           form controllers, keyboard visibility. The page likely has working
           UI for building a form template.
           choose_inspection_form_page: has search field and page shell.
           The others (edit, preview, gallery) are not deeply verified but
           page files with models exist.
           Whether template INSERT/UPDATE to the database is implemented
           is not confirmed from custom code — likely done via FlutterFlow
           page actions (not visible in custom_code/).

Navigation
  Component: pages/components/custom_navigation_component/
  Detail:    Shell renders correctly (responsive, animated divider on active tab).
             Tab 1 (Dashboard) → HomePageWidget: wired.
             Tab 2 (Assets) → AssetListPageWidget: wired.
             Tab 3 (Forms/layer-group) → AssetListPageWidget: placeholder routing.
             Tab 4 (Notifications/bell) → HomePageWidget: placeholder routing.
             App drawer (AppDrawerContentWidget) is imported in home and asset
             pages but its content is not verified.

OTP Authentication
  Actions: custom_code/actions/c_a_otp_start.dart,
           custom_code/actions/c_a_otp_verify.dart
  DB:      email_otp_codes table exists (challenge_id, code_hash, expires_at)
  Detail:  Custom actions exist for starting and verifying an OTP challenge.
           No page that uses these actions was identified in pages/authentication/.
           The pin_code component exists in pages/components/ and may be the
           intended UI. End-to-end flow is not confirmed.

File / Photo Attachment
  Code:    lib/backend/supabase/storage/storage.dart
  DB:      files table (org_id, asset_id, kind, url, label)
  Detail:  Storage upload and delete helpers are implemented.
           The files database table exists but no Flutter code inserts into it.
           Asset photos (picUrl) are uploaded to storage and the URL is stored
           directly on the assets row — not via the files table.
           No dedicated files listing UI was found.

--------------------------------------------------
PLACEHOLDER ONLY
--------------------------------------------------

Inspection Execution (Inspect Asset)
  Page:    pages/inspections/inspect_asset/
  Detail:  The page renders a scaffold with title text "Page Title" (literal
           string, not a variable) and an empty body Column (no children).
           No data queries, no form rendering, no submission logic.
           The in-memory draft infrastructure (actions) is built but cannot
           be used until this page is implemented.
           The inspect_asset route exists in the nav but leads to an empty screen.

--------------------------------------------------
NOT STARTED
--------------------------------------------------

Defect Management
  DB:      defects table exists (org_id, inspection_id, item_id, severity,
           description, status, photo_url, resolved_at)
  Detail:  No pages under pages/ for defects.
           No custom actions read or write the defects table.
           No FFAppState fields for defects.

Operators / Driver Profiles
  DB:      operators table exists (org_id, name, license_no, phone, photo_url)
  Detail:  No pages, no actions, no state for operators.

Consumption Logs
  DB:      consumption_logs table exists (asset_id, date, type, qty, unit,
           cost, meter_value, receipt_url)
  Detail:  No pages, no actions, no state for consumption or fuel logs.

People Management / User Admin
  DB:      app_users, users_orgs, roles, user_orgs_expanded view
  Detail:  No pages exist for listing, editing, or managing users within an org.
           No custom actions for inviting users or assigning roles.
           roles table and user_orgs_expanded view exist but have no Flutter UI.

Maintenance Scheduling
  DB:      No dedicated table found in the schema.
  Detail:  Not present anywhere in the codebase.

Reporting
  Detail:  No report pages, no report-specific queries or aggregations.
           The dashboard tiles display summary values but the data source
           behind them is not confirmed as live.

Push Notifications / Reminders
  Detail:  No notification service integration, no notification table,
           no scheduling mechanism found.

Asset Soft Delete / Restore
  DB:      assets.deleted_at / deleted_by / delete_reason columns exist.
           asset_soft_delete() and asset_restore() server functions exist.
  Detail:  No Flutter action calls either function.
           No "deleted" assets filter or restore UI.

--------------------------------------------------
OUT OF SCOPE (do not modify — maintained separately)
--------------------------------------------------

Onboarding
  Pages:   pages/onboarding/get_started_page/, pages/onboarding/onboarding_page/
  Actions: ca_bootstrap.dart (session bootstrap is in scope — onboarding wizard is not),
           c_a_upsert_onboarding_v3.dart
  DB:      upsert_onboarding_v2, upsert_onboarding_v3 server functions

Billing / Subscription
  Pages:   pages/billing/payment_successful_page/,
           pages/billing/payment_cancel_page/,
           pages/billing/paymment_cancelled_page2/
  Components: bottom_sheet_plan_confirmation, bottom_sheet_stripe_checkout,
              bottom_sheet_stripe_checkout_payment_sheet
  Actions: ca_payment_details.dart
  DB:      entitlements, plans, subscriptions, payments tables
