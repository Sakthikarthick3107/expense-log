


import 'dart:ffi';

import 'package:flutter/material.dart';

ThemeData appTheme = ThemeData(
  fontFamily: 'Poppins',

  colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.red,
      // primary: Colors.deepOrange,
      // secondary: Colors.deepOrange,
      background: Color(0xFFF0F8FF),


  ),
  appBarTheme: const AppBarTheme(

      backgroundColor: Colors.deepOrange
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.deepOrange,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5)
      )
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
        foregroundColor: Colors.black
    ),
  ),


  listTileTheme:const ListTileThemeData(
    titleTextStyle: TextStyle(
      fontSize: 20,
      color: Colors.black,
      fontFamily: 'Poppins'
    ),
    subtitleTextStyle: TextStyle(
      fontSize: 16,
      color: Colors.black,
      fontFamily: 'Poppins'
    ),
    tileColor: Colors.transparent
  ),

  useMaterial3: true,
);