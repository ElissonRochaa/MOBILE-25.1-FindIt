// lib/widgets/post_filter_tabs.dart

import 'package:flutter/material.dart';

class PostFilterTabs extends StatelessWidget {
  final String selectedTab;
  final ValueChanged<String> onTabSelected;

  const PostFilterTabs({
    Key? key,
    required this.selectedTab,
    required this.onTabSelected,
  }) : super(key: key);

  // O botão gradiente é específico para este widget, então o definimos aqui.
  Widget _buildGradientButton({required VoidCallback onPressed, required String text, required BuildContext context}) {
    final ThemeData theme = Theme.of(context);
    final Color gradStart = theme.brightness == Brightness.light ? theme.primaryColor : theme.colorScheme.primary;
    final Color gradEnd = theme.brightness == Brightness.light ? Color.lerp(theme.primaryColor, Colors.black, 0.3)! : Color.lerp(theme.colorScheme.primary, Colors.black, 0.4)!;

    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [gradStart, gradEnd], begin: Alignment.centerLeft, end: Alignment.centerRight),
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            child: Text(text, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  Widget _buildInactiveButton({required VoidCallback onPressed, required String text, required BuildContext context}) {
    final theme = Theme.of(context);
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.cardColor.withOpacity(0.8),
          foregroundColor: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: theme.dividerColor.withOpacity(0.5))),
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 0.5,
        ),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          selectedTab == 'perdido'
              ? _buildGradientButton(onPressed: () => onTabSelected('perdido'), text: 'Perdidos', context: context)
              : _buildInactiveButton(onPressed: () => onTabSelected('perdido'), text: 'Perdidos', context: context),
          const SizedBox(width: 12),
          selectedTab == 'achado'
              ? _buildGradientButton(onPressed: () => onTabSelected('achado'), text: 'Achados', context: context)
              : _buildInactiveButton(onPressed: () => onTabSelected('achado'), text: 'Achados', context: context),
        ],
      ),
    );
  }
}