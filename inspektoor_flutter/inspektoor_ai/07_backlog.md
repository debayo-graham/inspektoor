Development Backlog
Generated: 2026-02-28
Source: gaps identified in 06_module_inventory.md and 05_data_model_map.md
Scope: complete what exists — no new features, no redesigns

--------------------------------------------------
MODULE: INSPECTION EXECUTION
--------------------------------------------------

Priority: Critical. The inspection draft infrastructure exists but the
execution page is an empty placeholder. Nothing in this module works end-to-end.

INSP-01  Build inspect_asset page UI  [DONE — 2026-03-11]
  Files built (all clean Dart, no FlutterFlow imports):
    lib/features/inspection/inspection_runner_view.dart
    lib/features/inspection/inspection_session.dart
    lib/features/inspection/inspection_tokens.dart
    lib/features/inspection/components/inspection_item_step.dart
    lib/features/inspection/components/inspection_progress_header.dart
    lib/features/inspection/components/inspection_summary_view.dart
    lib/features/inspection/components/pill_button.dart
    lib/features/inspection/components/item_inputs/option_grid.dart
    lib/features/inspection/components/item_inputs/multi_check_list.dart
    lib/features/inspection/components/item_inputs/multi_choice_list.dart
    lib/features/inspection/components/item_inputs/text_entry.dart
    lib/features/inspection/components/item_inputs/signature_pad.dart
    lib/features/inspection/components/item_inputs/stub_notice.dart
    lib/features/inspection/components/item_inputs/comment_box_input.dart
    lib/features/inspection/components/item_inputs/numeric_input.dart
    lib/features/inspection/components/item_inputs/alphanumeric_input.dart
    lib/features/inspection/components/item_inputs/single_check_card.dart
    lib/features/inspection/components/item_inputs/photo_input.dart
    lib/common/components/ocr_camera_screen.dart
    lib/common/components/photo_capture_box.dart
    lib/common/components/photo_preview_screen.dart
    lib/common/components/dashed_border_painter.dart
    lib/common/components/confirm_quit_inspection_dialog.dart
    lib/common/components/loading_overlay.dart

  Work done:
    InspectionRunnerView (orchestrator)
      - Reads FFAppState.templateJson and inspectionDraftJson.
      - Derives current step from answered item count.
      - AnimatedSwitcher with directional slide transitions (forward/back).
      - Per-item answer cache: selections survive back-navigation.
      - Wires addOrUpdateItemValue, undoLastStep, buildValuesForPassAllSubChecks.
      - Routes to InspectionSummaryView when all items answered.
      - Deferred first build (_ready flag + addPostFrameCallback) for snappy page open.
      - Memoized _defectMap() — computed once per build, passed to child builders.
      - Tablet layout: LayoutBuilder ≥768px → side-by-side summary + step view.

    InspectionSession (pure Dart, no Flutter dependency)
      - parseTemplate: parses and order-sorts template items from JSON.
      - answeredCount / answeredItems / defectMap: query the draft JSON.
      - needsNextButton: type policy (tap-to-submit vs Next button).
      - buildValues / unsetMultiCheckCount: value assembly and validation.
      - assetName: extracts asset name from draft JSON.

    InspectionItemStep (per-step StatefulWidget)
      - Renders correct input widget by item type via switch expression.
      - Types fully implemented:
          single-check       → SingleCheckCard (tap-to-submit)
          multiple-choice    → InspectionOptionGrid (single) or
                               InspectionMultiChoiceList (allowMultiple=true)
          multi-check        → InspectionMultiCheckList with Pass All shortcut;
                               validates all sub-checks answered before submit
          numeric            → NumericInput (decimal keyboard, unit suffix, OCR)
          comment-box        → CommentBoxInput (multiline, maxLength, OCR, quick-fill)
          alphanumeric       → AlphanumericInput (OCR)
          signature          → InspectionSignaturePad (fully implemented)
          photo              → PhotoInput (multi-photo capture with preview)
          unknown            → InspectionStubNotice
      - Footer: Previous / Next pill buttons; layout adapts to which are needed.
      - Signature: Next enabled only after a stroke is captured.
      - Multi-check: snackbar shown if any sub-checks unset on Next.

    InspectionSignaturePad (fully implemented — not a stub)
      - Drawing canvas via `signature` package (SignatureController).
      - Clear and Done buttons; Done disabled until at least one stroke drawn.
      - Exports PNG as Uint8List via onCapture callback.
      - Value stored as base64 string in answer cache; survives back-navigation.

    InspectionProgressHeader + InspectionSegmentBar
      - Segmented progress bar: each segment coloured pass/fail/current/pending.
      - Step label and item label displayed below the bar.
      - Directional animation: blue overlay sweeps left-to-right on forward,
        right-to-left on backward. Multi-check base colors under overlay.

    InspectionSummaryView
      - Shown when step == total (all items answered).
      - Stat chips: Passed / Defects / Total counts.
      - Per-item list with pass/fail/unanswered indicators.
      - Submit Inspection button present but disabled with INSP-02 placeholder notice.

    PhotoCaptureBox (reusable multi-photo widget)
      - Empty state: dashed border, camera icon, label + subtitle.
      - Has-photos state: PageView carousel with pagination dots, counter badge,
        add button, delete overlay.
      - No FlutterFlow imports — camera capture injected via callback.

    PhotoPreviewScreen (full-screen photo review)
      - Add/delete/reorder photos with thumbnails.
      - Annotation mode: freehand drawing with undo/clear, bakes strokes on Done
        (not on save — save is instant).
      - Label overlay (visual only, never baked into bytes).
      - Deleting last photo does NOT auto-close the screen.

    LoadingOverlay (reusable animated overlay)
      - Animated pill card: waveform bars (left) + message/subtitle (center)
        + optional icon (right).
      - Waveform: 4 bars with staggered sine-wave height animation (1.8s loop).
      - Bouncing dots: 3 grey dots with staggered scale/opacity (2s loop).
      - Backdrop: dark scrim with 4px blur (BackdropFilter).
      - Entry animation: scale from 85% + fade in (400ms easeOutBack).
      - API: LoadingOverlay.show(context, message:, subtitle:, icon:) / .hide(context).
      - Used pre-navigation on asset list page for seamless inspection load.

    inspect_asset_widget.dart
      - Title bar: "INSPECTION" label above asset name.
      - Body: InspectionRunnerView with onInteracted callback.
      - Back navigation: PopScope + confirm dialog with re-entrancy guard.
      - Tablet: hides AppBar when ≥768px (runner has its own header).

  UI Modernisation:
    inspection_tokens.dart
      - Colour tokens: kInspPassBg/Border/Fill, kInspFailBg/Border/Fill,
        kInspWarningBg/Border/Warning, kInspSlate, kInspBorder, kInspCard,
        kInspPrimary, kInspPrimaryText, kInspSecText.
      - inspInterStyle(size, weight, color) helper — all new text uses this.

  Per-sub-check photoRequired:
    - Each check object carries photoRequired (bool) and maxPhotos (int 1-5).
    - Falls back to item-level config for old templates.
    - Card editor: per-check config row (camera icon + switch + max dropdown).
    - Tap-to-toggle on sub-check cards (first tap = pass, second = fail).
    - Hard reset of failure notes/photos when toggling back to pass.

  Comment-box input + OCR:
    - Rich textarea with char count ring (amber warning at 90%), quick-fill chips.
    - OCR camera: custom viewfinder, 3 extraction modes (numeric, alphanumeric, freeText).
    - Camera icon stays tappable for rescan on all input types.

