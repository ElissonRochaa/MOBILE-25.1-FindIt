import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:find_it/screens/post_detail/post_detail_screen.dart';
import 'package:find_it/screens/conversations/conversation_list_screen.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:find_it/service/auth_service.dart';
// NOVO IMPORT: Importa o seu widget customizado
import 'package:find_it/widgets/custom_bottom_navbar.dart'; 

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  int _bottomNavCurrentIndex = 0; // Este estado controla o item ativo da BottomNavBar

  List<dynamic> _allPosts = [];
  List<dynamic> _filteredPosts = [];
  bool _isLoadingPosts = true;
  String _postsErrorMessage = '';
  List<dynamic> _notifications = [];
  int _newNotificationCount = 0;
  IO.Socket? _socket;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchPosts();
    _initSocketConnection();

    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (_tabController.indexIsChanging) {
        if (_tabController.index == 1) {
          if (_newNotificationCount > 0) {
            if (mounted) {
              setState(() {
                _newNotificationCount = 0;
              });
            }
          }
        }
      }
    });
    _searchController.addListener(_filterPosts);
  }

  void _filterPosts() {
    final query = _searchController.text.toLowerCase();
    if (mounted) {
      setState(() {
        if (query.isEmpty) {
          _filteredPosts = List.from(_allPosts);
        } else {
          _filteredPosts = _allPosts.where((post) {
            final itemName = post['nomeItem']?.toString().toLowerCase() ?? '';
            return itemName.contains(query);
          }).toList();
        }
      });
    }
  }

  Future<void> _initSocketConnection() async {
    final token = await AuthService.getToken();
    if (token == null) {
      print("FeedScreen Socket: Token não encontrado.");
      return;
    }
    try {
      _socket = IO.io('http://localhost:8080', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': {'token': token}
      });
      _socket!.connect();
      _socket!.onConnect((_) { print('FeedScreen: Conectado ao Socket.IO Server'); });
      _socket!.on('newPostNotification', (data) {
        if (mounted) {
          setState(() {
            _notifications.insert(0, data);
            if (_tabController.index != 1) {
              _newNotificationCount++;
            }
          });
        }
      });
      _socket!.onDisconnect((_) => print('FeedScreen: Desconectado do Socket.IO Server'));
      _socket!.onError((data) => print('FeedScreen: Socket Error: $data'));
    } catch (e) {
      print('FeedScreen: Erro ao conectar ao socket: $e');
    }
  }

  Future<void> _fetchPosts() async {
    if (mounted) {
      setState(() {
        _isLoadingPosts = true;
        _postsErrorMessage = '';
      });
    }
    try {
      final response = await http.get(Uri.parse('http://localhost:8080/api/v1/posts'));
      if (mounted) {
        if (response.statusCode == 200) {
          final String responseBody = utf8.decode(response.bodyBytes);
          final List<dynamic> fetchedPosts = jsonDecode(responseBody);
          setState(() {
            _allPosts = fetchedPosts;
            _filteredPosts = List.from(_allPosts);
            _isLoadingPosts = false;
          });
          _filterPosts();
        } else {
          setState(() {
            _postsErrorMessage = 'Erro ao carregar posts: ${response.statusCode}';
            _isLoadingPosts = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _postsErrorMessage = 'Erro de conexão: $e';
          _isLoadingPosts = false;
        });
      }
    }
  }

  String _formatDate(String rawDate) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(rawDate));
    } catch (e) { return rawDate; }
  }

  @override
  void dispose() {
    _tabController.dispose(); // O listener é removido automaticamente com o dispose do controller
    _searchController.removeListener(_filterPosts);
    _searchController.dispose();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  // NOVA FUNÇÃO: Lógica de navegação para a BottomNavBar
  void _onBottomNavTapped(int index) {
    setState(() {
      _bottomNavCurrentIndex = index;
    });

    // Lógica de navegação (use pushReplacementNamed para evitar empilhar a mesma tela)
    // Adicione verificações para não navegar para a mesma tela se já estiver nela.
    final currentRoute = ModalRoute.of(context)?.settings.name;

    if (index == 0) { // Feed
      if (currentRoute != '/') { // Só navega se não estiver já no feed
        Navigator.pushReplacementNamed(context, '/');
      } else {
        _fetchPosts(); // Ou apenas atualiza o feed se já estiver nele
      }
    } else if (index == 1) { // Novo Post
      Navigator.pushNamed(context, '/create-post');
    } else if (index == 2) { // Perfil
      if (currentRoute != '/profile') { // Só navega se não estiver já no perfil
        Navigator.pushNamed(context, '/profile');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text('Feed', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.black),
            tooltip: 'Minhas Conversas',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ConversationListScreen()));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1D8BC9),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1D8BC9),
          tabs: [
            const Tab(text: 'Feed'),
            Tab(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Text('Notificações'),
                  if (_newNotificationCount > 0)
                    Positioned(
                      top: -4,
                      right: -12,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Center(
                          child: Text(
                            _newNotificationCount > 9 ? '9+' : '$_newNotificationCount',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_tabController.index == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(30)),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    hintText: 'Pesquisar por nome do item...',
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFeedContent(),
                _buildNotificationsContent(),
              ],
            ),
          ),
        ],
      ),
      // ATUALIZADO: Usando o CustomBottomNavBar
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _bottomNavCurrentIndex,
        onTap: _onBottomNavTapped, // Passa a função de callback
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchPosts,
        backgroundColor: const Color(0xFF1D8BC9),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildFeedContent() {
    if (_isLoadingPosts) return const Center(child: CircularProgressIndicator());
    if (_postsErrorMessage.isNotEmpty) return Center(child: Text(_postsErrorMessage));
    if (_filteredPosts.isEmpty) {
      if (_searchController.text.isNotEmpty) {
        return const Center(child: Text('Nenhum post encontrado com este nome.'));
      }
      return const Center(child: Text('Nenhum post encontrado.'));
    }
    return RefreshIndicator(
      onRefresh: _fetchPosts,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: _filteredPosts.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final post = _filteredPosts[index];
          return GestureDetector(
            onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => PostDetailScreen(post: post))); },
            child: _buildPostCard(post: post),
          );
        },
      ),
    );
  }

  Widget _buildNotificationsContent() {
    if (_notifications.isEmpty) {
      return const Center(child: Text('Nenhuma notificação no momento.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notificationData = _notifications[index];
        return _buildNotificationCard(notificationData);
      },
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> postData) {
    final String imageUrl = postData['fotoUrl'] ?? '';
    final String itemName = postData['nomeItem'] ?? 'Item não identificado';
    final String situacao = postData['situacao'] ?? '';
    final String dataPostagem = _formatDate(postData['createdAt'] ?? '');
    final String autorNome = postData['autor']?['nome'] ?? 'Alguém';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: SizedBox(
          width: 60,
          height: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.grey))
                : Container(color: Colors.grey[200], child: const Icon(Icons.photo, color: Colors.grey)),
          ),
        ),
        title: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style.copyWith(fontSize: 15, color: Colors.black87),
            children: <TextSpan>[
              TextSpan(text: '$autorNome postou um item '),
              TextSpan(
                text: situacao == 'achado' ? 'achado' : 'perdido',
                style: TextStyle(fontWeight: FontWeight.bold, color: situacao == 'achado' ? Colors.green : Colors.orange[700])
              ),
              const TextSpan(text: ': "'),
              TextSpan(text: itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: '"'),
            ],
          ),
        ),
        subtitle: Text('Em: $dataPostagem', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(post: postData),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostCard({required dynamic post}) {
    final bool isFound = post['situacao'] == 'achado';
    final String imageUrl = post['fotoUrl'] ?? '';
    final String itemName = post['nomeItem'] ?? 'Item não identificado';
    final String description = post['descricao'] ?? 'Sem descrição';
    final String authorName = post['autor']?['nome'] ?? 'Usuário anônimo';
    final String postDate = _formatDate(post['dataOcorrencia'] ?? '');

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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Container(
                color: Colors.grey[300],
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.white)),
                      )
                    : const Center(child: Icon(Icons.photo, size: 50, color: Colors.white)),
              ),
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
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Por: $authorName',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      postDate,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
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