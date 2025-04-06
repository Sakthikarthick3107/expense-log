import 'dart:ffi';

import 'package:flutter/material.dart';

import '../utility/preset_colors.dart';

Color _parseHexColor(String hex) {
  hex = hex.replaceAll('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  return Color(int.parse(hex, radix: 16));
}

ThemeData appTheme(bool isDarkTheme , String appPrimary) {
  Color primaryColor = presetColors.firstWhere(
        (c) => c.name.toLowerCase() == appPrimary.toLowerCase(),
    orElse: () => presetColors[0], //
  ).color;
  return ThemeData(
    fontFamily: 'Poppins',
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        color: isDarkTheme ? Colors.white : Colors.black,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: isDarkTheme ? Colors.white70 : Colors.black87,
      ),
      displaySmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: isDarkTheme ? Colors.white60 : Colors.black54,
      ),
      headlineLarge: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: isDarkTheme ? Colors.white : Colors.black,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: isDarkTheme ? Colors.white70 : Colors.black87,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: isDarkTheme ? Colors.white60 : Colors.black54,
      ),
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: isDarkTheme ? Colors.white : Colors.black,
      ),
      titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: isDarkTheme ? Colors.white70 : Colors.black87,
      ),
      titleSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: isDarkTheme ? Colors.white60 : Colors.black54,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: isDarkTheme ? Colors.white : Colors.black,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: isDarkTheme ? Colors.white70 : Colors.black87,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: isDarkTheme ? Colors.white60 : Colors.black54,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDarkTheme ? Colors.white : Colors.black,
      ),
      labelMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: isDarkTheme ? Colors.white70 : Colors.black87,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: isDarkTheme ? Colors.white60 : Colors.black54,
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: const CircleBorder(),
      foregroundColor: Colors.white,
      backgroundColor: isDarkTheme? primaryColor.withOpacity(0.4) : primaryColor.withOpacity(0.8),
      sizeConstraints: BoxConstraints.tightFor(
        width: 50,
        height: 50,
      ),
    ),

    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      // secondary: Colors.deepOrange,
      surface: isDarkTheme ? Color(0xFF202124) :  Color(0xFFF0F8FF),
      background: isDarkTheme ? Color(0xFF202124) :  Color(0xFFF0F8FF),

    ),
    appBarTheme:  AppBarTheme(
      elevation: 10,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        backgroundColor: isDarkTheme ? Colors.black12 : Colors.white,
        titleTextStyle: TextStyle(
          color: isDarkTheme ? Colors.white : Colors.black,
          fontSize: 20
        ),
        iconTheme: IconThemeData(
          color: isDarkTheme ? Colors.white : Colors.black,
        )
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5)
          )
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
          foregroundColor:primaryColor
      ),
    ),


    listTileTheme:  ListTileThemeData(
        titleTextStyle: TextStyle(
            fontSize: 18,
            color: isDarkTheme ? Colors.white : Colors.black,
            fontFamily: 'Poppins'
        ),

        subtitleTextStyle: TextStyle(
            fontSize: 16,
            color: isDarkTheme ? Colors.white : Colors.black,
            fontFamily: 'Poppins'
        ),
        leadingAndTrailingTextStyle: TextStyle(
          fontSize: 18,
          color: isDarkTheme ? Colors.white : Colors.black
        ),
        tileColor: Colors.transparent,

    ),


    cardTheme: CardTheme(
      surfaceTintColor: isDarkTheme ?  Color(0xFF0000000) : Color(0xFFF0F8FF),
      color: isDarkTheme ?  Color(0xFF0000000) : Color(0xFFF0F8FF),
    ),

    drawerTheme: DrawerThemeData(
      backgroundColor: isDarkTheme ? Color(0xFF2F2F2F) : Colors.white
    ),
    iconTheme: IconThemeData(
      color: isDarkTheme ? Colors.white :Colors.black
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDarkTheme ? Colors.black12 :Colors.white,
      contentTextStyle: TextStyle(
        color: isDarkTheme ? Colors.white :Colors.black
      )
    ),

    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: TextStyle(
        color: Colors.white,
        fontSize: 16
      ),

    ),
    dialogTheme: DialogTheme(
      backgroundColor: isDarkTheme ? Color(0xFF333333) : Color(0xFFF0F8FF),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),

    datePickerTheme: DatePickerThemeData(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      rangePickerSurfaceTintColor: isDarkTheme ? Color(0xFF333333) : Color(0xFFF0F8FF),
      rangePickerHeaderBackgroundColor: isDarkTheme ? Color(0xFF333333) : Color(0xFFF0F8FF),
      headerHelpStyle:TextStyle(
        color: isDarkTheme ? Color(0xFFF0F8FF) : Color(0xFF333333)
      ) ,
      rangePickerHeaderHelpStyle: TextStyle(
          color: isDarkTheme ? Color(0xFFF0F8FF) : Color(0xFF333333)
      ) ,

      rangePickerHeaderForegroundColor: isDarkTheme ? Color(0xFFF0F8FF) : Color(0xFF333333),
      backgroundColor: isDarkTheme ? Color(0xFF333333) : Color(0xFFF0F8FF),
        headerForegroundColor: isDarkTheme ? Colors.white : Colors.black,
        headerHeadlineStyle: TextStyle(
          color: isDarkTheme ? Colors.white : Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),

      weekdayStyle: TextStyle(
        color: isDarkTheme ? Colors.white : Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),



      // Day style customization
      dayStyle: TextStyle(
        color: isDarkTheme ? Colors.white : Colors.black,
      ),
      dayForegroundColor: WidgetStateProperty.all(isDarkTheme ? Colors.white : Colors.black),
      dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor.withOpacity(0.5);
        }
        return Colors.transparent;
      }),
      // Today customization
      todayForegroundColor: WidgetStateProperty.all(Colors.white),
      todayBackgroundColor: WidgetStateProperty.all(primaryColor),
      todayBorder: BorderSide(
        color: primaryColor,
        width: 2.0,
      ),


      yearStyle: TextStyle(
        color: isDarkTheme ? Colors.white : Colors.black,
      ),
      yearForegroundColor: WidgetStateProperty.all(isDarkTheme ? Colors.white : Colors.black),


      rangePickerBackgroundColor: isDarkTheme ? Color(0xFF333333) : Color(0xFFF0F8FF),
      rangeSelectionBackgroundColor: primaryColor.withOpacity(0.5),
      rangeSelectionOverlayColor: WidgetStateProperty.all(Colors.red.withOpacity(0.3)),


      dividerColor: isDarkTheme ? Colors.white : Colors.black,


      cancelButtonStyle: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(Colors.red),
      ),
      confirmButtonStyle: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(primaryColor),
      ),
    ),


    useMaterial3: true,
  );
}