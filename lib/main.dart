import 'package:flutter/material.dart';
import 'screens/feed/feed_screen.dart';
import 'screens/create_post/create_post_screen.dart';
import 'screens/post_detail/post_detail_screen.dart';

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
      // Remova a propriedade home e use apenas routes
      initialRoute: '/',
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
          );
        },
      },
    );
  }
}