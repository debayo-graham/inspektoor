import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'lat_lng.dart';
import 'place.dart';
import 'uploaded_file.dart';
import '/backend/supabase/supabase.dart';
import '/auth/supabase_auth/auth_util.dart';

int increment(int value) {
  return value + 1;
}

int incrementSteps(
  int currentStep,
  int maxSteps,
) {
  if (currentStep < maxSteps) {
    return currentStep + 1;
  }
  return currentStep;
}

int decrementSteps(int currentStep) {
  if (currentStep > 1) {
    return currentStep - 1;
  }
  return currentStep;
}

bool isGreaterThanZero(String? value) {
  final numVal = int.tryParse(value ?? '') ?? 0;
  return numVal > 0;
}

int toIntOrZero(String? s) {
  if (s == null) return 0;
  final v = int.tryParse(s.trim());
  return v ?? 0;
}

String formatTwoDecimalFromString(String value) {
  if (value.isEmpty) return "0.00";

  final parsed = double.tryParse(value) ?? 0.0;
  return parsed.toStringAsFixed(2);
}

String totalDueTwoDecimal(
  String unitPrice,
  int assetCount,
  String discount,
  String tax,
) {
  final p = double.tryParse(unitPrice) ?? 0.0;
  final d = double.tryParse(discount) ?? 0.0;
  final t = double.tryParse(tax) ?? 0.0;

  final total = (p * assetCount) - d + t;
  return total.toStringAsFixed(2);
}

String subtotalTwoDecimal(
  String unitPrice,
  int assetCount,
) {
  final p = double.tryParse(unitPrice) ?? 0.0;
  final subtotal = p * assetCount;
  return subtotal.toStringAsFixed(2);
}

dynamic validateField(
  String? value,
  String type,
  bool requiredField,
  String label,
  int? minLength,
  int? maxLength,
  double? min,
  double? max,
  int? minAge,
  int? maxAge,
  String? pattern,
) {
  final v = (value ?? '').trim(); // treat null as empty string

  // Required
  if (requiredField && v.isEmpty) {
    return {"valid": false, "error": "$label is required."};
  }
  if (v.isEmpty) return {"valid": true, "error": null};

  // Email
  if (type == 'email') {
    final emailRegex = RegExp(
      r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$',
      caseSensitive: false,
    );
    if (!emailRegex.hasMatch(v)) {
      return {"valid": false, "error": "Enter a valid email address."};
    }
  }

  // Number
  else if (type == 'number') {
    final parsed = double.tryParse(v);
    if (parsed == null) {
      return {"valid": false, "error": "$label must be a number."};
    }
    if (min != null && parsed < min) {
      return {"valid": false, "error": "$label must be at least $min."};
    }
    if (max != null && parsed > max) {
      return {"valid": false, "error": "$label must be at most $max."};
    }
  }

  // Date (expects YYYY-MM-DD)
  else if (type == 'date') {
    try {
      final parsedDate = DateTime.parse(v);
      final now = DateTime.now();

      final age = now.year -
          parsedDate.year -
          ((now.month < parsedDate.month ||
                  (now.month == parsedDate.month && now.day < parsedDate.day))
              ? 1
              : 0);

      if (minAge != null && age < minAge) {
        return {
          "valid": false,
          "error": "You must be at least $minAge years old."
        };
      }
      if (maxAge != null && age > maxAge) {
        return {
          "valid": false,
          "error": "You must be younger than $maxAge years old."
        };
      }
    } catch (_) {
      return {
        "valid": false,
        "error": "$label must be a valid date (YYYY-MM-DD)."
      };
    }
  } else if (type == 'text') {
    // nothing special here — the length and pattern checks below will still run
  }

  // Length (for text)
  if (minLength != null && v.length < minLength) {
    return {
      "valid": false,
      "error": "$label must be at least $minLength characters."
    };
  }
  if (maxLength != null && v.length > maxLength) {
    return {
      "valid": false,
      "error": "$label must be at most $maxLength characters."
    };
  }

  // Regex pattern
  if (pattern != null && pattern.isNotEmpty) {
    final re = RegExp(pattern);
    if (!re.hasMatch(v)) {
      return {"valid": false, "error": "$label is invalid."};
    }
  }

  return {"valid": true, "error": null};
}

String formatDateYMD(String dateString) {
  if (dateString.trim().isEmpty) return '';

  final parts = dateString.split('-');
  if (parts.length != 3) return '';

  final year = parts[0];
  final monAbbr = parts[1].toLowerCase();
  final day = parts[2].padLeft(2, '0');

  const months = {
    "jan": "01",
    "feb": "02",
    "mar": "03",
    "apr": "04",
    "may": "05",
    "jun": "06",
    "jul": "07",
    "aug": "08",
    "sep": "09",
    "oct": "10",
    "nov": "11",
    "dec": "12",
  };

  final monthNum = months[monAbbr.substring(0, 3)];
  if (monthNum == null) return '';

  return "$year-$monthNum-$day";
}

String calcTotalInCents(
  int quantity,
  double unitPrice,
) {
  final total = quantity * unitPrice;

  // Convert dollars to cents and round to avoid floating point issues
  final cents = (total * 100).round();

  return cents.toString();
}

String incrementWithLeadingZero(String numberStr) {
  // Try to parse the incoming string
  final numValue = int.tryParse(numberStr) ?? 0;

  // Increment the number
  final incremented = numValue + 1;

  // If less than 10, pad with leading zero
  if (incremented < 10) {
    return incremented.toString().padLeft(2, '0');
  }

  // Otherwise, just return the number as string
  return incremented.toString();
}

