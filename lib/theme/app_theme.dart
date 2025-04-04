// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Palette de couleurs moderne
  static const Color primaryColor = Color(0xFF4F46E5);       // Indigo plus vibrant
  static const Color secondaryColor = Color(0xFF06B6D4);     // Cyan
  static const Color accentColor = Color(0xFFEC4899);        // Rose
  static const Color backgroundColor = Color(0xFFF9FAFB);    // Gris très clair
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFEF4444);         // Rouge vif
  static const Color successColor = Color(0xFF10B981);       // Vert émeraude
  static const Color warningColor = Color(0xFFF59E0B);       // Ambre
  static const Color textColor = Color(0xFF111827);          // Presque noir
  static const Color textLightColor = Color(0xFF6B7280);     // Gris
  static const Color dividerColor = Color(0xFFE5E7EB);       // Gris très clair
  
  // Espacement
  static const double spacing_xs = 4.0;
  static const double spacing_s = 8.0;
  static const double spacing_m = 16.0;
  static const double spacing_l = 24.0;
  static const double spacing_xl = 32.0;
  static const double spacing_xxl = 48.0;
  
  // Rayons
  static const double radius_xs = 4.0;
  static const double radius_s = 8.0;
  static const double radius_m = 12.0;
  static const double radius_l = 16.0;
  static const double radius_xl = 24.0;
  static const double radius_xxl = 32.0;
  
  // Élévations
  static const double elevation_none = 0.0;
  static const double elevation_xs = 1.0;
  static const double elevation_s = 2.0;
  static const double elevation_m = 4.0;
  static const double elevation_l = 8.0;
  static const double elevation_xl = 16.0;
  
  // Durées d'animation
  static const Duration animationDurationShort = Duration(milliseconds: 200);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationLong = Duration(milliseconds: 500);
  
  // Courbes d'animation
  static const Curve animationCurve = Curves.easeInOut;
  
  // Thème clair
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      error: errorColor,
      background: backgroundColor,
      surface: surfaceColor,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: backgroundColor,
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceColor,
      foregroundColor: textColor,
      elevation: elevation_xs,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: GoogleFonts.inter(
        color: textColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      shadowColor: Colors.black.withOpacity(0.05),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: textLightColor,
      elevation: elevation_m,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        elevation: elevation_s,
        shadowColor: primaryColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius_l),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        side: BorderSide(color: primaryColor, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius_l),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius_l),
        borderSide: BorderSide(color: dividerColor, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius_l),
        borderSide: BorderSide(color: dividerColor, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius_l),
        borderSide: BorderSide(color: primaryColor, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius_l),
        borderSide: BorderSide(color: errorColor, width: 1.0),
      ),
      contentPadding: EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 16,
      ),
      hintStyle: GoogleFonts.inter(
        color: textLightColor,
        fontSize: 16,
      ),
      labelStyle: GoogleFonts.inter(
        color: textLightColor,
        fontSize: 16,
      ),
      floatingLabelStyle: GoogleFonts.inter(
        color: primaryColor,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      errorStyle: GoogleFonts.inter(
        color: errorColor,
        fontSize: 12,
      ),
    ),
    cardTheme: CardTheme(
      color: surfaceColor,
      elevation: elevation_s,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius_l),
      ),
      shadowColor: Colors.black.withOpacity(0.1),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    ),
    dividerTheme: DividerThemeData(
      color: dividerColor,
      thickness: 1,
      space: 24,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: backgroundColor,
      disabledColor: dividerColor,
      selectedColor: primaryColor.withOpacity(0.2),
      secondarySelectedColor: primaryColor,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: GoogleFonts.inter(
        color: textColor,
        fontSize: 14,
      ),
      secondaryLabelStyle: GoogleFonts.inter(
        color: primaryColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius_l),
        side: BorderSide(color: dividerColor),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: surfaceColor,
      elevation: elevation_l,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius_l),
      ),
      titleTextStyle: GoogleFonts.inter(
        color: textColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: GoogleFonts.inter(
        color: textColor,
        fontSize: 16,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: textColor,
      contentTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius_m),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: elevation_m,
    ),
    tabBarTheme: TabBarTheme(
      labelColor: primaryColor,
      unselectedLabelColor: textLightColor,
      indicatorColor: primaryColor,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor;
        }
        return Colors.transparent;
      }),
      checkColor: MaterialStateProperty.all(Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius_xs),
      ),
      side: BorderSide(color: textLightColor, width: 1.5),
    ),
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor;
        }
        return textLightColor;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor;
        }
        return Colors.white;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor.withOpacity(0.5);
        }
        return Colors.grey.shade300;
      }),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primaryColor,
      circularTrackColor: primaryColor.withOpacity(0.2),
      linearTrackColor: primaryColor.withOpacity(0.2),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surfaceColor,
      elevation: elevation_l,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(radius_l),
          topRight: Radius.circular(radius_l),
        ),
      ),
    ),
  );
  
  // Thème sombre
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      error: errorColor,
      background: Color(0xFF121212),
      surface: Color(0xFF1E1E1E),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: Color(0xFF121212),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: elevation_xs,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      shadowColor: Colors.black.withOpacity(0.2),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
      elevation: elevation_m,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
    ),
    cardTheme: CardTheme(
      color: Color(0xFF1E1E1E),
      elevation: elevation_s,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius_l),
      ),
      shadowColor: Colors.black.withOpacity(0.3),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    ),
    // Autres thèmes pour le mode sombre...
  );
}