INSP-01b  Comment-box "Quick Fill" from previous inspections
  Gap:  The comment-box input has hardcoded quick-fill chips
        ("No issues noted", "Minor wear observed", etc.). These should
        pull from the user's previous inspection comment values for the
        same template item, so frequently-used comments are one tap away.
  Work: After INSP-02 (submission) is implemented and inspection history
        exists in the database:
          1. Query the most recent N (e.g. 5) distinct comment values
             for the same template_item_key from previous inspections.
          2. Pass them as the `quickFills` parameter to
             InspectionCommentBoxInput.
          3. Fall back to the hardcoded defaults when no history exists.
  Depends on: INSP-02

INSP-02  Implement inspection submission action
  Gap:  No action submits FFAppState.inspectionDraftJson to the database.
        inspections, inspection_items, and inspection_item_values are never
        written from Flutter.
  Work: Create a new custom action (e.g. caSubmitInspection) that:
          1. Reads FFAppState.inspectionDraftJson
          2. Inserts one row into inspections (org_id, asset_id, template_id,
             started_at, completed_at, gps, status='completed', created_by)
          3. Inserts one row per item into inspection_items
             (inspection_id, template_item_key, type, label, order, config)
          4. Inserts one row per value into inspection_item_values
             (inspection_item_id, key, label, value, photo_url, comment)
        Schema for these tables is defined in 05_data_model_map.md.

