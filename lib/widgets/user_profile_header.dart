import 'package:flutter/material.dart';

class UserProfileHeader extends StatelessWidget {
  final String nome;
  final String curso;
  final String contato;
  final String profilePictureUrl;
  final VoidCallback onEditPressed;

  const UserProfileHeader({
    Key? key,
    required this.nome,
    required this.curso,
    required this.contato,
    required this.profilePictureUrl,
    required this.onEditPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color primaryColor = theme.primaryColor;
    final Color? textSecondaryColor = theme.textTheme.bodyMedium?.color;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.hoverColor,
            backgroundImage: profilePictureUrl.isNotEmpty ? NetworkImage(profilePictureUrl) : null,
            child: profilePictureUrl.isEmpty ? Icon(Icons.person, size: 45, color: textSecondaryColor?.withOpacity(0.7)) : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                ),
                const SizedBox(height: 6),
                Text(
                  curso,
                  style: TextStyle(fontSize: 15, color: textSecondaryColor),
                ),
                const SizedBox(height: 4),
                Text(
                  contato,
                  style: TextStyle(fontSize: 15, color: textSecondaryColor),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: primaryColor),
            onPressed: onEditPressed,
            tooltip: 'Editar Perfil',
          ),
        ],
      ),
    );
  }
}