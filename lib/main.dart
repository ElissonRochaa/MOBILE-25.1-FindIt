import 'package:flutter/material.dart';
import 'package:find_it/screens/splash/splash_screen.dart';
import 'package:find_it/screens/feed/feed_screen.dart';
import 'package:find_it/screens/create_post/create_post_screen.dart';
import 'package:find_it/screens/cadastro/Cadastro.dart';
import 'package:find_it/screens/login/Login.dart';
import 'package:find_it/screens/perfil/perfil.dart';
import 'package:find_it/screens/editarPerfil/editar_perfil.dart';
import 'package:find_it/screens/conversations/conversation_list_screen.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(420, 825), 
    center: true, 
    backgroundColor: Colors.transparent, 
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal, 
    title: 'FindIt - Achados e Perdidos', 
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FindIt - Achados e Perdidos', 
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D8BC9),
          primary: const Color(0xFF1D8BC9),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1D8BC9),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/feed': (context) => const FeedScreen(),
        '/login': (context) => const Login(),
        '/cadastro': (context) => const Cadastro(),
        '/create-post': (context) => const CreatePostScreen(),
        '/profile': (context) => const Perfil(),
        '/editar-perfil': (context) => const EditarPerfil(),
        '/conversations': (context) => const ConversationListScreen(),
      },
    );
  }
}