INSP-03  Wire submission action into inspect_asset page
  Gap:  Even after INSP-02 exists, it must be called from the page.
  Work: Add a submit/complete button to inspect_asset page that calls
        caSubmitInspection and navigates on success.
  Depends on: INSP-01, INSP-02

INSP-04  Update asset.last_inspected_at on inspection submit
  Gap:  The assets table has a last_inspected_at column. It is never updated.
  Work: After a successful inspection INSERT, update the asset row:
          .from('assets').update({'last_inspected_at': completedAt}).eq('id', assetId)
        This can be done inside caSubmitInspection or via a DB trigger.
  Depends on: INSP-02

--------------------------------------------------
MODULE: INSPECTION FORM TEMPLATES
--------------------------------------------------

FORM-01  Confirm inspection_templates INSERT is wired in create page
  File: lib/pages/inspection_forms/create_inspection_form_page/
  Gap:  The create page imports schema manipulation actions and card editor.
        No custom action inserts into inspection_templates.
        This is likely handled via a FlutterFlow page action (not visible in
        custom_code/). Needs verification that a save path exists and writes
        schema JSONB to the database.
  Work: Trace the save/submit action on the create page. If no DB write
        exists, add a caCreateInspectionTemplate action that inserts:
          (org_id, name, category, schema, version=1, is_active=true,
           created_by=currentUserUid)

FORM-02  Confirm inspection_templates UPDATE is wired in edit page
  File: lib/pages/inspection_forms/edit_inspection_form_page/
  Gap:  Same as FORM-01 for the edit path. Needs to UPDATE the schema,
        name, category, is_active on the existing template row.
  Work: Verify the save path. If missing, add a caUpdateInspectionTemplate action.

FORM-03  Wire choose_inspection_form_page to launch inspection
  File: lib/pages/inspection_forms/choose_inspection_form_page/
  Gap:  Page has a search field but the path from "choose a form" to
        "start inspection" is not confirmed.
  Work: Verify that selecting a template on this page calls initInspectionDraft
        (already implemented) and navigates to inspect_asset.
  Depends on: INSP-01

FORM-04  Verify preview_inspection_form_page renders real template data
  File: lib/pages/inspection_forms/preview_inspection_form_page/
  Gap:  File exists but was not deeply read. Preview may render static/empty content.
  Work: Confirm the page reads from FFAppState.templateJson (or a passed
        template row) and renders the form structure correctly.

--------------------------------------------------
MODULE: ASSET LIST
--------------------------------------------------

ASSET-01  Confirm asset list page loads and displays live data
  File: lib/pages/assets/asset_list_page/asset_list_page_widget.dart
  Gap:  Page shell and search controller exist. The body content (list of assets,
        query wiring) was not fully verified.
  Work: Confirm the page queries assets filtered by FFAppState.currentOrgId
        and renders each asset row. Confirm the search field filters results.

ASSET-02  Implement asset soft delete in Flutter
  Gap:  assets.deleted_at / deleted_by / delete_reason columns exist.
        Server functions asset_soft_delete() and asset_restore() exist.
        No Flutter action calls either. No delete option exists in the UI.
  Work: Add a caDeleteAsset custom action that calls the asset_soft_delete()
        RPC. Wire it to a delete action (e.g. swipe or context menu) on the
        asset list or edit page.

ASSET-03  Confirm _copy pages are duplicates and not the active pages
  Files: pages/assets/add_asset_page_copy/, pages/assets/edit_asset_page_copy/
  Gap:  Two _copy variants exist. It is not confirmed which is the active
        version and which is an abandoned draft.
  Work: Compare add_asset_page vs add_asset_page_copy and
        edit_asset_page vs edit_asset_page_copy. Determine which is wired
        in the router (lib/flutter_flow/nav/nav.dart) and remove or archive
        the unused copy.

--------------------------------------------------
MODULE: DASHBOARD
--------------------------------------------------

DASH-01  Confirm dashboard tiles display live data
  File: lib/pages/dashboard/home_page/home_page_widget.dart
  Gap:  All four DashboardTileLg* components are imported. Whether they
        receive real query results (inspection counts, defect counts, etc.)
        or render default/static values is not confirmed.
  Work: Read the full home_page_widget.dart body to verify what data each
        tile receives. If tiles use hardcoded default values (e.g. summaryValue=1),
        wire them to live queries against inspections, assets, and defects.

