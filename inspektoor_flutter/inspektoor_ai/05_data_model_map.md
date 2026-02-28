Data Model Map
Generated: 2026-02-28
Sources: 04_schema_baseline.sql, lib/backend/supabase/**, lib/custom_code/actions/**,
         lib/app_state.dart

--------------------------------------------------
Supabase Client Initialization
--------------------------------------------------

File: lib/backend/supabase/supabase.dart

Class: SupaFlow (singleton)
  SupaFlow.client  — global access to the SupabaseClient
  SupaFlow.initialize() — called at app startup

Auth flow type: implicit (AuthFlowType.implicit)
Headers: X-Client-Info = 'flutterflow'

--------------------------------------------------
Database Schema: Tables
--------------------------------------------------

All tables live in the public schema unless noted.

CORE DOMAIN

assets
  id (uuid PK), org_id, name, category*, make, model, serial_or_vin,
  status (text, default 'active'), status_id (FK asset_statuses),
  location, tags (jsonb []), meter_type/unit/value, attributes (jsonb {}),
  last_inspected_at, picUrl, year, created/updated/deleted metadata,
  delete_reason, deleted_by
  * category enum: vehicle, trailer, heavy_equipment, access_equipment,
    power_equipment, fluid_handling, safety_equipment, building_systems, other
  Soft delete: deleted_at / delete_reason / deleted_by columns.
  Trigger: stamp_assets (sets created_by, updated_by, updated_at).
  Trigger: enforce_asset_limit (blocks insert if org limit reached).
  Index: org_id, (org_id, name).

asset_statuses
  id, code (unique), label, color, sort_order, is_default, is_terminal,
  created_at, updated_at
  Lookup table. Function asset_status_id('code') returns the id.

asset_inspection_templates  (junction table)
  asset_id + inspection_template_id (composite PK), created_at, created_by
  Links assets to their assigned inspection form templates.

inspection_templates
  id, org_id (nullable for predefined), name, category, schema (jsonb),
  version, is_active, is_predefined, created_by, created_at
  Constraint: predefined OR org_id must be set.
  Full-text + trigram indexes on name and category.
  The schema column holds the JSON form definition.

inspections
  id, org_id, asset_id, template_id, status (default 'in_progress'),
  started_at, completed_at, gps (jsonb), signed_by, signature_url,
  created/updated metadata

inspection_items
  id, inspection_id, template_item_key, type, label, order, config (jsonb),
  created/updated metadata

inspection_item_values
  id, inspection_item_id, key, label, value, photo_url, comment, created_at

defects
  id, org_id, inspection_id, item_id (nullable), severity (default 'Medium'),
  description, status (default 'Open'), photo_url, created_at, resolved_at

operators
  id, org_id, name, license_no, phone, photo_url, created_at

consumption_logs
  id, org_id, asset_id, date, type, qty, unit, cost, meter_value,
  receipt_url, created_at

files
  id, org_id, asset_id (nullable), kind, url, label, created_at

IDENTITY / PEOPLE

app_users
  id (= auth.uid()), email, first_name, middle_name, last_name,
  display_name, avatar_url, gender, dob, created_at, updated_at
  Created automatically by trigger handle_new_auth_user on auth.users insert.

app_users_v  (view)
  Adds computed full_name (first + middle + last, trimmed).

users_orgs
  user_id + org_id (unique), id (surrogate PK), role_id (FK roles)

user_orgs_expanded  (view)
  users_orgs joined with roles — exposes role_key and role_label.

roles
  id, role_key (regex: ^[a-z_]+$), label, created_at
  Lookup table. Known key: 'owner'.

orgs
  id, name, asset_limit (default 1), status (draft/active/suspended),
  onboarding_stage, address fields, primary_contact fields,
  stripe_customer_id, stripe_subscription_id, billing_email, plan_id

BILLING (out of scope for in-app development — do not modify)

entitlements
  id, org_id, plan_id, source (stripe/manual), source_ref,
  asset_limit, features (jsonb {}), status (enum: active/suspended/
  canceled/expired/pending), current_period_start/end, created/updated_at
  Unique index: one active entitlement per org.

entitlements_current  (view)
  Filters entitlements to status = 'active' only.

plans
  id, code (unique), name, stripe_price_id (unique), interval (month/year),
  currency, unit_price, is_per_asset, asset_limit, created/updated_at

subscriptions
  id, org_id, stripe_customer_id, stripe_subscription_id, quantity,
  status, current_period_end, plan_id, created/updated_at

payments
  id, org_id, stripe_* fields, amount_paid_cents, currency, card_last4,
  payment_method_brand/type, receipt_url, status, paid_at, created_at

SYSTEM

app_errors
  id, user_id, org_id, env (dev/prod), platform, app_version, screen,
  error_type, message, stack, extra (jsonb), occurred_at

email_otp_codes
  id, user_id, challenge_id, code_hash, expires_at (10 min), consumed_at,
  created_at

audit_log
  id (bigint, auto-increment), org_id, actor_id, action (TG_OP),
  entity (table name), entity_id, changes (jsonb full row snapshot), created_at

--------------------------------------------------
Database Functions and Triggers
--------------------------------------------------

app.org_id()
  Extracts org_id from the auth JWT claim 'org_id'.
  Used in RLS policies.

bootstrap()  [SECURITY DEFINER]
  Returns jsonb: { orgs: [...], entitlements: [...] }
  Called by caBootstrap() on login to populate FFAppState.
  Queries: users_orgs → orgs, entitlements_current → users_orgs.

search_inspection_templates(p_org, p_scope, p_q, p_sort_by, p_sort_dir, p_limit, p_offset)
  Paginated, filtered search across inspection_templates.
  Scope options: org_created, predefined, all.
  Joins app_users to return creator_first_name / creator_last_name.
  Called by rpcSearchFormTemplates() — currently passes no sort/limit/offset params.

upsert_onboarding_v2 / upsert_onboarding_v3  [SECURITY DEFINER, OUT OF SCOPE]
  Multi-step onboarding that creates/updates app_users, orgs, users_orgs.

asset_soft_delete(p_id, p_reason)
  Sets deleted_at = now(), deleted_by = auth.uid() on assets row.
  Not yet called from Flutter custom code — unconfirmed if wired via FlutterFlow.

asset_restore(p_id)
  Clears deleted_at / delete_reason / deleted_by.
  Not yet called from Flutter custom code.

asset_status_id(p_code) [STABLE]
  Returns UUID of asset_statuses row matching code.

Triggers on assets:
  stamp_assets — sets created_by, updated_by, updated_at automatically.
  enforce_asset_limit — raises exception if org has reached its asset_limit.

Trigger on auth.users:
  handle_new_auth_user — inserts into app_users(id, email) on new auth signup.

Trigger on audit_log targets:
  log_change — writes INSERT/UPDATE/DELETE events to audit_log.

Timestamp triggers:
  stamp_asset_statuses, tg_entitlements_updated_at, update_updated_at_column

--------------------------------------------------
Supabase Usage in Flutter — Authentication
--------------------------------------------------

File: lib/custom_code/actions/ca_login.dart
  supa.auth.signInWithPassword(email, password)
  Returns: { success, code, message }
  Error codes normalized: invalid_credentials, email_not_confirmed,
  rate_limited, no_session.

File: lib/custom_code/actions/ca_create_account.dart
  supa.auth.signUp(email, password)
  Returns: { success, code, message }
  Trigger handle_new_auth_user fires server-side on signup.

File: lib/auth/supabase_auth/supabase_auth_manager.dart  (not deeply read)
  FlutterFlow-generated auth manager. Handles sign-out and session state.

File: lib/custom_code/actions/refresh_supabase_session.dart  (not deeply read)
  Refreshes the auth session token.

Note: OTP auth (c_a_otp_start, c_a_otp_verify) exists but not deeply read.
The email_otp_codes table supports a custom OTP challenge flow.

--------------------------------------------------
Supabase Usage in Flutter — Database Reads
--------------------------------------------------

assets (via FFAppState cache)
  File: lib/app_state.dart
  assetDahbosrdCache — caches List<AssetsRow> for the dashboard.
  Populated by FlutterFlow-generated queries (not custom code).

asset_inspection_templates (read in upsertAsset)
  .from('asset_inspection_templates')
  .select('inspection_template_id')
  .eq('asset_id', assetId)
  Returns current template associations for an asset.

inspection_templates (via RPC)
  rpcSearchFormTemplates() → supa.rpc('search_inspection_templates', params)
  Params passed: p_org, p_scope, p_q only (sort/limit/offset not passed).

bootstrap() RPC
  caBootstrap() → supa.rpc('bootstrap', params: {})
  Returns first org + matching entitlement for current user.
  Populates FFAppState: currentOrgId, entitlementStatus, assetLimit,
  features, planId, stripeSubId.

FlutterFlow-generated table reads (inferred from backend/supabase/database/tables/):
  All 24 table/view files exist and expose query helpers.
  Pages likely read: assets, inspections, inspection_templates,
  app_users, orgs, asset_inspection_templates, asset_statuses.
  These reads happen inside FlutterFlow page widget code, not custom actions.

--------------------------------------------------
Supabase Usage in Flutter — Database Writes
--------------------------------------------------

assets  (INSERT)
  File: lib/custom_code/actions/upsert_asset.dart
  .from('assets').insert(data).select().maybeSingle()
  Fields written: org_id, name, category, make, model, picUrl (optional)

assets  (UPDATE)
  File: lib/custom_code/actions/upsert_asset.dart
  .from('assets').update(data).eq('id', assetId).select().maybeSingle()
  Same fields as INSERT.

asset_inspection_templates  (INSERT)
  File: lib/custom_code/actions/upsert_asset.dart
  .from('asset_inspection_templates').insert(rows)
  Rows: { asset_id, inspection_template_id }

asset_inspection_templates  (DELETE)
  File: lib/custom_code/actions/upsert_asset.dart
  .from('asset_inspection_templates').delete().eq('asset_id', ...).inFilter(...)
  Removes de-linked templates from an asset.

inspection_templates  (INSERT/UPDATE)
  Inferred via pages/inspection_forms/ page structure. Not confirmed in
  custom code — likely done through FlutterFlow page actions.

inspections, inspection_items, inspection_item_values  (NOT YET PERSISTED)
  The inspection draft is built in memory only using FFAppState.inspectionDraftJson.
  No custom action submits this draft to the database.
  There is no caSubmitInspection or equivalent action in the codebase.
  Status: INCOMPLETE — draft data never leaves the device.

--------------------------------------------------
Supabase Usage in Flutter — Edge Functions
--------------------------------------------------

log-error  (invoked by initGlobalErrorLogging)
  File: lib/custom_code/actions/init_global_error_logging.dart
  supa.functions.invoke('log-error', body: { ... })
  Triggered by FlutterError.onError and PlatformDispatcher.onError.
  Payload: user_id, org_id, env, platform, app_version, screen,
           error_type, message, stack, extra.
  Writes to app_errors (via the Edge Function, not direct insert).

--------------------------------------------------
Supabase Usage in Flutter — Storage
--------------------------------------------------

File: lib/backend/supabase/storage/storage.dart

uploadSupabaseStorageFile(bucketName, selectedFile)
  SupaFlow.client.storage.from(bucketName).uploadBinary(...)
  Returns public URL.

uploadSupabaseStorageFiles(bucketName, selectedFiles)
  Batch version of above.

deleteSupabaseFileFromPublicUrl(publicUrl)
  Parses bucket and path from URL.
  SupaFlow.client.storage.from(bucketName).remove([filePath])

Bucket names: passed as runtime parameters — no hardcoded bucket names found
in storage.dart. Call sites determine the bucket.

--------------------------------------------------
FFAppState — Global State
--------------------------------------------------

File: lib/app_state.dart

Session/auth:
  userAccessToken     — stored JWT access token
  currentOrgId        — set by caBootstrap()
  entitlementStatus   — from bootstrap entitlement
  assetLimit          — max assets allowed for org
  features            — entitlement feature map (jsonb)
  planId              — current plan UUID
  stripeSubId         — Stripe subscription source_ref

UI state:
  displayName         — shown in UI
  selectedMenuKey     — active nav item ('homePage' default)
  expandedMenuKey     — expanded drawer item
  snackbar*           — message, color, show flag, bg, text, duration, trigger
  periodIndex/periodKey/rangeStart/rangeEnd — dashboard date filter

Inspection draft (in-memory, not persisted):
  inspectionDraftJson     — JSON string: { asset_id, template_id, started_at, gps, items[] }
  templateJson            — current template schema JSON
  currentInspectionIndex  — current step position

Caches:
  assetDahbosrdCache    — List<AssetsRow>, keyed by uniqueQueryKey
  listOfCountryCache    — ApiCallResponse (for country dropdowns)

--------------------------------------------------
What Is NOT Yet Implemented in Flutter
--------------------------------------------------

These database tables exist and have Flutter table files but no read or write
operations were found in custom code or confirmed in page code:

  defects              — table exists, no CRUD actions found
  operators            — table exists, no CRUD actions found
  consumption_logs     — table exists, no CRUD actions found
  files                — storage upload exists, but no insert into files table
  roles                — table exists, read only via views
  audit_log            — written server-side by triggers only
  app_errors           — written via Edge Function only

Inspection submission is incomplete:
  inspections          — never inserted from Flutter
  inspection_items     — never inserted from Flutter
  inspection_item_values — never inserted from Flutter
  The draft JSON in FFAppState is built but never submitted.

--------------------------------------------------
Observations
--------------------------------------------------

1. BOOTSTRAP PATTERN: Login triggers caBootstrap() → bootstrap() RPC,
   which returns the user's org and active entitlement in one call.
   Result is stored in FFAppState and used throughout the app session.

2. ASSET LIMIT ENFORCEMENT: The enforce_asset_limit trigger on assets
   blocks inserts server-side when the org reaches its limit. The Flutter
   app does not separately validate this before attempting an insert.

3. SOFT DELETE: Assets support soft delete via deleted_at/deleted_by/
   delete_reason. The restore and soft-delete functions exist on the
   server. No Flutter action calls them yet.

4. INSPECTION DRAFT IS LOCAL ONLY: The inspect_asset flow builds a JSON
   draft in FFAppState but no submission action exists. This is the most
   significant gap between the inspection UI and actual data persistence.

5. AUDIT LOG IS AUTOMATIC: All writes to audited tables are captured by
   the log_change trigger. No Flutter code needs to write to audit_log.

6. ERROR LOGGING IS IMPLEMENTED: Global Flutter errors are captured and
   sent to the log-error Edge Function, which writes to app_errors.
   This is fully wired.

7. STORAGE IS GENERIC: The storage helpers take a bucket name as a
   parameter. The bucket used for asset photos (picUrl) is not visible
   in custom code — it originates from a FlutterFlow action on the
   asset pages.
