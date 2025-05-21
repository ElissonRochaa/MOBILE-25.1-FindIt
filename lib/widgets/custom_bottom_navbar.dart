import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Botão Home (Feed)
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => onTap(0),
            color: currentIndex == 0 ? const Color(0xFF1D8BC9) : Colors.grey,
          ),

          // Espaço para o FAB
          const SizedBox(width: 40),

          // Botão CreatePost
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => onTap(1),
            color: currentIndex == 1 ? const Color(0xFF1D8BC9) : Colors.grey,
          ),

          // Botão Perfil
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => onTap(2),
            color: currentIndex == 2 ? const Color(0xFF1D8BC9) : Colors.grey,
          ),
        ],
      ),
    );
  }
}
