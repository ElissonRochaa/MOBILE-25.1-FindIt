import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:find_it/service/auth_service.dart';
import 'package:find_it/screens/user_profile/user_profile_screen.dart';
import 'package:find_it/widgets/custom_bottom_navbar.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailScreen({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  List<dynamic> _comments = [];
  bool _isLoadingComments = true;
  bool _isPostingComment = false;
  String? _currentUserId;

  final int _bottomNavCurrentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _currentUserId = await AuthService.getUserId();
    if (!mounted) return;
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    if (!mounted) return;
    setState(() => _isLoadingComments = true);
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/v1/posts/${widget.post['_id']}/comments'),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        setState(() {
          _comments = jsonDecode(responseBody);
        });
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorData['message'] ?? 'Erro ao buscar comentários.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro de conexão ao buscar comentários: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingComments = false);
      }
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty || _isPostingComment) return;
    if (!mounted) return;
    setState(() => _isPostingComment = true);
    
    final token = await AuthService.getToken();
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Você precisa estar logado para comentar.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      setState(() => _isPostingComment = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/v1/posts/${widget.post['_id']}/comments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'texto': _commentController.text}),
      );
      if (!mounted) return;
      if (response.statusCode == 201) {
        _commentController.clear();
        _fetchComments();
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['message'] ?? 'Erro ao adicionar comentário.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro de conexão ao adicionar comentário: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPostingComment = false);
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final token = await AuthService.getToken();
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Você precisa estar logado para deletar.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text('Tem certeza que deseja excluir este comentário?'),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancelar',
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
              ),
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            TextButton(
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete != true) return;

    try {
      final response = await http.delete(
        Uri.parse('http://localhost:8080/api/v1/posts/${widget.post['_id']}/comments/$commentId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        _fetchComments();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Comentário excluído com sucesso!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['message'] ?? 'Erro ao deletar comentário.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro de conexão ao deletar comentário: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
  
  String _formatDate(String rawDate) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(rawDate));
    } catch (e) {
      return rawDate;
    }
  }

  void _onBottomNavTapped(int index) {
    final currentRouteName = ModalRoute.of(context)?.settings.name;

    if (index == 0) {
      Navigator.popUntil(context, ModalRoute.withName('/feed'));
    } else if (index == 1) {
      if (currentRouteName != '/create-post') {
        Navigator.pushNamed(context, '/create-post');
      }
    } else if (index == 2) {
      if (currentRouteName != '/profile') {
        Navigator.pushNamed(context, '/profile');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String itemName = widget.post['nomeItem'] ?? 'Item';
    final String description = widget.post['descricao'] ?? 'Sem descrição';
    final String userName = widget.post['autor']?['nome'] ?? 'Usuário';
    final String userProfilePic = widget.post['autor']?['profilePicture'] ?? '';
    final String authorId = widget.post['autor']?['_id']?.toString() ?? '';
    final String date = _formatDate(widget.post['dataOcorrencia'] ?? '');
    final bool isFound = widget.post['situacao'] == 'achado';
    final String imageUrl = widget.post['fotoUrl'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detalhes do Post',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 1,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.cardColor.withOpacity(0.5),
                        image: imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(imageUrl), 
                                fit: BoxFit.cover)
                            : null,
                      ),
                      child: imageUrl.isEmpty
                          ? Center(
                              child: Icon(
                                Icons.photo_outlined, 
                                size: 80, 
                                color: theme.iconTheme.color?.withOpacity(0.5),
                              ),
                            )
                          : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
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
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isFound ? Colors.green.shade600 : Colors.orange.shade600,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isFound ? 'Achado' : 'Perdido',
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () {
                            if (authorId.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserProfileScreen(userId: authorId),
                                ),
                              );
                            }
                          },
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: theme.cardColor.withAlpha((0.5 * 255).toInt()),
                                backgroundImage: userProfilePic.isNotEmpty 
                                    ? NetworkImage(userProfilePic) 
                                    : null,
                                child: userProfilePic.isEmpty 
                                    ? Icon(
                                        Icons.person, 
                                        size: 24, 
                                        color: theme.colorScheme.onSurface,
                                      ) 
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName, 
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, 
                                      fontSize: 16,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  Text(
                                    date, 
                                    style: TextStyle(
                                      color: theme.textTheme.bodySmall?.color,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 16, 
                            height: 1.5, 
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Comentários',
                          style: TextStyle(
                            fontSize: 20, 
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildCommentsSection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildCommentInputField(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _bottomNavCurrentIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }

  Widget _buildCommentsSection() {
    final theme = Theme.of(context);
    
    if (_isLoadingComments) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CircularProgressIndicator(color: theme.primaryColor),
        ),
      );
    }
    if (_comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Text(
            'Nenhum comentário ainda. Seja o primeiro!', 
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return _buildComment(comment: comment);
      },
    );
  }

  Widget _buildComment({required Map<String, dynamic> comment}) {
    final theme = Theme.of(context);
    final author = comment['autor'];
    final commentAuthorId = author?['_id']?.toString();
    final bool canDelete = (_currentUserId != null && 
                          (commentAuthorId == _currentUserId || 
                           widget.post['autor']?['_id']?.toString() == _currentUserId));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.hoverColor,
            backgroundImage: author?['profilePicture'] != null && author['profilePicture'].isNotEmpty
                ? NetworkImage(author['profilePicture'])
                : null,
            child: author?['profilePicture'] == null || author['profilePicture'].isEmpty
                ? Icon(
                    Icons.person, 
                    size: 20, 
                    color: theme.colorScheme.onSurface,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  author?['nome'] ?? 'Usuário', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  comment['texto'] ?? '', 
                  style: TextStyle(
                    height: 1.4, 
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          if (canDelete)
            SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.delete_outline, 
                  color: theme.iconTheme.color?.withOpacity(0.6), 
                  size: 20,
                ),
                onPressed: () => _deleteComment(comment['_id']),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildCommentInputField() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  )
                ],
              ),
              child: TextField(
                controller: _commentController,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                decoration: InputDecoration(
                  hintText: 'Adicione um comentário...',
                  hintStyle: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                minLines: 1,
                maxLines: 3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: _addComment,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle, 
                  color: theme.primaryColor,
                ),
                child: _isPostingComment 
                    ? SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(
                          strokeWidth: 2, 
                          color: theme.colorScheme.onPrimary,
                        ),
                      ) 
                    : Icon(
                        Icons.send, 
                        color: theme.colorScheme.onPrimary, 
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}