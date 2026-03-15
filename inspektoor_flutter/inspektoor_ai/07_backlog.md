Development Backlog
Generated: 2026-02-28
Last updated: 2026-03-12
Source: gaps identified in 06_module_inventory.md and 05_data_model_map.md
Scope: complete what exists — no new features, no redesigns

--------------------------------------------------
MODULE: INSPECTION EXECUTION
--------------------------------------------------

Priority: Critical. The inspection draft infrastructure exists but the
execution page is an empty placeholder. Nothing in this module works end-to-end.

INSP-01  Build inspect_asset page UI  `DONE — 2026-03-11`
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
      - Back navigation: PopScope(canPop: false) + onPopInvokedWithResult checks
        didPop before triggering dialog. _forcePop() for programmatic navigation.
        _submitted flag prevents dialog when submit navigates away.
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

  Display overflow fix (numeric + alphanumeric inputs):
    - LayoutBuilder > FittedBox(scaleDown) > ConstrainedBox(maxWidth: 2×) > Text.rich/Text
    - Zero-width spaces (\u200B) between digits/chars for character-level line breaking.
    - Alphanumeric: letter-spacing preserved for format-patterned values (natural breaks
      via hyphens/spaces); letter-spacing dropped for free-form codes (\u200B used instead).
    - Both mobile and tablet layouts covered.

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

INSP-02  Implement inspection submission action  `DONE — 2026-03-12`
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

  Pre-submission close-out work done (2026-03-12):
    inspection_item_types.dart
      - Re-enabled 'signature' in kItemTypeLabels getter (was filtered out).
        Users can now add Signature items to any template.

    inspection_session.dart
      - Removed items.removeWhere((e) => e['type'] == 'signature') — user-added
        signature items (e.g. "Driver Signature") now pass through to the runner.
      - Auto-appended __final_signature__ step retains its 'Inspector Signature'
        label so it is clearly distinguished in submitted data.
      - buildValues() now accepts itemLabel parameter (default 'Value'). Used for
        numeric / alphanumeric / comment-box label field instead of hardcoded "Value".

    inspection_item_step.dart
      - _handleNext() extracts itemLabel from widget.item['label'] and threads it
        through to all submit paths:
          photo:     'label': itemLabel (was hardcoded 'Photos')
          signature: 'label': itemLabel (was hardcoded 'Signature')
          text entry: passes itemLabel to buildValues()
      - Result: inspection_item_values.label in the DB now stores the real template
        item label (e.g. "Trailer number", "Driver Signature") instead of "Value".

    inspection_summary_view.dart
      - _extractImages() now reads _photos field (base64 list) in addition to value
        field — fixes signature image not displaying on summary page.
      - _SignatureCard shows item label as primary bold header (was hardcoded
        'Inspected by').
      - inspectorName parameter is now nullable (String?). "Signed by [name]" sub-line
        only rendered for __final_signature__ key (inspector auto-step). All other
        signature items (e.g. Driver Signature) suppress the "Signed by" line.


INSP-03  Wire submission action into inspect_asset page  `DONE — 2026-03-12`
  Gap:  Even after INSP-02 exists, it must be called from the page.
  Work: Add a submit/complete button to inspect_asset page that calls
        caSubmitInspection and navigates on success.
  Depends on: INSP-01, INSP-02

INSP-04  Update asset.last_inspected_at on inspection submit  `DONE — 2026-03-12`
  Gap:  The assets table has a last_inspected_at column. It is never updated.
  Work: After a successful inspection INSERT, update the asset row:
          .from('assets').update({'last_inspected_at': completedAt}).eq('id', assetId)
        This can be done inside caSubmitInspection or via a DB trigger.
  Depends on: INSP-02

