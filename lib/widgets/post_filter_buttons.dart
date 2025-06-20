import 'package:flutter/material.dart';

class PostFilterButtons extends StatelessWidget {
  final String selectedTab;
  final ValueChanged<String> onTabSelected;

  const PostFilterButtons({
    Key? key,
    required this.selectedTab,
    required this.onTabSelected,
  }) : super(key: key);

  Widget _buildGradientButton({
    required BuildContext context,
    required VoidCallback? onPressed,
    required Widget child,
    double borderRadius = 20.0,
  }) {
    final ThemeData theme = Theme.of(context);

    final Color gradStart = theme.brightness == Brightness.light
        ? theme.primaryColor
        : theme.colorScheme.primary; 
    final Color gradEnd = theme.brightness == Brightness.light
        ? Color.lerp(theme.primaryColor, Colors.black, 0.3)!
        : Color.lerp(theme.colorScheme.primary, Colors.black, 0.4)!; 

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gradStart, gradEnd],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget buildButton(String text, String status) {
      final bool isActive = selectedTab == status;
      if (isActive) {
        return Expanded(
          child: _buildGradientButton(
            context: context,
            onPressed: () => onTabSelected(status),
            borderRadius: 25.0,
            child: Text(text, style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        );
      } else {
        return Expanded(
          child: ElevatedButton(
            onPressed: () => onTabSelected(status),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.cardColor.withOpacity(0.8),
              foregroundColor: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: BorderSide(color: theme.dividerColor.withOpacity(0.5))
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0.5,
            ),
            child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          buildButton('Perdidos', 'perdido'),
          const SizedBox(width: 12),
          buildButton('Achados', 'achado'),
          const SizedBox(width: 12),
          buildButton('Resolvidos', 'resolvido'),
        ],
      ),
    );
  }
}