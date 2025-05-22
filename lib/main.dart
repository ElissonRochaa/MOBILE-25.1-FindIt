import 'package:flutter/material.dart';
import 'package:find_it/service/auth_service.dart';
import 'package:find_it/screens/feed/feed_screen.dart';
import 'package:find_it/screens/create_post/create_post_screen.dart';
import 'package:find_it/screens/post_detail/post_detail_screen.dart';
import 'package:find_it/screens/cadastro/Cadastro.dart';
import 'package:find_it/screens/login/Login.dart';
import 'package:find_it/screens/perfil/perfil.dart';
import 'package:find_it/screens/editarPerfil/editar_perfil.dart'; // Novo import

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
        '/post-detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return PostDetailScreen(
            itemName: args['itemName'],
            description: args['description'],
            userName: args['userName'],
            date: args['date'],
            isFound: args['isFound'],
            imageUrl: args['imageUrl'] ?? '',
          );
        },
        '/cadastro': (context) => const Cadastro(),
        '/login': (context) => const Login(),
        '/profile': (context) => const Perfil(),
        '/editar-perfil': (context) => const EditarPerfil(), // Nova rota adicionada
      },
    );
  }
}