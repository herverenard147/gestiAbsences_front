import 'package:flutter/material.dart';

class AppConstants {
  // ── API ──────────────────────────────────────────────────
  // Changer cette URL selon votre environnement
  // Android emulator  : http://10.0.2.2:3000/api
  // iOS simulator     : http://localhost:3000/api
  // Appareil physique : http://[IP_DE_VOTRE_PC]:3000/api
  static const String baseUrl = 'https://gestiabsence.onrender.com/api';

  // ── Couleurs ─────────────────────────────────────────────
  static const Color primary    = Color(0xFF1A1A18);
  static const Color secondary  = Color(0xFF5F5E5A);
  static const Color background = Color(0xFFF5F5F0);
  static const Color surface    = Color(0xFFFFFFFF);
  static const Color border     = Color(0xFFE5E3DC);

  static const Color success    = Color(0xFF3B6D11);
  static const Color successBg  = Color(0xFFEAF3DE);
  static const Color warning    = Color(0xFF854F0B);
  static const Color warningBg  = Color(0xFFFAEEDA);
  static const Color danger     = Color(0xFFA32D2D);
  static const Color dangerBg   = Color(0xFFFCEBEB);
  static const Color info       = Color(0xFF185FA5);
  static const Color infoBg     = Color(0xFFE6F1FB);
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppConstants.primary,
      background: AppConstants.background,
      surface: AppConstants.surface,
    ),
    scaffoldBackgroundColor: AppConstants.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppConstants.surface,
      foregroundColor: AppConstants.primary,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: AppConstants.primary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppConstants.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppConstants.border, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppConstants.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppConstants.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppConstants.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppConstants.secondary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      labelStyle: const TextStyle(fontSize: 13, color: AppConstants.secondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppConstants.primary,
        side: const BorderSide(color: AppConstants.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontSize: 13),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppConstants.border, thickness: 1),
  );
}
