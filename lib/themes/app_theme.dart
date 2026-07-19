import 'package:flutter/material.dart';

import '../utility/preset_colors.dart';

ThemeData appTheme(bool isDarkTheme, String appPrimary) {
  Color primaryColor = presetColors
      .firstWhere(
        (c) => c.name.toLowerCase() == appPrimary.toLowerCase(),
        orElse: () => presetColors[0],
      )
      .color;

  final brightness = isDarkTheme ? Brightness.dark : Brightness.light;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: brightness,
    surface: isDarkTheme ? const Color(0xFF1A1A2E) : const Color(0xFFF8F9FA),
  );

  final surfaceColor = isDarkTheme ? const Color(0xFF16213E) : Colors.white;
  final cardColor = isDarkTheme ? const Color(0xFF1E2A4A) : Colors.white;
  final scaffoldBg = isDarkTheme ? const Color(0xFF0F0F23) : const Color(0xFFF2F3F7);

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: brightness,
    colorScheme: colorScheme.copyWith(
      surface: surfaceColor,
    ),
    scaffoldBackgroundColor: scaffoldBg,

    textTheme: TextTheme(
      displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withValues(alpha: 0.87)),
      displaySmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: colorScheme.onSurface.withValues(alpha: 0.60)),
      headlineLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
      headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withValues(alpha: 0.87)),
      headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: colorScheme.onSurface.withValues(alpha: 0.60)),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: colorScheme.onSurface.withValues(alpha: 0.87)),
      titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: colorScheme.onSurface.withValues(alpha: 0.60)),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: colorScheme.onSurface),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: colorScheme.onSurface.withValues(alpha: 0.87)),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: colorScheme.onSurface.withValues(alpha: 0.60)),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.onSurface.withValues(alpha: 0.87)),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colorScheme.onSurface.withValues(alpha: 0.60)),
    ),

    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      backgroundColor: surfaceColor,
      foregroundColor: colorScheme.onSurface,
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurface),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: const CircleBorder(),
      foregroundColor: Colors.white,
      backgroundColor: primaryColor.withValues(alpha: 0.85),
      elevation: 6,
      highlightElevation: 10,
      sizeConstraints: const BoxConstraints.tightFor(width: 56, height: 56),
    ),

    cardTheme: CardThemeData(
      elevation: isDarkTheme ? 2 : 1,
      shadowColor: primaryColor.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      color: cardColor,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        shadowColor: colorScheme.primary.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDarkTheme
          ? Colors.white.withValues(alpha: 0.06)
          : colorScheme.surface.withValues(alpha: 0.8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 1.5),
      ),
      hintStyle: TextStyle(
        fontSize: 14,
        color: colorScheme.onSurface.withValues(alpha: 0.38),
      ),
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      floatingLabelStyle: TextStyle(
        color: colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
      helperStyle: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5)),
      counterStyle: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5)),
    ),

    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 13,
        color: colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      leadingAndTrailingTextStyle: TextStyle(
        fontSize: 14,
        color: colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      tileColor: Colors.transparent,
      horizontalTitleGap: 12,
      minVerticalPadding: 8,
    ),

    drawerTheme: DrawerThemeData(
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
    ),

    iconTheme: IconThemeData(
      color: colorScheme.onSurface.withValues(alpha: 0.7),
      size: 24,
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: isDarkTheme ? const Color(0xFF2D2D44) : const Color(0xFF323232),
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      elevation: 6,
      width: 320,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: surfaceColor,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      contentTextStyle: TextStyle(
        fontSize: 15,
        color: colorScheme.onSurface.withValues(alpha: 0.8),
      ),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.12),
    ),

    dividerTheme: DividerThemeData(
      color: colorScheme.outline.withValues(alpha: 0.12),
      thickness: 0.5,
      space: 0,
    ),

    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      labelStyle: TextStyle(fontSize: 13, color: colorScheme.onSurface),
      secondaryLabelStyle: TextStyle(fontSize: 13, color: colorScheme.onSurface),
      selectedColor: colorScheme.primary.withValues(alpha: 0.15),
      checkmarkColor: colorScheme.primary,
      brightness: brightness,
    ),

    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: TextStyle(fontSize: 14, color: colorScheme.onSurface),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDarkTheme
            ? Colors.white.withValues(alpha: 0.06)
            : colorScheme.surface.withValues(alpha: 0.8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
    ),

    datePickerTheme: DatePickerThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      headerBackgroundColor: colorScheme.primary,
      headerForegroundColor: colorScheme.onPrimary,
      headerHeadlineStyle: TextStyle(
        color: colorScheme.onPrimary,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      headerHelpStyle: TextStyle(color: colorScheme.onPrimary.withValues(alpha: 0.8)),
      backgroundColor: surfaceColor,
      surfaceTintColor: Colors.transparent,
      dayStyle: TextStyle(color: colorScheme.onSurface),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colorScheme.onPrimary;
        return colorScheme.onSurface;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colorScheme.primary;
        return Colors.transparent;
      }),
      todayForegroundColor: WidgetStateProperty.all(colorScheme.primary),
      todayBackgroundColor: WidgetStateProperty.all(colorScheme.primary.withValues(alpha: 0.12)),
      todayBorder: BorderSide(color: colorScheme.primary, width: 1.5),
      yearStyle: TextStyle(color: colorScheme.onSurface),
      yearForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colorScheme.onPrimary;
        return colorScheme.onSurface;
      }),
      weekdayStyle: TextStyle(
        color: colorScheme.onSurface.withValues(alpha: 0.6),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      rangePickerBackgroundColor: surfaceColor,
      rangePickerSurfaceTintColor: Colors.transparent,
      rangePickerHeaderBackgroundColor: colorScheme.primary,
      rangePickerHeaderForegroundColor: colorScheme.onPrimary,
      rangePickerHeaderHelpStyle: TextStyle(color: colorScheme.onPrimary.withValues(alpha: 0.8)),
      rangeSelectionBackgroundColor: colorScheme.primary.withValues(alpha: 0.2),
      rangeSelectionOverlayColor: WidgetStateProperty.all(colorScheme.primary.withValues(alpha: 0.08)),
      dividerColor: colorScheme.outline.withValues(alpha: 0.12),
      cancelButtonStyle: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(colorScheme.error),
        textStyle: WidgetStateProperty.all(const TextStyle(fontWeight: FontWeight.w600)),
      ),
      confirmButtonStyle: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(colorScheme.primary),
        textStyle: WidgetStateProperty.all(const TextStyle(fontWeight: FontWeight.w600)),
      ),
    ),

    timePickerTheme: TimePickerThemeData(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      hourMinuteColor: colorScheme.surface,
      hourMinuteTextColor: colorScheme.onSurface,
      dialHandColor: colorScheme.primary,
      dialBackgroundColor: colorScheme.surface,
      dialTextColor: colorScheme.onSurface,
      entryModeIconColor: colorScheme.primary,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colorScheme.primary;
        return colorScheme.onSurface.withValues(alpha: 0.5);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colorScheme.primary.withValues(alpha: 0.4);
        return colorScheme.onSurface.withValues(alpha: 0.15);
      }),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colorScheme.primary;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      side: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.5)),
    ),

    popupMenuTheme: PopupMenuThemeData(
      color: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.12),
    ),

    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
      linearTrackColor: colorScheme.primary.withValues(alpha: 0.12),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surfaceColor,
      indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.primary);
        }
        return TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6));
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: colorScheme.primary, size: 24);
        }
        return IconThemeData(color: colorScheme.onSurface.withValues(alpha: 0.6), size: 22);
      }),
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: colorScheme.primary,
      inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.2),
      thumbColor: colorScheme.primary,
      overlayColor: colorScheme.primary.withValues(alpha: 0.12),
      valueIndicatorColor: colorScheme.primary,
      valueIndicatorTextStyle: TextStyle(color: colorScheme.onPrimary),
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: colorScheme.primary,
      unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.5),
      indicatorColor: colorScheme.primary,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: isDarkTheme ? const Color(0xFF2D2D44) : const Color(0xFF323232),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 13),
    ),
  );
}
