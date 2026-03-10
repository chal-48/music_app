import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================================
// AppTheme — Design tokens ทั้งหมดอยู่ที่นี่ที่เดียว
// ใช้ context.watch<ThemeProvider>().isDarkMode แล้วส่ง isDark ให้ AppTheme
// ============================================================================
class AppTheme {
  final bool isDark;
  const AppTheme({required this.isDark});

  // ---------- Colors ----------
  static const Color accent     = Color(0xFFFF5500);
  static const Color accentGlow = Color(0x73FF5500); // 45% opacity

  Color get bg           => isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F2);
  Color get surface      => isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF);
  Color get surfaceHigh  => isDark ? const Color(0xFF242424) : const Color(0xFFEEEEEE);
  Color get border       => isDark ? Colors.white12           : Colors.black12;
  Color get divider      => isDark ? Colors.white12           : Colors.black12;

  Color get textPrimary  => isDark ? Colors.white             : const Color(0xFF111111);
  Color get textSecond   => isDark ? Colors.white60           : Colors.black54;
  Color get textHint     => isDark ? Colors.white38           : Colors.black38;
  Color get iconMuted    => isDark ? Colors.white24           : Colors.black26;

  Color get sheetBg      => isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF);
  Color get bottomSheetDrag => isDark ? Colors.grey.shade700  : Colors.grey.shade400;

  // ---------- Typography ----------
  TextStyle headline(double size) => GoogleFonts.inter(
    color: textPrimary, fontSize: size, fontWeight: FontWeight.bold);

  TextStyle body(double size) => GoogleFonts.inter(
    color: textPrimary, fontSize: size);

  TextStyle secondary(double size) => GoogleFonts.inter(
    color: textSecond, fontSize: size);

  TextStyle hint(double size) => GoogleFonts.inter(
    color: textHint, fontSize: size);

  TextStyle accent_(double size, {FontWeight w = FontWeight.normal}) =>
    GoogleFonts.inter(color: accent, fontSize: size, fontWeight: w);

  // ---------- Decoration Helpers ----------
  BoxDecoration cardDecoration({double radius = 12}) => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(radius),
  );

  BoxDecoration accentButtonDecoration({double radius = 30}) => BoxDecoration(
    color: accent,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [BoxShadow(color: accentGlow, blurRadius: 12, offset: const Offset(0, 4))],
  );

  InputDecoration searchFieldDecoration({String hint = 'Search...'}) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(color: textHint),
    prefixIcon: Icon(Icons.search_rounded, color: accent),
    filled: true,
    fillColor: surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(50),
      borderSide: const BorderSide(color: accent, width: 1.5),
    ),
  );

  InputDecoration textFieldDecoration(String label, {IconData? prefixIcon, Widget? suffixIcon}) => InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.inter(color: textHint),
    floatingLabelStyle: GoogleFonts.inter(color: accent),
    prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: textHint, size: 20) : null,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: accent, width: 1.5),
    ),
  );
}