import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class CarbonTypography {
  static TextStyle get displayXl => GoogleFonts.ibmPlexSans(
        fontSize: 76.0,
        fontWeight: FontWeight.w300,
        height: 1.17,
        letterSpacing: -0.5,
        color: CarbonColors.ink,
      );

  static TextStyle get displayLg => GoogleFonts.ibmPlexSans(
        fontSize: 60.0,
        fontWeight: FontWeight.w300,
        height: 1.17,
        letterSpacing: -0.4,
        color: CarbonColors.ink,
      );

  static TextStyle get displayMd => GoogleFonts.ibmPlexSans(
        fontSize: 42.0,
        fontWeight: FontWeight.w300,
        height: 1.20,
        letterSpacing: 0,
        color: CarbonColors.ink,
      );

  static TextStyle get headline => GoogleFonts.ibmPlexSans(
        fontSize: 32.0,
        fontWeight: FontWeight.w400,
        height: 1.25,
        letterSpacing: 0,
        color: CarbonColors.ink,
      );

  static TextStyle get cardTitle => GoogleFonts.ibmPlexSans(
        fontSize: 24.0,
        fontWeight: FontWeight.w400,
        height: 1.33,
        letterSpacing: 0,
        color: CarbonColors.ink,
      );

  static TextStyle get subhead => GoogleFonts.ibmPlexSans(
        fontSize: 20.0,
        fontWeight: FontWeight.w400,
        height: 1.40,
        letterSpacing: 0,
        color: CarbonColors.ink,
      );

  static TextStyle get bodyLg => GoogleFonts.ibmPlexSans(
        fontSize: 18.0,
        fontWeight: FontWeight.w400,
        height: 1.50,
        letterSpacing: 0,
        color: CarbonColors.ink,
      );

  static TextStyle get body => GoogleFonts.ibmPlexSans(
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
        height: 1.50,
        letterSpacing: 0.16,
        color: CarbonColors.ink,
      );

  static TextStyle get bodySm => GoogleFonts.ibmPlexSans(
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
        height: 1.29,
        letterSpacing: 0.16,
        color: CarbonColors.ink,
      );

  static TextStyle get bodyEmphasis => GoogleFonts.ibmPlexSans(
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
        height: 1.29,
        letterSpacing: 0.16,
        color: CarbonColors.ink,
      );

  static TextStyle get caption => GoogleFonts.ibmPlexSans(
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
        height: 1.33,
        letterSpacing: 0.32,
        color: CarbonColors.inkMuted,
      );

  static TextStyle get button => GoogleFonts.ibmPlexSans(
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
        height: 1.29,
        letterSpacing: 0.16,
        color: CarbonColors.onPrimary,
      );

  static TextStyle get eyebrow => GoogleFonts.ibmPlexSans(
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
        height: 1.29,
        letterSpacing: 0.16,
        color: CarbonColors.inkMuted,
      );
}
