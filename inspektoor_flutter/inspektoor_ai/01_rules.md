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