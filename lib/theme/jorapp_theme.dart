import 'package:flutter/material.dart';

class JorappColors {
  static const Color lime = Color(0xFFD7E337);
  static const Color teal = Color(0xFF1F6481);
  static const Color tealDark = Color(0xFF15495F);
  static const Color ink = Color(0xFF142228);
  static const Color surface = Color(0xFFF5F8F0);
  static const Color surfaceStrong = Color(0xFFE8F0DF);
}

ThemeData buildJorappTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: JorappColors.teal,
    onPrimary: Colors.white,
    secondary: JorappColors.lime,
    onSecondary: JorappColors.ink,
    error: Color(0xFFB3261E),
    onError: Colors.white,
    surface: JorappColors.surface,
    onSurface: JorappColors.ink,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: JorappColors.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: JorappColors.surface,
      foregroundColor: JorappColors.ink,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: JorappColors.ink,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: JorappColors.tealDark,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return JorappColors.teal;
        }
        return Colors.white;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return JorappColors.lime.withOpacity(0.65);
        }
        return const Color(0xFFD1D9C9);
      }),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: JorappColors.teal,
      foregroundColor: Colors.white,
    ),
  );
}
