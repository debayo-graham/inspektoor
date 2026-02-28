// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/custom_code/actions/index.dart';
import '/flutter_flow/custom_functions.dart';

import 'package:uuid/uuid.dart';

num? _parseNum(String? s) {
  if (s == null || s.trim().isEmpty) return null;
  return num.tryParse(s.trim());
}

int _parseIntOrZero(String? s) {
  if (s == null || s.trim().isEmpty) return 0;
  return int.tryParse(s.trim()) ?? 0;
}

int? _parseIntOrNull(String? s) {
  if (s == null || s.trim().isEmpty) return null;
  return int.tryParse(s.trim());
}

// Converts nullable string to trimmed safe string.
String _s(String? v) => (v ?? '').trim();

Future<dynamic> buildCard(
  String mode,
  dynamic? incomingItem, // pass full card JSON on edit, leave unset on create
  int index, // parent should send inspectionFormItems -> Number of Items
  String type,
  String label,
  String? icon, // nullable is fine
  List<dynamic>? checksList,
  List<dynamic>? options,
  bool? allowMultiple,
  bool? photoRequired,
  String? minVal,
  String? maxVal,
  String? placeholder,
  String? unit,
  String? note,
  String? minPhotos,
  String? maxPhotos,
  List<dynamic>? examples,
  String? maxLength,
  String? regex,
) async {
  final bool hasIncomingMap = incomingItem is Map;

  // Preserve key/order on edit. Create new key and use index on create.
  final key = (mode == "edit" &&
          hasIncomingMap &&
          (incomingItem as Map).containsKey("key"))
      ? incomingItem["key"]
      : "item_${const Uuid().v4()}";

  final order = (mode == "edit" &&
          hasIncomingMap &&
          (incomingItem as Map).containsKey("order"))
      ? incomingItem["order"]
      : index + 1; // 1-based on create

  // Default Pass/Fail and normalized options
  final defaultOptions = [
    {"label": "Pass"},
    {"label": "Fail"}
  ];
  final List<dynamic> opts =
      (options == null || (options is List && options.isEmpty))
          ? defaultOptions
          : options;

  final iconStr = _s(icon);
  final placeholderStr = _s(placeholder);
  final unitStr = _s(unit);
  final regexStr = _s(regex);

  Map<String, dynamic> config = {};

  switch (type) {
    case "single-check":
      config = {
        "options": opts,
        "photoRequired": photoRequired ?? false,
      };
      break;

    case "multi-check":
      config = {
        "checks": checksList ?? [],
        "options": opts,
        "photoRequired": photoRequired ?? false,
      };
      break;

    case "multiple-choice":
      config = {
        "options": opts,
        "allowMultiple": allowMultiple ?? false,
      };
      break;

    case "numeric":
      config = {
        "min": _parseNum(minVal),
        "max": _parseNum(maxVal),
        "placeholder": placeholderStr,
        "unit": unitStr.isEmpty ? null : unitStr,
        "options": opts,
      };
      break;

    case "photo":
      config = {
        "note": note ?? "",
        "minPhotos": _parseIntOrZero(minPhotos),
        "maxPhotos": _parseIntOrZero(maxPhotos),
        "examples": examples ?? [],
        "options": opts,
      };
      break;

    case "comment-box":
      config = {
        "placeholder": placeholderStr,
        "maxLength": _parseIntOrNull(maxLength),
        "options": opts,
      };
      break;

    case "signature":
      config = {
        "note": note ?? "Please sign",
        "options": opts,
      };
      break;

    case "alphanumeric":
      config = {
        "placeholder": placeholderStr,
        "maxLength": _parseIntOrNull(maxLength),
        "regex": regexStr.isEmpty ? null : regexStr,
        "options": opts,
      };
      break;

    default:
      config = {"options": opts};
  }

  final result = {
    "key": key,
    "order": order,
    "type": type,
    "label": label,
    "icon": iconStr.isEmpty ? null : iconStr,
    "config": config,
  };

  return result;
}
