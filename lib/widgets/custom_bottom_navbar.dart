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
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => onTap(0),
            color: currentIndex == 0 ? const Color(0xFF1D8BC9) : Colors.grey,
          ),
          const SizedBox(width: 40), // Espaço para o FAB
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => onTap(1),
            color: currentIndex == 1 ? const Color(0xFF1D8BC9) : Colors.grey,
          ),
        ],
      ),
    );
  }
}