DASH-02  Resolve home_page_copy and home_page_copy2
  Files: pages/dashboard/home_page_copy/, pages/dashboard/home_page_copy2/
  Gap:  Two copy variants exist alongside the primary home_page. Their purpose
        is unknown. They may be experimental rewrites or in-progress iterations.
  Work: Compare with home_page. Identify which is active in the router.
        Remove or archive unused copies.

--------------------------------------------------
MODULE: NAVIGATION
--------------------------------------------------

NAV-01  Route nav tab 3 to correct destination
  File: lib/pages/components/custom_navigation_component/custom_navigation_component_widget.dart
  Gap:  Tab index 3 (FontAwesome layerGroup icon, labeled for Forms/Templates)
        currently routes to AssetListPageWidget. This is a placeholder destination.
  Work: Route tab 3 to the correct page once the forms list page is available.
        If choose_inspection_form_page or a form template list is the target,
        update the onPressed handler accordingly.

NAV-02  Route nav tab 4 to correct destination
  File: same as NAV-01
  Gap:  Tab index 4 (bell icon, labeled for Notifications) currently routes
        to HomePageWidget. This is a placeholder destination.
  Work: Route tab 4 to the notifications page when one exists.
        Until then, document this as pending and avoid navigating to it.

--------------------------------------------------
MODULE: DEFECTS
--------------------------------------------------

DEF-01  Build defect list page
  Gap:  defects table exists (id, org_id, inspection_id, item_id, severity,
        description, status, photo_url, resolved_at). No Flutter page exists.
  Work: Create pages/defects/ with a list page that queries defects filtered
        by org_id and optionally by inspection_id. Display severity and status.

DEF-02  Build defect detail / edit page
  Gap:  No page exists for viewing or resolving a single defect.
  Work: Create a detail page that displays defect fields and allows updating
        status (e.g. Open → Resolved) and setting resolved_at.

DEF-03  Wire defect creation to inspection submission
  Gap:  When an inspection item fails, a defect should be created.
        The defects table has inspection_id and item_id FK columns for this.
  Work: During or after inspection submission (INSP-02), for each item that
        represents a failure, insert a row into defects with the appropriate
        inspection_id, item_id, severity, and description.
  Depends on: INSP-02

--------------------------------------------------
MODULE: OPERATORS
--------------------------------------------------

OPR-01  Build operator list page
  Gap:  operators table exists (id, org_id, name, license_no, phone, photo_url).
        No Flutter page, no custom actions.
  Work: Create pages/operators/ with a list page that queries operators
        filtered by org_id.

OPR-02  Build operator create / edit page
  Gap:  No page for creating or editing an operator record.
  Work: Create add/edit pages with fields for name, license_no, phone.
        Photo upload uses the existing storage helpers.

--------------------------------------------------
MODULE: CONSUMPTION LOGS
--------------------------------------------------

CON-01  Build consumption log list per asset
  Gap:  consumption_logs table exists (asset_id, date, type, qty, unit, cost,
        meter_value, receipt_url). No Flutter page, no custom actions.
  Work: Create a consumption log view scoped to a specific asset, accessible
        from the asset detail or edit page.

CON-02  Build consumption log entry form
  Gap:  No create form exists.
  Work: Add a form for logging a consumption event (type, qty, unit, date,
        cost, meter_value). Receipt photo upload uses existing storage helpers.

--------------------------------------------------
MODULE: PEOPLE / USER MANAGEMENT
--------------------------------------------------

PPL-01  Build org user list page
  Gap:  users_orgs and user_orgs_expanded view exist. app_users table exists.
        No page lists users within an org.
  Work: Create a people/users list page that queries user_orgs_expanded
        filtered by currentOrgId. Display name, email, role_label.

PPL-02  Build user role management
  Gap:  roles table exists (role_key, label). users_orgs.role_id references roles.
        No UI exists for assigning or changing a user's role.
  Work: On the user detail within the org, allow selecting from available roles
        and updating users_orgs.role_id.

--------------------------------------------------
MODULE: FILES / ATTACHMENTS
--------------------------------------------------

FILE-01  Wire asset photo upload to files table
  Gap:  Asset photos are uploaded to storage and the URL is stored in
        assets.picUrl directly. The files table (org_id, asset_id, kind,
        url, label) is never written.
  Work: Determine project intent: either continue using assets.picUrl for
        the primary photo (current behaviour) or add a files table insert
        after upload for audit/gallery purposes. Document the decision.

--------------------------------------------------
MODULE: OTP AUTHENTICATION
--------------------------------------------------

