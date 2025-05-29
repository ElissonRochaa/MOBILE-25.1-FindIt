import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    Key? key, // Correção: super.key para construtores de widgets
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Pega o tema atual do BottomNavigationBar
    final BottomNavigationBarThemeData bottomNavTheme = Theme.of(context).bottomNavigationBarTheme;

    return BottomNavigationBar(
      // Usa as cores e propriedades definidas no tema
      backgroundColor: bottomNavTheme.backgroundColor, 
      currentIndex: currentIndex,
      selectedItemColor: bottomNavTheme.selectedItemColor,
      unselectedItemColor: bottomNavTheme.unselectedItemColor, 
      type: bottomNavTheme.type ?? BottomNavigationBarType.fixed, // Usa o tipo do tema ou um padrão
      elevation: bottomNavTheme.elevation ?? 8.0, // Usa a elevação do tema ou um padrão
      onTap: onTap, 
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined), // Ícone de contorno para não selecionado
          activeIcon: Icon(Icons.home), // Ícone preenchido para selecionado
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