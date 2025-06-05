// lib/main.dart

import 'dart:io'; // Necessário para verificar a plataforma
import 'package:flutter/foundation.dart'; // Para usar kIsWeb
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
import 'package:provider/provider.dart';
import 'package:find_it/service/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ativa window_manager apenas em plataformas desktop
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
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
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      title: 'FindIt - Achados e Perdidos',
      debugShowCheckedModeBanner: false,
      theme: themeNotifier.lightTheme,
      darkTheme: themeNotifier.darkTheme,
      themeMode: themeNotifier.currentThemeMode,
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