OTP-01  Confirm OTP flow has a working page
  Gap:  c_a_otp_start and c_a_otp_verify custom actions exist.
        email_otp_codes table and pin_code component exist.
        No page in pages/authentication/ was identified as using these actions.
  Work: Locate the page that hosts the OTP flow. If it is one of the existing
        authentication pages (e.g. a step within login), confirm the actions
        are called. If no page exists, create one using the pin_code component.

--------------------------------------------------
HOUSEKEEPING
--------------------------------------------------

CLEAN-01  Remove or archive unused _copy page variants
  Files: pages/assets/add_asset_page_copy/,
         pages/assets/edit_asset_page_copy/,
         pages/dashboard/home_page_copy/,
         pages/dashboard/home_page_copy2/,
         pages/components/bottom_sheet_add_forms_to_asset_copy/,
         pages/billing/paymment_cancelled_page2/ (out-of-scope but still exists)
  Gap:  Six _copy variants clutter the codebase. Their relationship to the
        primary pages is unconfirmed.
  Work: For each, check the router (nav.dart) and page references. If unused,
        remove the page folder and its route entry.

CLEAN-02  Remove or document bottom_sheet_add_forms_to_asset_copy
  File: pages/components/bottom_sheet_add_forms_to_asset_copy/
  Gap:  A copy of the add-forms-to-asset bottom sheet exists.
        It is not clear which version is active.
  Work: Compare with the original bottom_sheet_add_forms_to_asset.
        Keep the active version, remove the other.

--------------------------------------------------
MODULE: REMINDERS AND NOTIFICATIONS  [implement last]
--------------------------------------------------

No schema, pages, or actions exist for this module yet. Design and
implementation must be based on what is discovered in this repository
when work begins. The following describes the intended behaviour only.

Overview:
  Users with an appropriate role can create scheduled reminders.
  Each reminder triggers both an email notification and an in-app
  notification to all users who hold a specified target role within
  the same org.

NOTIF-01  Design and create reminders table
  Gap:  No reminders table exists in the schema.
  Work: Add a reminders table to the database. Minimum columns required:
          id, org_id, created_by, title, message, target_role_id (FK roles),
          schedule (cron expression or next_run_at timestamp),
          is_active, created_at, updated_at
        Determine whether recurrence is stored as a cron string or as a
        next_run_at that is recomputed after each fire.

NOTIF-02  Design and create notifications table
  Gap:  No notifications table exists in the schema.
  Work: Add a notifications table for in-app delivery. Minimum columns:
          id, org_id, user_id, reminder_id (nullable FK reminders),
          title, message, is_read, created_at
        This table is the source of truth for the in-app notification inbox.

NOTIF-03  Build scheduled delivery mechanism (server-side)
  Gap:  No scheduled job or Edge Function exists for sending reminders.
  Work: Implement a scheduled Edge Function (or pg_cron job) that:
          1. Queries reminders where is_active = true and next_run_at <= now()
          2. Resolves all users in the org who hold the target role
             (via users_orgs joined to roles)
          3. Inserts one row per user into the notifications table
          4. Sends an email to each resolved user via the existing email
             provider (to be determined — no email sender exists yet)
          5. Updates next_run_at on the reminder for the next occurrence
  Note: Email provider integration must be decided before this can be built.

NOTIF-04  Build reminder create / edit page
  Gap:  No page exists for creating or editing a reminder.
  Work: Create pages/reminders/ with a form for:
          - title and message
          - target role selector (reads from roles table)
          - schedule configuration (frequency, start date/time)
          - is_active toggle
        Only users whose role permits reminder management should see this page.
        Role-based access enforcement to be determined when PPL-02 is complete.

NOTIF-05  Build notification inbox page
  Gap:  No in-app notification page exists. Nav tab 4 (bell icon) is currently
        an unrouted placeholder (see NAV-02).
  Work: Create pages/notifications/ with a list of notifications for the
        current user (query notifications where user_id = currentUserUid,
        ordered by created_at desc).
        Mark notifications as read (is_read = true) on open or on tap.
        Wire NAV-02 (bell tab) to this page.
  Depends on: NOTIF-02, NAV-02

NOTIF-06  Display unread notification count on nav tab
  Gap:  The bell icon on the nav bar has no badge or count indicator.
  Work: Query count of notifications where user_id = currentUserUid
        and is_read = false. Display as a badge on the bell icon.
  Depends on: NOTIF-02, NOTIF-05
