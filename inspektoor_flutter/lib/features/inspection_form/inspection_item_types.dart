// ─── InspectionItemTypes ─────────────────────────────────────────────────────
//
// Pure-Dart type registry for inspection item types.
// No Flutter / FlutterFlow imports.
//
// Single source of truth for:
//   • The canonical type string stored in template JSON (e.g. 'single-check')
//   • The UI display label shown in the dropdown (e.g. 'Single Check')
//   • The section group used for future grouped-dropdown UX
//
// Adding a new type in the future = add one entry to kInspectionItemTypes.
// Everything else (builder UI, execution renderer) picks it up via the registry.

class InspectionItemTypeDef {
  /// Canonical string stored in template / draft JSON.
  final String type;

  /// Human-readable label shown in the type dropdown.
  final String label;

  /// Section heading for future grouped-dropdown UX.
  final String group;

  const InspectionItemTypeDef({
    required this.type,
    required this.label,
    required this.group,
  });
}

const List<InspectionItemTypeDef> kInspectionItemTypes = [
  InspectionItemTypeDef(type: 'single-check',    label: 'Single Check',            group: 'Defect Cards'),
  InspectionItemTypeDef(type: 'multi-check',     label: 'Multi Check',             group: 'Defect Cards'),
  InspectionItemTypeDef(type: 'multiple-choice', label: 'Multiple Choice',         group: 'Defect Cards'),
  InspectionItemTypeDef(type: 'photo',           label: 'Photo',                   group: 'Photo'),
  InspectionItemTypeDef(type: 'numeric',         label: 'Data Entry Numeric',      group: 'Data Entry'),
  InspectionItemTypeDef(type: 'alphanumeric',    label: 'Data Entry Alphanumeric', group: 'Data Entry'),
  InspectionItemTypeDef(type: 'comment-box',     label: 'Comment Box',             group: 'Data Entry'),
  InspectionItemTypeDef(type: 'signature',       label: 'Signature',               group: 'Data Entry'),
];

/// All display labels in dropdown order.
List<String> get kItemTypeLabels => kInspectionItemTypes
    .map((t) => t.label)
    .toList();

/// Returns the display label for a given canonical type string.
/// Falls back to the type string itself if not found.
String labelFromType(String? type) => kInspectionItemTypes
    .where((t) => t.type == type)
    .map((t) => t.label)
    .firstOrNull ??
    (type ?? 'Unknown');

/// Returns the canonical type string for a given display label.
/// Falls back to 'multi-check' for unknown labels (backward compatibility).
String typeFromLabel(String? label) => kInspectionItemTypes
    .firstWhere(
      (t) => t.label == label,
      orElse: () => kInspectionItemTypes[1], // 'multi-check'
    )
    .type;
