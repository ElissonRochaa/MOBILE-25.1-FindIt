import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 

class UserPostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final String? currentUserId;
  final Function(String postId) onDelete;
  final Function(String postId) onResolve;
  final String Function(String rawDate) formatDate; 

  const UserPostCard({
    Key? key,
    required this.post,
    required this.currentUserId,
    required this.onDelete,
    required this.onResolve,
    required this.formatDate, 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final itemName = post['nomeItem'] ?? '';
    final description = post['descricao'] ?? '';
    final date = formatDate(post['dataOcorrencia'] ?? ''); 
    final imageUrl = post['fotoUrl'] ?? '';
    final isFound = post['situacao'] == 'achado';
    final isResolved = post['situacao'] == 'resolvido';
    final String postId = post['_id'] ?? '';
    final String postAuthorId = post['autor']?['_id']?.toString() ?? '';
    final bool isCurrentUserPost = (currentUserId != null && postAuthorId == currentUserId);

    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final titleColor = theme.colorScheme.primary;
    final descriptionColor = theme.textTheme.bodyMedium?.color ?? (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87);
    final dateColor = theme.textTheme.bodySmall?.color ?? Colors.grey[600];
    final iconMoreColor = (theme.iconTheme.color ?? (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black54)).withOpacity(0.7);

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: theme.cardTheme.elevation ?? 2,
      color: cardColor,
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
                      errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 40)),)
                  : Center(child: Icon(Icons.photo_library_outlined, size: 50, color: Colors.grey[400])),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        itemName,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: titleColor)
                      )
                    ),
                    if (isCurrentUserPost)
                      SizedBox(
                        width: 40,
                        height: 30,
                        child: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: iconMoreColor, size: 22),
                          tooltip: "Opções",
                          onSelected: (value) {
                            if (value == 'resolver') {
                              onResolve(postId);
                            } else if (value == 'excluir') {
                              onDelete(postId);
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            if (!isResolved)
                              PopupMenuItem<String>(
                                value: 'resolver',
                                child: Row(children: [Icon(Icons.check_circle_outline, color: Colors.green.shade600), const SizedBox(width: 8), const Text('Resolvido')]),
                              ),
                            PopupMenuItem<String>(
                              value: 'excluir',
                              child: Row(children: [Icon(Icons.delete_outline, color: Colors.redAccent.shade100), const SizedBox(width: 8), const Text('Excluir')]),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusTagBackgroundColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isResolved
                             ? Colors.blueGrey.shade300.withOpacity(0.5)
                             : (isFound ? Colors.green.shade300.withOpacity(0.5) : Colors.orange.shade300.withOpacity(0.5))
                    )
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusTextColor, fontWeight: FontWeight.bold, fontSize: 11)
                  ),
                ),
                Text(description, style: TextStyle(fontSize: 14, color: descriptionColor, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Text('Data: $date', style: TextStyle(fontSize: 12, color: dateColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}