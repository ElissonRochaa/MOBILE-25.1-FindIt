import 'package:find_it/pages/CreatePost.dart';
import 'package:find_it/pages/Feed.dart';
import 'package:find_it/pages/Perfil.dart';
import 'package:find_it/pages/PostDetail.dart';
import 'package:flutter/material.dart';
import 'package:find_it/pages/Login.dart';

void main() {
  final ThemeData baseTheme = ThemeData();

  runApp(
    MaterialApp(
      title: 'Achados e Perdidos',
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
      initialRoute: '/login', //
      routes: {
        '/': (context) => const Feed(),
        '/login': (context) => const Login(),
        '/create-post': (context) => const CreatePost(),
        '/perfil': (context) => const Perfil(),
        '/post-detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return PostDetail(
            itemName: args['itemName'],
            description: args['description'],
            userName: args['userName'],
            date: args['date'],
            isFound: args['isFound'],
          );
        },
      },
    ),
  );
}
