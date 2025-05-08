import 'package:flutter/material.dart';
import 'screens/create_post/create_post_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Achados e Perdidos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D8BC9),
        ),
      ),
      home: const HomeScreen(),
      routes: {
        '/create-post': (context) => const CreatePostScreen(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const Center(child: Text('Tela Inicial')),
    const SizedBox(), // Espaço vazio para o FAB
    const Center(child: Text('Perfil do Usuário')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achados e Perdidos'),
      ),
      body: _screens[_currentIndex],
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1D8BC9),
        onPressed: () {
          Navigator.pushNamed(context, '/create-post');
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () => setState(() => _currentIndex = 0),
            ),
            const SizedBox(width: 40),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => setState(() => _currentIndex = 2),
            ),
          ],
        ),
      ),
    );
  }
}