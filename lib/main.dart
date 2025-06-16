import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:find_it/screens/splash/splash_screen.dart';
import 'package:find_it/screens/feed/feed_screen.dart';
import 'package:find_it/screens/create_post/create_post_screen.dart';
import 'package:find_it/screens/cadastro/Cadastro.dart';
import 'package:find_it/screens/login/Login.dart';
import 'package:find_it/screens/perfil/perfil.dart';
import 'package:find_it/screens/editarPerfil/editar_perfil.dart';
import 'package:find_it/screens/conversations/conversation_list_screen.dart';
// Corrigi o nome da pasta para 'recovery' conforme seus imports
import 'package:find_it/screens/recovery/RecuperarSenha.dart';
// Importe a tela de reset que criamos
import 'package:find_it/screens/recovery/reset_password_screen.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'package:find_it/service/theme_service.dart';
// 1. Importe o go_router
import 'package:go_router/go_router.dart';

// 2. Defina a configuração de rotas do GoRouter
// Todas as suas rotas antigas foram mapeadas aqui.
final GoRouter _router = GoRouter(
  initialLocation: '/', // A rota inicial agora é a Splash Screen
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/feed',
      builder: (context, state) => const FeedScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const Login(),
    ),
    GoRoute(
      path: '/cadastro',
      builder: (context, state) => const Cadastro(),
    ),
    GoRoute(
      path: '/create-post',
      builder: (context, state) => const CreatePostScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const Perfil(),
    ),
    GoRoute(
      path: '/editar-perfil',
      builder: (context, state) => const EditarPerfil(),
    ),
    GoRoute(
      path: '/conversations',
      builder: (context, state) => const ConversationListScreen(),
    ),
    GoRoute(
      path: '/recuperar-senha',
      builder: (context, state) => const RecuperarSenha(),
    ),
    // AQUI ESTÁ A NOVA ROTA PARA O DEEP LINK
    GoRoute(
      path: '/reset-password',
      builder: (BuildContext context, GoRouterState state) {
        // Extrai o token da URL (ex: /reset-password?token=12345)
        final token = state.uri.queryParameters['token'];

        if (token == null || token.isEmpty) {
          // Se o token for inválido, podemos mostrar uma tela de erro ou redirecionar
          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Link de redefinição de senha inválido ou expirado.'),
              ),
            ),
          );
        }
        // Se o token existir, abre a tela de reset.
        return ResetPasswordScreen(token: token);
      },
    ),
  ],
);


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sua lógica de window_manager permanece INTACTA
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

  // Seu Provider permanece INTACTO
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

    // 3. Mude de MaterialApp para MaterialApp.router
    return MaterialApp.router(
      // As configurações do seu tema são preservadas
      title: 'FindIt - Achados e Perdidos',
      debugShowCheckedModeBanner: false,
      theme: themeNotifier.lightTheme,
      darkTheme: themeNotifier.darkTheme,
      themeMode: themeNotifier.currentThemeMode,

      // Remova 'home' e 'routes' e adicione 'routerConfig'
      routerConfig: _router,
    );
  }
}