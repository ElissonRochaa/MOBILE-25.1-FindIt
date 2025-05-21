import 'package:flutter/material.dart';
import 'package:find_it/pages/Login.dart';

void main() {
  final ThemeData baseTheme = ThemeData();

  runApp(
    MaterialApp(
      home: Login(),
      theme: baseTheme.copyWith(
        primaryColor: const Color(0xff1D8BC9),
        scaffoldBackgroundColor: const Color(0xffffffff),
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: const Color(0xff1D8BC9),
          secondary: const Color(0xffffffff),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xff1D8BC9),
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xff1D8BC9)),
          ),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xff1D8BC9),
          selectionColor: Color(0xff1D8BC9),
          selectionHandleColor: Color(0xff1D8BC9),
        ),
      ),
      debugShowCheckedModeBanner: false,
    ),
  );
}
