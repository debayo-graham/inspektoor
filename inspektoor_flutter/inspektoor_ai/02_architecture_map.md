Architecture Map: lib/ folder structure
Generated: 2026-02-28
Source: folder structure scan only — files not deeply read unless noted

--------------------------------------------------
Top-Level Files
--------------------------------------------------

- main.dart              App entry point
- app_state.dart         Global app state (FlutterFlow pattern)
- app_constants.dart     App-wide constants
- environment_values.dart Environment/config values (e.g. API keys, env flags)
- index.dart             Barrel export of all pages

--------------------------------------------------
lib/auth/
--------------------------------------------------

Authentication layer, separated from backend data layer.

- auth_manager.dart              Abstract auth manager interface
- base_auth_user_provider.dart   Base class for auth user providers
- supabase_auth/
  - supabase_auth_manager.dart   Supabase implementation of auth manager
  - supabase_user_provider.dart  Supabase user provider (stream-based)
  - auth_util.dart               Auth utility helpers (current user, etc.)
  - email_auth.dart              Email/password sign-in logic

--------------------------------------------------
lib/backend/
--------------------------------------------------

Data access layer. Two sub-systems: REST API calls and Supabase client.

api_requests/
  - api_calls.dart               Defined API call classes
  - api_manager.dart             HTTP request execution manager
  - browser_client_stub.dart     Web stub for HTTP client
  - get_streamed_response.dart   Streaming response helper

supabase/
  - supabase.dart                Supabase client initialisation
  - storage/
    - storage.dart               File/media storage helpers
  - database/
    - database.dart              Barrel export for all tables
    - row.dart                   Base row model
    - table.dart                 Base table query class
    - tables/                    One file per database table or view:
        app_errors.dart
        app_users.dart
        app_users_v.dart             (view)
        asset_inspection_templates.dart
        asset_statuses.dart
        assets.dart
        audit_log.dart
        consumption_logs.dart
        defects.dart
        email_otp_codes.dart
        entitlements.dart
        entitlements_current.dart    (view/materialized)
        files.dart
        inspection_item_values.dart
        inspection_items.dart
        inspection_templates.dart
        inspections.dart
        operators.dart
        orgs.dart
        payments.dart
        plans.dart
        roles.dart
        subscriptions.dart
        user_orgs_expanded.dart      (view)
        users_orgs.dart

--------------------------------------------------
lib/flutter_flow/
--------------------------------------------------

FlutterFlow framework support files. Not application logic — do not modify
unless FlutterFlow regenerates them.

Includes: theme, animations, widgets (button tabbar, checkbox group, credit
card form, dropdown, icon button, radio button, web view), nav router,
form field controller, lat/lng helpers, place model, upload helpers,
request manager (caching), and custom functions.

--------------------------------------------------
lib/custom_code/
--------------------------------------------------

Hand-written Dart code that extends FlutterFlow-generated scaffolding.
This is the primary place for custom logic.

actions/
  Auth:
    - ca_login.dart
    - ca_create_account.dart
    - c_a_otp_start.dart
    - c_a_otp_verify.dart
    - refresh_supabase_session.dart

  Onboarding:
    - ca_bootstrap.dart
    - c_a_upsert_onboarding_v3.dart

  Assets:
    - upsert_asset.dart
    - get_asset_forms.dart
    - add_forms_to_asset.dart
    - delete_asset_forms.dart
    - delete_all_forms_from_asset.dart

  Inspection:
    - init_inspection_draft.dart
    - update_inspection_draft_g_p_s.dart
    - add_or_update_item_value.dart
    - build_values_for_pass_all_sub_checks.dart
    - undo_last_step.dart

  Form / Schema:
    - rpc_search_form_templates.dart
    - wrap_schema.dart
    - unwrap_schema.dart
    - build_card.dart
    - add_or_replace_by_key.dart
    - delete_card_item_by_key.dart
    - move_card_item.dart

  Billing:
    - ca_payment_details.dart

  Utility:
    - generate_uuid_action.dart
    - hide_keyboard.dart
    - open_in_external_browser.dart
    - trigger_snackbar.dart
    - init_global_error_logging.dart
    - crash_for_test.dart

  index.dart             Barrel export

widgets/
  - dynamic_text.dart           Text widget with dynamic content
  - selectable_forms_list.dart  Multi-select list for inspection forms
  - sliding_period_control.dart Period/date range selector
  - snackbar.dart               Custom snackbar widget
  - index.dart                  Barrel export

--------------------------------------------------
lib/pages/
--------------------------------------------------