INSP-05  Capture device GPS coordinates at inspection start
  Gap:  The inspections table already has a gps column and caSubmitInspection
        already reads draft['gps'] and writes it to the DB. However nothing in
        the Flutter app ever populates the gps field in the draft JSON.
  Work: 1. Check pubspec.yaml for geolocator — add if missing.
        2. Request location permission when an inspection is started
           (initInspectionDraft or the runner view's initState).
        3. Call Geolocator.getCurrentPosition() and store
           {lat, lng, accuracy} as JSON into the draft's gps field.
        4. If permission denied or location unavailable, store null and
           proceed — GPS is optional, never a submission blocker.
  Depends on: INSP-02

INSP-06  Show GPS location map pin on inspection summary page
  Gap:  No map is shown anywhere in the inspection flow. The inspector
        should see a map pin on the summary screen confirming where the
        inspection was recorded before they submit.
  Work: 1. Check pubspec.yaml for flutter_map or google_maps_flutter.
           Prefer flutter_map (OpenStreetMap, no API key required).
        2. On InspectionSummaryView, if gps is non-null in the draft,
           render a small embedded map (180–200px tall) with a pin at
           the captured lat/lng. Map is non-interactive (static view).
        3. Show formatted coordinates as text below the map
           (e.g. "12.3456° N, 1.2345° W").
        4. If GPS is null, show a "Location not captured" placeholder row.
        5. Extract as a reusable InspectionLocationMap widget for reuse
           in INSP-07.
  Depends on: INSP-05

INSP-07  Display GPS map on inspection history / detail view
  Gap:  When a future inspection detail/history page is built, the stored
        gps coordinates in inspections.gps should be shown on a map.
  Work: Read gps from the inspection row and render InspectionLocationMap
        (built in INSP-06) with the stored coordinates.
  Depends on: INSP-06

--------------------------------------------------
MODULE: INSPECTION FORM TEMPLATES
--------------------------------------------------

FORM-01  Confirm inspection_templates INSERT is wired in create page  `DONE — 2026-03-12`
  File: lib/pages/inspection_forms/create_inspection_form_page/
  Verified: Save button calls wrapSchema() then InspectionTemplatesTable().insert()
            with org_id, name, schema, category. Navigates to InspectionGalleryPage on success.

FORM-02  Confirm inspection_templates UPDATE is wired in edit page  `DONE — 2026-03-12`
  File: lib/pages/inspection_forms/edit_inspection_form_page/
  Verified: Save button calls wrapSchema() then InspectionTemplatesTable().update()
            matching on id. Updates name, schema, category. Navigates back on success.

FORM-03  Redesign "Use Existing Form" selection flow  [IN PROGRESS — 2026-03-14]
  Replaces: choose_inspection_form_page, inspection_gallery_page,
            preview_inspection_form_page (FlutterFlow-generated, do not match new UI)
  Design:   4-screen flow from UI/UX designers (DM Sans, sky-blue palette)
  Screens:
    Screen 1 — ChooseFormLandingPage   (lib/features/inspection_form/pages/)  `DONE`
      "Use Existing Form" card + "Build New Form" row
      Categories fetched from DB, scrollable chips
    Screen 2 — FormSearchPage  `DONE`
      Live search (300ms debounce) + category filter chips + results list
      Infinite scroll, stagger animation, step count in rows
    Screen 3 — FormDetailsPage  `DONE`
      Accordion step config panels (per-type: numeric, multi-check, etc.)
      Preview button (icon + label, purple theme) → FormPreviewScreen
      "Use This Form" → ConfirmActionDialog → duplicates predefined template
        with user's org_id, is_predefined=false → navigates to Screen 4
    Screen 3A — FormPreviewScreen  `DONE`
      Standalone interactive preview (no FFAppState)
      Mobile: dark banner + progress header + AnimatedSwitcher steps
      Tablet (≥768px): banner + header + sidebar step list + content
      Reuses InspectionItemStep (callbacks) + InspectionSummaryView(onSubmit: null)
      Local state: _stepIndex, _answerCache, _answeredItems, _goingForward
    Screen 4 — FormConfirmedPage  `DONE — UI only`
      Animated green checkmark, form summary, breadcrumb trail,
      "Select Asset & Begin" + secondary actions (Change Form, Edit This Form, Go to Dashboard)
      Silent duplicate-template cleanup on any back navigation (PopScope fire-and-forget)
    Screen 5 — SelectAssetPage  `DONE — 2026-03-14`
      lib/features/asset_selection/pages/select_asset_page.dart
      Search bar (300ms debounce) + category filter chips + asset cards
      Selection state with sticky footer (recap strip + "Begin Inspection" green button)
      Overflow bottom sheet: Change Form, Go to Dashboard, Cancel Inspection
      Cancel bottom sheet with red confirm + "Keep Going"
      Inspection status from last_inspected_at: ok/due/overdue (green/amber/red)
      Two entry points:
        1. From FormConfirmedPage "Select Asset & Begin" → form + schemaItems passed
        2. From drawer "Inspect Asset" → no form, standalone mode
      On "Begin Inspection": sets templateJson + calls initInspectionDraft → pushes InspectAsset
      Registered as GoRouter route: /selectAssetPage
      Context-aware drawer `DONE — 2026-03-14`:
        - Standalone entry (from drawer): shows hamburger menu + app drawer, hides "Change Form" in overflow
        - Form flow entry (from FormConfirmedPage): shows back button, full overflow menu
        - Uses `widget.form == null` as discriminator (`_isStandalone` getter)
        - `_scaffoldKey` (GlobalKey<ScaffoldState>) for programmatic drawer open
      Layout fix `DONE — 2026-03-14`:
        - Replaced Scaffold.bottomSheet (was expanding to cover body → blank page)
          with Stack + Positioned for sticky footer overlay
  Drawer wiring `DONE — 2026-03-14`:
    lib/pages/components/app_drawer_content/app_drawer_content_widget.dart
      "Inspect Asset" item under inspections menu now navigates to SelectAssetPage
      (was AssetListPageWidget). "Assets" item under Asset Management unchanged.
  New shared component:
    lib/common/components/confirm_action_dialog.dart  `DONE`
      Reusable Cancel/Confirm dialog (same style as ConfirmQuitInspectionDialog
      but without "type confirm" text field). Static show() → Future<bool>.
  Nav wiring: replace existing FFRoute entries for /chooseInspectionFormPage
              and /inspectionGalleryPage; push Screens 2-4 imperatively
  Still TODO:
    - Wire "Edit This Form" on FormConfirmedPage → navigate to form editor for duplicated template
    - Wire "Go to Dashboard" on FormConfirmedPage + SelectAssetPage → navigate to dashboard
    - DB fix: UPDATE inspection_templates SET org_id = NULL WHERE is_predefined = true
    - Update card editor + create form to use category picker (hardcoded 'Vehicles')
  Depends on: INSP-01, INSP-03

FORM-04  Verify preview_inspection_form_page renders real template data
  Note: Screen 3 (FormPreviewPage) of FORM-03 supersedes this for the
        inspection-start flow. This ticket remains only if the old
        preview page is still needed for form management (admin view).
  File: lib/pages/inspection_forms/preview_inspection_form_page/
  Work: After FORM-03 is live, decide whether to delete or repurpose.

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
MODULE: ASSET CATEGORIES (org-managed)
--------------------------------------------------

Priority: Medium. Replaces the hardcoded 9-value category enum with an
org-scoped lookup table. Follows the same pattern as template_categories.
Current state: assets.category is a text column with a CHECK constraint
limiting values to 9 hardcoded strings. Labels and icons are duplicated
across add_asset_page, select_asset_page, and the _kCategoryLabels map.

ACAT-01  Create asset_categories table and migrate data
  Gap:  Asset categories are a hardcoded CHECK constraint on assets.category.
        Orgs cannot add, rename, or reorder categories.
  Work: 1. Create asset_categories table:
            id (uuid PK), org_id (uuid FK → orgs), name (text),
            icon (text, nullable — icon key for Flutter lookup),
            sort_order (int), created_at, updated_at
         2. Seed default rows for every existing org using the current 9
            categories (vehicle, trailer, heavy_equipment, etc.) with
            sensible sort_order values.
         3. Add category_id (uuid FK → asset_categories) column to assets.
         4. Backfill assets.category_id from the existing text category
            column matched against the seeded rows for each org.
         5. Drop the CHECK constraint on assets.category.
         6. (Future migration) Drop the old assets.category text column
            once all Flutter code reads category_id exclusively.
  Notes: - Seed must run per-org so each org gets its own rows.
         - Keep assets.category readable (do not drop yet) for backward
           compat during migration.

ACAT-02  Update add/edit asset pages to use category picker
  Gap:  Add and edit asset pages use a hardcoded dropdown with 9 enum values.
  Work: 1. Fetch asset_categories for the current org (ordered by sort_order).
         2. Replace the hardcoded dropdown with a picker populated from DB rows.
         3. Write category_id (uuid) to assets on insert/update instead of
            the text category column.
         4. Update upsert_asset.dart to send category_id.
  Files: lib/pages/assets/add_asset_page/add_asset_page_widget.dart
         lib/pages/assets/edit_asset_page/edit_asset_page_widget.dart
         lib/custom_code/actions/upsert_asset.dart
  Depends on: ACAT-01

ACAT-03  Update SelectAssetPage filter chips to read from DB
  Gap:  SelectAssetPage builds filter chips from whatever category strings
        exist on fetched assets. Icons are mapped via _assetCategoryIcon()
        using a hardcoded switch.
  Work: 1. Fetch asset_categories for the current org on page init.
         2. Build filter chips from the DB rows (name + sort_order).
         3. Filter assets by category_id match instead of text comparison.
         4. Replace _assetCategoryIcon() and _kCategoryLabels with a
            data-driven icon/label lookup from the fetched category rows.
         5. Remove hardcoded _kCategoryLabels map.
  File: lib/features/asset_selection/pages/select_asset_page.dart
  Depends on: ACAT-01

ACAT-04  Build asset category management screen (org settings)
  Gap:  No UI exists for orgs to manage their asset categories.
  Work: 1. Create a settings/categories page where org admins can:
            - Add new categories (name, optional icon)
            - Rename existing categories
            - Reorder categories (drag or sort_order buttons)
            - Delete categories (only if no assets reference them,
              or reassign assets first)
         2. Wire from an org settings / admin section (location TBD).
  Depends on: ACAT-01
  Notes: Can be backlogged until an org settings section is built.
         The seeded defaults cover users until then.

ACAT-05  Seed default asset categories on new org creation
  Gap:  ACAT-01 seeds categories for existing orgs, but new orgs created
        after the migration also need defaults.
  Work: Add a DB trigger or update the onboarding RPC (upsert_onboarding_v3)
        to insert the default 9 asset_categories rows when a new org is
        created.
  Depends on: ACAT-01

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

--------------------------------------------------
MODULE: TECH DEBT / CLEANUP
--------------------------------------------------

Priority: Low. Tackle incrementally as files are touched for real work.

TECH-01  Route all caught errors to global error logger
  Gap:  Many catch blocks handle errors gracefully (snackbar, debugPrint) but
        swallow the exception — it never reaches the global error handler and
        is not recorded in the app_errors table. This makes production issues
        invisible.
  Work: Audit all try/catch blocks across the codebase. In every catch that
        handles an error locally (snackbar, fallback, etc.), add a call to
        logCaughtError() so the error is also sent to the Supabase Edge
        Function for logging. The logCaughtError() helper was added to
        init_global_error_logging.dart (errorType: 'CaughtError').
        Priority files:
          - lib/features/ (all feature code)
          - lib/custom_code/actions/ (all custom actions)
        Exclude: FlutterFlow-generated code (lib/flutter_flow/*, lib/pages/*)
  Depends on: nothing

TECH-02  Field readability — bump text sizes on FF-generated pages
  Gap:  Custom feature pages bumped to min 12px (2026-03-14).
        FlutterFlow-generated pages (lib/pages/*, lib/flutter_flow/*) still
        use small sizes (9–11px) that are hard to read outdoors.
  Work: Audit and bump when those pages are included in MVP scope.
        Follow the field readability guidelines in 03_ui_system.md.
  Depends on: nothing

TECH-03  Fix FlutterFlow-generated analyzer warnings
  Gap:  ~3000 analyzer warnings and infos from FlutterFlow-generated code
        (lib/flutter_flow/*, lib/pages/*, lib/backend/*). Now that FlutterFlow
        is no longer used, these should be cleaned up.
  Work: Fix warnings file-by-file as each file is touched for feature work.
        Do not batch-fix in a single PR — keep diffs focused.
  Depends on: nothing
