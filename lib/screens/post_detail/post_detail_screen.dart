import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:find_it/service/auth_service.dart';
import 'package:find_it/screens/user_profile/user_profile_screen.dart';
// NOVO IMPORT: Importa o seu widget customizado
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

  // Define o índice para a BottomNavBar.
  // Para esta tela, podemos usar 0 (Feed) como referência.
  final int _bottomNavCurrentIndex = 0; 

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _currentUserId = await AuthService.getUserId();
    if (!mounted) return; // Checa se o widget ainda está na árvore
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['message'] ?? 'Erro ao buscar comentários.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão ao buscar comentários.'), backgroundColor: Colors.red),
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
        const SnackBar(content: Text('Você precisa estar logado para comentar.'), backgroundColor: Colors.red),
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
          SnackBar(content: Text(errorData['message'] ?? 'Erro ao adicionar comentário.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão ao adicionar comentário.'), backgroundColor: Colors.red),
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
        const SnackBar(content: Text('Você precisa estar logado para deletar.'), backgroundColor: Colors.red),
      );
      return;
    }
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:8080/api/v1/posts/${widget.post['_id']}/comments/$commentId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        _fetchComments();
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['message'] ?? 'Erro ao deletar comentário.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão ao deletar comentário.'), backgroundColor: Colors.red),
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

  // NOVA FUNÇÃO: Lógica de navegação para a BottomNavBar
  void _onBottomNavTapped(int index) {
    final currentRouteName = ModalRoute.of(context)?.settings.name;

    if (index == 0) { // Feed
      // Para voltar ao Feed a partir de uma tela interna, popUntil é bom.
      Navigator.popUntil(context, ModalRoute.withName('/'));
    } else if (index == 1) { // Novo Post
      Navigator.pushNamed(context, '/create-post');
    } else if (index == 2) { // Perfil
      // Se já estiver no perfil do usuário logado, não faz nada,
      // caso contrário, navega.
      // Este é o perfil do usuário LOGADO, então usamos /profile
      if (currentRouteName != '/profile') {
         Navigator.pushNamed(context, '/profile');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Detalhes do Post', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
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
                        color: Colors.grey[300],
                        image: imageUrl.isNotEmpty
                            ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                            : null,
                      ),
                      child: imageUrl.isEmpty
                          ? const Center(child: Icon(Icons.photo, size: 80, color: Colors.white))
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
                              child: Text(itemName,
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1D8BC9))),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isFound ? const Color(0xFF15AF12) : const Color(0xFFFF9900),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isFound ? 'Achado' : 'Perdido',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                                backgroundColor: Colors.grey[400],
                                backgroundImage: userProfilePic.isNotEmpty ? NetworkImage(userProfilePic) : null,
                                child: userProfilePic.isEmpty ? const Icon(Icons.person, size: 24, color: Colors.white) : null,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(date, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(description, style: const TextStyle(fontSize: 16, height: 1.5)),
                        const SizedBox(height: 32),
                        const Text('Comentários', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
      // ADICIONADO: CustomBottomNavBar
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _bottomNavCurrentIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }

  Widget _buildCommentsSection() {
    if (_isLoadingComments) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_comments.isEmpty) {
      return const Center(child: Text('Nenhum comentário ainda. Seja o primeiro!'));
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
    final author = comment['autor'];
    final commentAuthorId = author?['_id']?.toString();
    final postAuthorId = widget.post['autor']?['_id']?.toString();
    final bool canDelete = (_currentUserId != null && (_currentUserId == commentAuthorId || _currentUserId == postAuthorId));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[300],
            backgroundImage: author?['profilePicture'] != null && author['profilePicture'].isNotEmpty
                ? NetworkImage(author['profilePicture'])
                : null,
            child: author?['profilePicture'] == null || author['profilePicture'].isEmpty
                ? const Icon(Icons.person, size: 20, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(author?['nome'] ?? 'Usuário', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(comment['texto'] ?? '', style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: () => _deleteComment(comment['_id']),
            )
        ],
      ),
    );
  }

  Widget _buildCommentInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(24)),
              child: TextField(
                controller: _commentController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Adicione um comentário...', border: InputBorder.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1D8BC9)),
            child: IconButton(
              icon: _isPostingComment 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _addComment,
            ),
          ),
        ],
      ),
    );
  }
}