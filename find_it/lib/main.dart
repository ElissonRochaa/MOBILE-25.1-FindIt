//import 'package:find_it/pages/editar_perfil.dart';
import 'package:find_it/pages/perfil.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const FindIt());
}

class FindIt extends StatelessWidget {
  const FindIt({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Editar perfil')),
        body: const Center(child: Perfil()),
      ),
    );
  }
}
