// lib/widgets/user_profile_header.dart

import 'package:flutter/material.dart';

class UserProfileHeader extends StatelessWidget {
  final String profilePictureUrl;
  final String nome;
  final String curso;
  final bool isMyProfile;
  final VoidCallback onChatPressed;

  const UserProfileHeader({
    Key? key,
    required this.profilePictureUrl,
    required this.nome,
    required this.curso,
    required this.isMyProfile,
    required this.onChatPressed,
  }) : super(key: key);

  // Reutilizamos seu widget de botão gradiente aqui dentro
  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required Widget child,
    double borderRadius = 20.0,
    required BuildContext context,
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
    final textSecondaryColor = theme.textTheme.bodyMedium?.color;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          color: theme.cardColor,
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: theme.hoverColor,
                backgroundImage: profilePictureUrl.isNotEmpty ? NetworkImage(profilePictureUrl) : null,
                child: profilePictureUrl.isEmpty
                    ? Icon(Icons.person, size: 45, color: textSecondaryColor?.withOpacity(0.7))
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nome, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                    const SizedBox(height: 4),
                    Text(curso, style: TextStyle(fontSize: 14, color: textSecondaryColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isMyProfile)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: _buildGradientButton(
              onPressed: onChatPressed,
              borderRadius: 12,
              context: context,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Conversar', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}