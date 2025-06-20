import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final BottomNavigationBarThemeData bottomNavTheme = Theme.of(context).bottomNavigationBarTheme;

    return BottomNavigationBar(
      backgroundColor: bottomNavTheme.backgroundColor, 
      currentIndex: currentIndex,
      selectedItemColor: bottomNavTheme.selectedItemColor,
      unselectedItemColor: bottomNavTheme.unselectedItemColor, 
      type: bottomNavTheme.type ?? BottomNavigationBarType.fixed, 
      elevation: bottomNavTheme.elevation ?? 8.0, 
      onTap: onTap, 
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined), 
          activeIcon: Icon(Icons.home), 
          label: 'Feed',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          activeIcon: Icon(Icons.add_circle),
          label: 'Novo Post',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}