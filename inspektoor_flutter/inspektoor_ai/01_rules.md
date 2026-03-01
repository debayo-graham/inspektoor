Operating Rules:

1. Do NOT redesign the system architecture.
2. Do NOT introduce new frameworks, libraries, or patterns unless explicitly instructed.
3. Only document or extend what already exists in the codebase.
4. Work incrementally and limit analysis strictly to the scope of the current task.
5. Never rescan the whole project unless explicitly told to do so.
6. Treat markdown files in this folder as the persistent source of truth between sessions.
7. Update AI memory files when tasks are completed so knowledge stays aligned with code.
8. Prefer minimal, surgical changes rather than large refactors.

--------------------------------------------------
FlutterFlow Freeze Rule (Critical)
--------------------------------------------------

The project originated from a FlutterFlow export, but FlutterFlow is NO LONGER
used for new development.

All FlutterFlow-generated code is now considered a legacy layer and must remain
unchanged unless a specific migration task explicitly allows modification.

You must NOT modify, extend, or depend on:

- Any file that extends `FlutterFlowModel`
- Anything inside the `lib/flutter_flow/` directory
- `flutter_flow_theme.dart`
- `flutter_flow_util.dart`
- `flutter_flow_widgets.dart`
- Existing FlutterFlow-generated widgets or models

These files are frozen to avoid destabilizing the application.

--------------------------------------------------
Rules for New Development
--------------------------------------------------

All new functionality must be implemented OUTSIDE the FlutterFlow layer.

When creating new code:

- Use plain Dart classes or standard Flutter state management only
  (e.g., ChangeNotifier, ValueNotifier, or simple controllers).
- Do NOT import anything from the `flutter_flow` directory.
- Do NOT subclass `FlutterFlowModel`.
- Place new work in clearly separated feature-based folders.
- Ensure new code can function independently from FlutterFlow.

This establishes a parallel clean layer that will eventually replace the legacy layer.

--------------------------------------------------
Migration Policy
--------------------------------------------------

Removal of FlutterFlow is a future, controlled migration step.
It is NOT part of normal feature development.

Do NOT attempt to refactor or replace FlutterFlow code unless the backlog
explicitly includes a migration task.

--------------------------------------------------
Session Discipline
--------------------------------------------------

After completing any implementation task:

- Update `06_module_inventory.md` to reflect new state.
- Update `07_backlog.md` to mark progress.
- Update `08_session_state.md` with a concise summary of what changed.

This ensures future sessions do not repeat analysis.


--------------------------------------------------
Additional
--------------------------------------------------

- When you have done coding a back log mark the necessary places in the md files as QA not DONE. I will give you instructions when to mack the item as DONE when we have completed testing 
- QA should never be treated as a completed item

 -----------------------------------------------
  Feature Structure Enforcement Rule (Critical)
  -----------------------------------------------

All new feature development must follow a strict folder structure to
maintain separation of concerns and prevent code sprawl.

  -----------------------------------
  Required Feature Folder Structure
  -----------------------------------

Each feature must be created under:

lib/features/`<feature_name>`{=html}/

Each feature must contain the following subfolders:

lib/features/`<feature_name>`{=html}/pages/
lib/features/`<feature_name>`{=html}/components/

Reusable utilities that are shared across features must be placed in:

lib/utils/

  -------------------------
  Folder Responsibilities
  -------------------------

pages/

-   Contains full screen widgets only.
-   One file per screen.
-   Handles layout and orchestration only.
-   Must not contain business logic.
-   Must not contain reusable widgets.
-   Must not contain utility or helper functions.
-   Page files must end with `_page.dart`.

components/

-   Contains reusable UI elements specific to that feature.
-   Must not contain application-wide utilities.
-   Must not depend on FlutterFlow.
-   Must receive all data via constructor parameters.
-   Must not manage global state.

utils/

-   Contains reusable helpers shared across multiple features.
-   Should be written as pure Dart when possible.
-   Must not contain UI code.
-   Must not import from flutter_flow.
-   Must not contain feature-specific logic.
-   If logic is reused by more than one feature, it belongs here.

 -------------------------
  Common Folder
 -------------------------
- for components and code that you see in the future that can be reused placed it in a common folder outside the feature folder. this makes it easer to reuse as we add more features

  ------------------
  Structural Rules
  ------------------1

-   No feature code may be placed directly inside lib/.
-   No reusable widget may be created inside a pages/ folder.
-   No helper or utility logic may be placed inside page or component
    files.
-   Cross-feature imports should be avoided. If reuse is needed, move
    the logic into lib/utils/.
-   FlutterFlow legacy files must not be modified or referenced.
-   All new development must remain independent from FlutterFlow.
-   Each feature must remain self-contained and modular.

  ---------
  Purpose
  ---------

This structure ensures:

-   Predictable project organization.
-   Clear separation between screens, components, and shared logic.
-   Reduced maintenance complexity.
-   Safer long-term removal of FlutterFlow dependencies.
-   Incremental evolution toward a clean architecture without large
    refactors.