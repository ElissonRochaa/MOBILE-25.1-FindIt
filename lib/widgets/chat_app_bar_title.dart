// lib/widgets/chat_app_bar_title.dart

import 'package:flutter/material.dart';

class ChatAppBarTitle extends StatelessWidget {
  final String recipientName;
  final String? recipientProfilePic;

  const ChatAppBarTitle({
    Key? key,
    required this.recipientName,
    this.recipientProfilePic,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: theme.cardColor.withAlpha(128),
          backgroundImage:
          recipientProfilePic != null && recipientProfilePic!.isNotEmpty
              ? NetworkImage(recipientProfilePic!)
              : null,
          child: recipientProfilePic == null || recipientProfilePic!.isEmpty
              ? Icon(Icons.person, size: 22, color: theme.iconTheme.color)
              : null,
        ),
        const SizedBox(width: 12),
        Text(
          recipientName,
          style: TextStyle(
            fontSize: 18,
            color: theme.textTheme.titleLarge?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}