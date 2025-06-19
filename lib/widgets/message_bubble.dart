import 'package:find_it/service/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final Color recipientBubbleColor = theme.cardColor;
    final Color recipientTextColor =
        theme.textTheme.bodyMedium?.color ?? Colors.black87;
    final Color myTextColor = theme.colorScheme.onPrimary;

    final borderRadius = isMe
        ? const BorderRadius.only(
      topLeft: Radius.circular(18),
      bottomLeft: Radius.circular(18),
      bottomRight: Radius.circular(4),
      topRight: Radius.circular(18),
    )
        : const BorderRadius.only(
      topLeft: Radius.circular(4),
      topRight: Radius.circular(18),
      bottomLeft: Radius.circular(18),
      bottomRight: Radius.circular(18),
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding:
            const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: isMe
                ? BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor,
                  // Assumindo que ThemeNotifier está disponível em algum lugar ou a cor é definida estaticamente
                  theme.brightness == Brightness.light
                      ? const Color(0xff0a4a7a) // Exemplo de cor escura
                      : theme.colorScheme.primaryContainer,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                )
              ],
            )
                : BoxDecoration(
              color: recipientBubbleColor,
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                )
              ],
            ),
            child: Text(
              message['content'] ?? '',
              style: TextStyle(
                color: isMe ? myTextColor : recipientTextColor,
                fontSize: 15.5,
                height: 1.3,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 10.0, right: 10.0),
            child: Text(
              DateFormat('HH:mm').format(DateTime.parse(
                  message['createdAt'] ?? DateTime.now().toIso8601String())
                  .toLocal()),
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 11,
              ),
            ),
          )
        ],
      ),
    );
  }
}