UI screens, grouped by feature domain. Each page follows the FlutterFlow
two-file pattern: *_widget.dart (UI) + *_model.dart (state/logic).

init/
  - splash_page                  App launch / loading screen

authentication/
  - bootstrap_page               Post-login routing / session bootstrap
  - login                        Email login screen
  - create_account               Account registration screen

onboarding/
  - get_started_page             First-run landing
  - onboarding_page              Onboarding flow (org setup etc.)

dashboard/
  - home_page                    Main dashboard
  - home_page_copy               [DUPLICATE — likely in-progress variant]
  - home_page_copy2              [DUPLICATE — likely in-progress variant]

assets/
  - asset_list_page              Browse/search assets
  - add_asset_page               Create new asset
  - edit_asset_page              Edit existing asset
  - add_asset_page_copy          [DUPLICATE — likely in-progress variant]
  - edit_asset_page_copy         [DUPLICATE — likely in-progress variant]

inspection_forms/
  - choose_inspection_form_page  Select a form template to use
  - create_inspection_form_page  Build a new form template
  - edit_inspection_form_page    Edit an existing form template
  - preview_inspection_form_page Preview a form before use
  - inspection_gallery_page      Photo/media gallery for an inspection

inspections/
  - inspect_asset                Active inspection execution screen

billing/
  - payment_successful_page      Stripe success redirect landing
  - payment_cancel_page          Stripe cancel redirect landing
  - paymment_cancelled_page2     [DUPLICATE — likely in-progress variant]

components/  (shared UI components used across pages)
  - app_drawer_content                         Side navigation drawer
  - custom_navigation_component                Bottom/tab navigation bar
  - button_main                                Primary action button
  - empty_list                                 Empty state placeholder
  - snackbar                                   Toast/snackbar message
  - custom_confirm_dialog                      Confirmation dialog
  - custom_message_dialog                      Info/message dialog
  - option_row                                 Single option list row
  - pin_code                                   PIN entry component
  - card_editor_sheet                          Bottom sheet: form card editor
  - bottom_sheet_add_forms_to_asset            Attach forms to asset
  - bottom_sheet_add_forms_to_asset_copy       [DUPLICATE — in-progress variant]
  - bottom_sheet_plan_confirmation             Billing plan confirm sheet
  - bottom_sheet_stripe_checkout               Stripe checkout sheet
  - bottom_sheet_stripe_checkout_payment_sheet Stripe payment sheet variant
  - inspection_gallery_more_options            Gallery item actions menu
  - dashboard_tile_lg_blue                     Dashboard metric tile (blue)
  - dashboard_tile_lg_green                    Dashboard metric tile (green)
  - dashboard_tile_lg_purple                   Dashboard metric tile (purple)
  - dashboard_tile_lg_red                      Dashboard metric tile (red)

--------------------------------------------------
Observations
--------------------------------------------------

1. FRAMEWORK: This is a FlutterFlow-generated project. Generated code lives
   in flutter_flow/ and pages/. Custom logic lives in custom_code/.

2. BACKEND: Supabase is the sole backend. No Firebase. The database table
   list covers the full domain model (assets, inspections, defects, orgs,
   billing, users, roles).

3. DUPLICATE PAGES: Several pages have _copy or _copy2 variants
   (home_page, add_asset_page, edit_asset_page, paymment_cancelled_page2,
   bottom_sheet_add_forms_to_asset_copy). These appear to be in-progress
   rewrites or experiments. Status is unverified — do not delete without
   confirming with owner.

4. BILLING / ONBOARDING — OUT OF SCOPE FOR IN-APP DEVELOPMENT:
   Onboarding (pages/onboarding/, custom_code/actions/ca_bootstrap.dart,
   c_a_upsert_onboarding_v3.dart) and billing (pages/billing/,
   custom_code/actions/ca_payment_details.dart, pages/components/
   bottom_sheet_plan_confirmation, bottom_sheet_stripe_checkout*) are
   present in the codebase but will NOT be implemented or modified as
   part of in-app development. These features are maintained separately.
   Do not touch any of these files until explicitly instructed.

5. INSPECTION FLOW: Custom actions suggest a draft-based inspection workflow
   (init_inspection_draft, update_inspection_draft_gps, add_or_update_item_value,
   undo_last_step). Schema wrapping/unwrapping actions suggest JSON-structured
   form definitions stored in the database.

6. MISSING FROM pages/: No dedicated pages found for defects, people/users
   management, reporting, or maintenance scheduling. These are in-scope for
   MVP (per 00_mission.md) but not yet present as page files.
