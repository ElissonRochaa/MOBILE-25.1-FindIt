import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:find_it/service/auth_service.dart';
import 'package:find_it/widgets/custom_bottom_navbar.dart';
import 'package:find_it/screens/post_detail/post_detail_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  int _currentIndex = 0;
  List<dynamic> _posts = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/v1/posts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _posts = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erro ao carregar posts: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro de conexão: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String rawDate) {
    try {
      final date = DateTime.parse(rawDate);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return rawDate;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Feed',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1D8BC9),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1D8BC9),
          tabs: const [
            Tab(text: 'Feed'),
            Tab(text: 'Notificações'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  hintText: 'Pesquisar',
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) {
                  // Opcional: implementar filtro local aqui
                },
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFeedContent(),
                const Center(
                  child: Text('Nenhuma notificação no momento'),
                ),
              ],
            ),
          ),
        ],
      ),
   bottomNavigationBar: BottomNavigationBar(
  currentIndex: _currentIndex,
  selectedItemColor: const Color(0xFF1D8BC9),
  onTap: (index) {
    setState(() => _currentIndex = index);
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/create-post');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/profile');
    }
  },
  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Feed',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.add_circle_outline),
      label: 'Novo Post',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      label: 'Perfil',
    ),
  ],
),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchPosts,
        backgroundColor: const Color(0xFF1D8BC9),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

 Widget _buildFeedContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    }

    if (_posts.isEmpty) {
      return const Center(child: Text('Nenhum post encontrado'));
    }

    return RefreshIndicator(
      onRefresh: _fetchPosts,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: _posts.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final post = _posts[index];
          final isFound = post['situacao'] == 'ACHADO';
          final imageUrl = post['fotoUrl'] != null ? 'http://localhost:8080${post['fotoUrl']}' : '';

          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/post-detail',
                arguments: {
                  'itemName': post['nomeItem'] ?? '',
                  'description': post['descricao'] ?? '',
                  'userName': post['usuario']?['nome'] ?? 'Usuário',
                  'date': _formatDate(post['data'] ?? ''),
                  'isFound': isFound,
                  'imageUrl': imageUrl,
                },
              );
            },
            child: _buildPostCard(
              isFound: isFound,
              post: post,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostCard({required bool isFound, required dynamic post}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagem em destaque
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 180,
              color: Colors.grey[300],
              child: post['fotoUrl'] != null
                  ? Image.network(
                      'http://localhost:8080${post['fotoUrl']}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                          const Center(child: Icon(Icons.photo, size: 50, color: Colors.white)),
                    )
                  : const Center(child: Icon(Icons.photo, size: 50, color: Colors.white)),
            ),
          ),

          // Conteúdo do post
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho (título + status)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        post['nomeItem'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D8BC9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isFound ? const Color(0xFF15AF12) : const Color(0xFFFF9900),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isFound ? 'Achado' : 'Perdido',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Descrição
                Text(
                  post['descricao'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),

                // Rodapé (autor + data)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Por: ${post['usuario']?['nome'] ?? 'Usuário'}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _formatDate(post['data']),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
