import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFont {
  static TextStyle title({
    double size = 22,
    Color color = Colors.white,
    FontWeight weight = FontWeight.bold,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  static TextStyle body({
    double size = 14,
    Color color = Colors.white,
    FontWeight weight = FontWeight.normal,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  static TextStyle subtitle({
    double size = 12,
    Color color = Colors.grey,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      color: color,
    );
  }
}