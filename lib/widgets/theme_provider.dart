import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void toggleDarkMode(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setSystemTheme() {
    _themeMode = ThemeMode.system;
    notifyListeners();
  }

  // Paleta base
  static const Color primary = Color(0xFFDC143C); // Crimson
  static const Color secondary = Color(0xFFB11030); // Detalhes
  static const Color accentBlue = Color(0xFF007AFF); // Links, destaques
  static const Color success = Color(0xFF28A745); // Sucesso
  static const Color warning = Color(0xFFFFC107); // Aviso
  static const Color error = Color(0xFFFF3B30); // Erro
  static const Color info = Color(0xFF17A2B8); // Informativo

  // Tons de superfície e texto
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textLight = Color(0xFF1E1E1E);
  static const Color textDark = Color(0xFFF6F0E8);

  static const Color hover = Color(0xFFFF5C77);

  /// Tipografia base
  static const TextTheme lightTextTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textLight),
    displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textLight),
    displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textLight),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textLight),
    headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textLight),
    titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textLight),
    bodyLarge: TextStyle(fontSize: 14, color: textLight, height: 1.4),
    bodyMedium: TextStyle(fontSize: 13, color: textLight, height: 1.4),
    bodySmall: TextStyle(fontSize: 12, color: Colors.grey),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primary),
  );

  static const TextTheme darkTextTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textDark),
    displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textDark),
    displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textDark),
    headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textDark),
    titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textDark),
    bodyLarge: TextStyle(fontSize: 14, color: textDark, height: 1.4),
    bodyMedium: TextStyle(fontSize: 13, color: textDark, height: 1.4),
    bodySmall: TextStyle(fontSize: 12, color: Colors.grey),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primary),
  );

  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey.shade100,
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: primary,
          onPrimary: Colors.white,
          secondary: accentBlue,
          onSecondary: Colors.white,
          surface: surfaceLight,
          onSurface: textLight,
          error: error,
          onError: Colors.white,
          background: Colors.grey.shade100,
          onBackground: textLight,
        ),
        textTheme: lightTextTheme,
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: secondary,
          contentTextStyle: const TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        cardTheme: CardThemeData(
          color: surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: surfaceLight,
          titleTextStyle: TextStyle(
            color: textLight,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: secondary),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      );

  ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: primary,
          onPrimary: Colors.white,
          secondary: accentBlue,
          onSecondary: Colors.white,
          surface: surfaceDark,
          onSurface: textDark,
          error: error,
          onError: Colors.white,
          background: Colors.black,
          onBackground: textDark,
        ),
        textTheme: darkTextTheme,
        appBarTheme: const AppBarTheme(
          backgroundColor: surfaceDark,
          foregroundColor: textDark,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: secondary,
          contentTextStyle: const TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        cardTheme: CardThemeData(
          color: surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: surfaceDark,
          titleTextStyle: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.grey),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      );
}
