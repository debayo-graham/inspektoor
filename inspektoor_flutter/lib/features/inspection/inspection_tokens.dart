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

TextStyle inspInterStyle(double size, FontWeight weight, Color color) =>
    GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: 0.0,
    );
