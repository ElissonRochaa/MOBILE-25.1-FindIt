// lib/widgets/post_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PostCard extends StatelessWidget {
  final Map<String, dynamic> post;

  const PostCard({
    Key? key,
    required this.post,
  }) : super(key: key);

  String _formatDate(String rawDate) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(rawDate));
    } catch (e) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemName = post['nomeItem'] ?? '';
    final description = post['descricao'] ?? '';
    final date = _formatDate(post['dataOcorrencia'] ?? '');
    final imageUrl = post['fotoUrl'] ?? '';
    final isFound = post['situacao'] == 'achado';
    final isResolved = post['situacao'] == 'resolvido';

    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final titleColor = theme.colorScheme.primary;
    final descriptionColor = theme.textTheme.bodyMedium?.color ?? (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87);
    final dateColor = theme.textTheme.bodySmall?.color ?? Colors.grey[600];

    String statusText;
    Color statusTagBackgroundColor;
    Color statusTextColor;

    if (isResolved) {
      statusText = 'RESOLVIDO';
      statusTagBackgroundColor = Colors.blueGrey.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.1);
      statusTextColor = theme.brightness == Brightness.dark ? Colors.blueGrey.shade200 : Colors.blueGrey.shade700;
    } else if (isFound) {
      statusText = 'ACHADO';
      statusTagBackgroundColor = Colors.green.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.1);
      statusTextColor = theme.brightness == Brightness.dark ? Colors.green.shade300 : Colors.green.shade800;
    } else {
      statusText = 'PERDIDO';
      statusTagBackgroundColor = Colors.orange.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.1);
      statusTextColor = theme.brightness == Brightness.dark ? Colors.orange.shade300 : Colors.orange.shade900;
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: theme.cardTheme.elevation ?? 2,
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: theme.hoverColor,
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover,
                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                      color: theme.primaryColor,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 40)),)
                  : Center(child: Icon(Icons.photo_library_outlined, size: 50, color: Colors.grey[400])),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(itemName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor)),
                Container(
                  margin: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusTagBackgroundColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isResolved
                          ? Colors.blueGrey.shade300.withAlpha((0.5 * 255).toInt())
                          : (isFound
                          ? Colors.green.shade300.withAlpha((0.5 * 255).toInt())
                          : Colors.orange.shade300.withAlpha((0.5 * 255).toInt())),
                    ),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusTextColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: descriptionColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text('Data: $date', style: TextStyle(fontSize: 12, color: dateColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}