import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Design tokens (from 03_ui_system.md – LightModeTheme)

const Color kInspPrimary     = Color(0xFF27AAE2);
const Color kInspPrimaryText = Color(0xFF1D354F);
const Color kInspSecText     = Color(0xFF57636C);
const Color kInspCard        = Color(0xFFFFFFFF);
const Color kInspBorder      = Color(0xFFE0E3E7);
const Color kInspSuccess     = Color(0xFF00AD07);
const Color kInspError       = Color(0xFFFF3333);
const Color kInspFormField   = Color(0xFFEFF3FA);

// Multi-check card state backgrounds
const Color kInspPassBg     = Color(0xFFF0FDF4); // green-50
const Color kInspPassBorder = Color(0xFFBBF7D0); // green-200
const Color kInspFailBg     = Color(0xFFF8FAFC); // slate-50  (neutral — no red scare)
const Color kInspFailBorder = Color(0xFFE2E8F0); // slate-200 (neutral)
const Color kInspSlate      = Color(0xFFF8FAFC); // slate-50

// Filled segmented-control active colours
const Color kInspPassFill   = Color(0xFF10B981); // emerald-500
const Color kInspFailFill   = Color(0xFFEF4444); // red-500 (Fail chip only)

// Fail-state text / dot — amber tones (non-alarming)
const Color kInspFailDot    = Color(0xFFF59E0B); // amber-500  (status dot)
const Color kInspFailText   = Color(0xFFB45309); // amber-700  (sub-labels)

// Amber / warning
const Color kInspWarning       = Color(0xFFF59E0B);
const Color kInspWarningBg     = Color(0xFFFEF3C7);
const Color kInspWarningBorder = Color(0xFFFCD34D);

TextStyle inspInterStyle(double size, FontWeight weight, Color color) =>
    GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: 0.0,
    );
