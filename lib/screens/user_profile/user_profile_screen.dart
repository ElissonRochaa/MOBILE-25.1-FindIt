import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:find_it/service/auth_service.dart';
import 'package:find_it/screens/chat/chat_screen.dart';
// NOVO IMPORT: Importa o seu widget customizado
import 'package:find_it/widgets/custom_bottom_navbar.dart'; 

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String nome = 'Carregando...';
  String curso = 'Carregando...';
  // String contato = 'Carregando...'; // Mantido comentado conforme seu código
  String profilePictureUrl = '';
  List<dynamic> _userPosts = [];
  String _selectedTab = 'perdido';
  bool _isLoading = true;
  String? _errorMessage;
  String? _loggedInUserId;

  // Define o índice para a BottomNavBar.
  // Como esta tela é de "visita", usamos o Feed (0) como referência.
  final int _bottomNavCurrentIndex = 0; 

  @override
  void initState() {
    super.initState();
    _loadInitialDataAndLoggedInUserId();
  }

  Future<void> _loadInitialDataAndLoggedInUserId() async {
    _loggedInUserId = await AuthService.getUserId();
    _carregarDadosDaPagina();
  }

  Future<void> _carregarDadosDaPagina() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _fetchUserData(widget.userId);
      await _fetchUserPosts(widget.userId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchUserData(String userIdToFetch) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Usuário não autenticado');

    final response = await http.get(
      Uri.parse('http://localhost:8080/api/v1/users/$userIdToFetch'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (!mounted) return;
    if (response.statusCode == 200) {
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      setState(() {
        nome = responseData['nome'] ?? 'Nome não informado';
        curso = responseData['curso'] ?? 'Curso não informado';
        // contato = responseData['telefone'] ?? 'Contato não informado';
        profilePictureUrl = responseData['profilePicture'] ?? '';
      });
    } else {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['message'] ?? 'Erro ao carregar dados do usuário');
    }
  }

  Future<void> _fetchUserPosts(String userIdToFetch) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Usuário não autenticado');

    final response = await http.get(
      Uri.parse('http://localhost:8080/api/v1/posts/user/$userIdToFetch'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (!mounted) return;
    if (response.statusCode == 200) {
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      setState(() {
        _userPosts = responseData;
      });
    } else {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['message'] ?? 'Erro ao carregar os posts do usuário');
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
    // Não precisamos de setState aqui para _bottomNavCurrentIndex,
    // pois esta tela não é um dos itens principais da barra.
    // A navegação simplesmente leva para outras seções.

    if (index == 0) { // Feed
      // Para voltar ao Feed a partir de uma tela interna como esta,
      // popUntil é uma boa forma de limpar a pilha até a rota raiz.
      Navigator.popUntil(context, ModalRoute.withName('/'));
    } else if (index == 1) { // Novo Post
      Navigator.pushNamed(context, '/create-post');
    } else if (index == 2) { // Perfil (do usuário logado)
      // Se o perfil visitado for o do próprio usuário logado, não faz nada.
      // Caso contrário, navega para o perfil do usuário logado.
      if (widget.userId != _loggedInUserId) {
         Navigator.pushNamed(context, '/profile');
      } else {
        // Se já está no perfil do usuário logado (este cenário não deveria acontecer
        // se esta é UserProfileScreen para outros), mas por segurança:
        Navigator.popUntil(context, ModalRoute.withName('/profile',));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedPosts = _userPosts.where((post) {
      if (post['situacao'] == 'resolvido') return false;
      return post['situacao'] == _selectedTab;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(nome == 'Carregando...' ? 'Perfil do Usuário' : nome, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Erro: $_errorMessage', textAlign: TextAlign.center)))
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.white,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: profilePictureUrl.isNotEmpty ? NetworkImage(profilePictureUrl) : null,
                            child: profilePictureUrl.isEmpty ? Icon(Icons.person, size: 40, color: Colors.grey[400]) : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1D8BC9))),
                                const SizedBox(height: 4),
                                Text(curso, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_loggedInUserId != null && widget.userId != _loggedInUserId)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Conversar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D8BC9),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  recipientId: widget.userId,
                                  recipientName: nome, 
                                  recipientProfilePic: profilePictureUrl,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      color: Colors.white,
                      child: Row(
                        children: [
                          _buildFilterButton('Perdidos', 'perdido'),
                          const SizedBox(width: 12),
                          _buildFilterButton('Achados', 'achado'),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFEFEFEF)),
                    Expanded(
                      child: displayedPosts.isEmpty
                          ? Center(child: Text('Nenhum item $_selectedTab para mostrar.'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: displayedPosts.length,
                              itemBuilder: (context, index) {
                                final post = displayedPosts[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildReadOnlyPostCard(post: post),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      // ADICIONADO: CustomBottomNavBar
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _bottomNavCurrentIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }

  Widget _buildFilterButton(String text, String status) {
    final bool isActive = _selectedTab == status;
    return Expanded(
      child: ElevatedButton(
        onPressed: () => setState(() => _selectedTab = status),
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? const Color(0xFF1D8BC9) : Colors.grey[200],
          foregroundColor: isActive ? Colors.white : Colors.grey[700],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: isActive ? 2 : 0,
        ),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildReadOnlyPostCard({required Map<String, dynamic> post}) {
    final itemName = post['nomeItem'] ?? '';
    final description = post['descricao'] ?? '';
    final date = _formatDate(post['dataOcorrencia'] ?? '');
    final imageUrl = post['fotoUrl'] ?? '';
    final isFound = post['situacao'] == 'achado';
    final isResolved = post['situacao'] == 'resolvido';

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.grey[200],
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image)),)
                  : const Center(child: Icon(Icons.photo, size: 50, color: Colors.grey)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(itemName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1D8BC9))),
                 if (isResolved)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                      child: Text('RESOLVIDO', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                  else
                    Container(
                      margin: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isFound ? const Color(0xFF15AF12) : const Color(0xFFFF9900),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isFound ? 'Achado' : 'Perdido',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                const SizedBox(height: 8),
                Text(description, style: const TextStyle(fontSize: 14, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text('Data: $date', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}