import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NeonTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    textTheme: GoogleFonts.orbitronTextTheme().apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xff9c27ff), // neon purple
      secondary: Color(0xff00eaff), // neon cyan
    ),
  );
}
