// CÓDIGO CORRIGIDO
import 'package:flutter/material.dart';
import 'package:find_it/service/auth_service.dart';
import 'package:find_it/screens/feed/feed_screen.dart';
import 'package:find_it/screens/create_post/create_post_screen.dart';
import 'package:find_it/screens/cadastro/Cadastro.dart';
import 'package:find_it/screens/login/Login.dart';
import 'package:find_it/screens/perfil/perfil.dart';
import 'package:find_it/screens/editarPerfil/editar_perfil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isLoggedIn = await AuthService.isLoggedIn();
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Achados e Perdidos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D8BC9),
        ),
      ),
      initialRoute: isLoggedIn ? '/' : '/login',
      routes: {
        '/': (context) => const FeedScreen(),
        '/create-post': (context) => const CreatePostScreen(),
        // A rota '/post-detail' foi removida daqui. A navegação agora é feita
        // diretamente pelo FeedScreen, o que é mais moderno e flexível.
        '/cadastro': (context) => const Cadastro(),
        '/login': (context) => const Login(),
        '/profile': (context) => const Perfil(),
        '/editar-perfil': (context) => const EditarPerfil(),
      },
    );
  }
}