List<dynamic> replaceAtIndex(
  List<dynamic> list,
  int index,
  dynamic value,
) {
  final newList = List<dynamic>.from(list);
  if (index >= 0 && index < newList.length) {
    newList[index] = value;
  }
  return newList;
}

String jsonPathToString(dynamic value) {
  return value.toString();
}

List<dynamic> makeInitialCheck(String id) {
  return [
    {
      "id": id,
      "label": "e.g Is the vehicle registration up to date?",
      "type": "checkbox",
      "photoRequired": false,
      "maxPhotos": 5
    }
  ];
}

int decrementStepsToZero(int currentStep) {
  if (currentStep > 0) {
    return currentStep - 1;
  }
  return currentStep;
}

String? formatDate(String inputDate) {
  try {
    // Handle formats like "5th July 2023" by stripping "st", "nd", "rd", "th"
    final cleaned = inputDate.replaceAll(RegExp(r'(st|nd|rd|th)'), '');

    // Try parsing
    final parsed = DateTime.tryParse(cleaned);
    if (parsed != null) {
      // Format as "July 5, 2023"
      return DateFormat('MMMM d, yyyy').format(parsed);
    }

    // Fallback: try with intl parsing using a custom pattern
    try {
      final parsedAlt = DateFormat('d MMMM yyyy').parse(cleaned);
      return DateFormat('MMMM d, yyyy').format(parsedAlt);
    } catch (_) {}

    // If parsing fails, just return input
    return inputDate;
  } catch (e) {
    return inputDate;
  }
}

String? getSupabaseToken() {
  final session = Supabase.instance.client.auth.currentSession;

  if (session != null && session.accessToken.isNotEmpty) {
    //print('Access token: ${session.accessToken}');
    return session.accessToken;
  } else {
    //print('No active session or token not available.');
    return null;
  }
}

int? addInts(
  int a,
  int b,
) {
  return a + b;
}

List<dynamic> decodeJsonList(String jsonString) {
  try {
    final decoded = json.decode(jsonString);

    // Ensure the decoded value is REALLY a list
    if (decoded is List) {
      return decoded;
    }

    return [];
  } catch (e) {
    print("decodeJsonList ERROR: $e");
    return [];
  }
}

/// This is used when a user is assigning forms to an asset.
///
/// To return a list of JSON objects selected by the user
List<dynamic> filterFormsByIds(
  List<dynamic> forms,
  List<String> ids,
) {
  final idSet = ids.toSet();
  return forms.where((f) {
    final id = f['id']?.toString();
    return id != null && idSet.contains(id);
  }).toList();
}

/// Used to add from ids to list when adding inspection forms associated with
/// an asset
List<String> mergeFormIds(
  List<String> existingIds,
  List<String> newIds,
) {
// Convert to sets ensures all duplicates are removed
  final merged = {...existingIds, ...newIds}.toList();

  // Sort alphabetically
  merged.sort((a, b) => a.compareTo(b));

  return merged;
}

List<dynamic> mergeFormObjects(
  List<dynamic> existingForms,
  List<dynamic> newForms,
) {
  final map = <String, dynamic>{};

  // Add all existing forms (keyed by id)
  for (final f in existingForms) {
    if (f != null && f['id'] != null) {
      map[f['id']] = f;
    }
  }

  // Add all new forms (this overwrites duplicates by id)
  for (final f in newForms) {
    if (f != null && f['id'] != null) {
      map[f['id']] = f;
    }
  }

  final merged = map.values.toList();

  // Sort by name field (null-safe)
  merged.sort((a, b) {
    final nameA = (a['name'] ?? '').toString();
    final nameB = (b['name'] ?? '').toString();
    return nameA.compareTo(nameB);
  });

  return merged;
}

List<dynamic> removeDeletedForms(
  List<dynamic> selectedForms,
  List<dynamic> deletedRows,
) {
// If there are no selected forms or no deleted rows, return original list.
  if (selectedForms.isEmpty || deletedRows.isEmpty) {
    return selectedForms;
  }

  // Extract all inspection_template_id values from the deleted rows.
  final idsToRemove = deletedRows
      .where((row) => row is Map && row.containsKey('inspection_template_id'))
      .map((row) => row['inspection_template_id'])
      .where((id) => id != null)
      .toSet();
  // Using a Set prevents duplicates & improves checking speed.

  // Build a new list keeping only forms whose id is NOT in idsToRemove.
  final updated = selectedForms.where((form) {
    if (form is Map && form.containsKey('id')) {
      final formId = form['id'];
      return !idsToRemove.contains(formId);
    }
    return true; // keep unexpected items (defensive)
  }).toList();

  // Order is preserved because we used .where() in sequence.
  return updated;
}

List<dynamic> removeFormsByIds(
  List<dynamic> selectedForms,
  List<String> idsToDelete,
) {
  if (selectedForms.isEmpty || idsToDelete.isEmpty) {
    return selectedForms;
  }

  // Convert to a Set for fast lookup
  final idsToRemove = idsToDelete.toSet();

  // Keep only items whose "id" field is NOT in idsToRemove
  final updated = selectedForms.where((form) {
    try {
      final formId = form['id'] as String?;
      if (formId == null) return true;
      return !idsToRemove.contains(formId);
    } catch (_) {
      // keep unexpected items instead of failing
      return true;
    }
  }).toList();

  return updated;
}
