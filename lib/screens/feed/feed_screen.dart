import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:find_it/screens/post_detail/post_detail_screen.dart';
import 'package:find_it/screens/conversations/conversation_list_screen.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:find_it/service/auth_service.dart';
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
  int _bottomNavCurrentIndex = 0;

  List<dynamic> _allPosts = [];
  List<dynamic> _filteredPosts = [];
  bool _isLoadingPosts = true;
  String _postsErrorMessage = '';
  List<dynamic> _notifications = [];
  int _newNotificationCount = 0;
  IO.Socket? _socket;

  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;
  final Color _focusColor = const Color(0xFF1D8BC9); 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchPosts();
    _initSocketConnection();

    _tabController.addListener(_handleTabSelection);
    _searchController.addListener(_filterPosts);

    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isSearchFocused = _searchFocusNode.hasFocus;
        });
      }
    });
  }

  void _filterPosts() {
    final query = _searchController.text.toLowerCase();
    if (mounted) {
      setState(() {
        if (query.isEmpty) {
          _filteredPosts = List.from(_allPosts);
        } else {
          _filteredPosts =
              _allPosts.where((post) {
                final itemName =
                    post['nomeItem']?.toString().toLowerCase() ?? '';
                return itemName.contains(query);
              }).toList();
        }
      });
    }
  }

  void _handleTabSelection() {
    if (mounted) {
      setState(() {}); 
    }
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
        'auth': {'token': token},
      });
      _socket!.connect();
      _socket!.onConnect((_) {
        print('FeedScreen: Conectado ao Socket.IO Server');
      });
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
      _socket!.onDisconnect(
        (_) => print('FeedScreen: Desconectado do Socket.IO Server'),
      );
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
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/v1/posts'),
      );
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
            _postsErrorMessage =
                'Erro ao carregar posts: ${response.statusCode}';
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
    } catch (e) {
      return rawDate;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(
      _handleTabSelection,
    ); 
    _tabController.dispose();
    _searchController.removeListener(_filterPosts);
    _searchController.dispose();
    _searchFocusNode.dispose(); 
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    if (index == _bottomNavCurrentIndex && index == 0) {
      _fetchPosts(); 
      return;
    }

    if (index != _bottomNavCurrentIndex) {
      setState(() {
        _bottomNavCurrentIndex = index;
      });
    }

    final String? currentRouteName = ModalRoute.of(context)?.settings.name;

    if (index == 0) {
      if (currentRouteName != '/feed') {
        Navigator.pushReplacementNamed(context, '/feed');
      }
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
    final Color focusedSearchInputFillColor = _focusColor.withOpacity(0.1);

    return Scaffold(
      backgroundColor: const Color(0xffEFEFEF), 
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
        backgroundColor: const Color(0xffEFEFEF), 
        elevation: 0, 
        iconTheme: const IconThemeData(color: Colors.black), 
        actions: [
          IconButton(
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.black,
            ),
            tooltip: 'Minhas Conversas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConversationListScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: _focusColor,
          unselectedLabelColor: Colors.grey[600], 
          indicatorColor: _focusColor, 
          indicatorWeight: 3.0, 
          tabs: [
            const Tab(text: 'Achados & Perdidos'), 
            Tab(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Text('Notificações'),
                  if (_newNotificationCount > 0)
                    Positioned(
                      top: -5, 
                      right: -15, 
                      child: Container(
                        padding: const EdgeInsets.all(2), 
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8), 
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _newNotificationCount > 9
                              ? '9+'
                              : '$_newNotificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Container(
        color: const Color(0xffEFEFEF), 
        child: Column(
          children: [
            if (_tabController.index == 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container( 
                  decoration: BoxDecoration(
                    color: _isSearchFocused ? focusedSearchInputFillColor : Colors.white, 
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: _isSearchFocused ? _focusColor : Colors.grey.shade300, 
                      width: _isSearchFocused ? 1.5 : 1.0,
                    ),
                     boxShadow: [
                       BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      )
                    ]
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode, 
                    cursorColor: _focusColor,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    decoration: InputDecoration(
                      border: InputBorder.none, 
                      prefixIcon: Icon(
                        Icons.search, 
                        color: _isSearchFocused ? _focusColor : Colors.grey[600]
                      ),
                      hintText: 'Pesquisar por nome do item...',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15, 
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildFeedContent(), _buildNotificationsContent()],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _bottomNavCurrentIndex,
        onTap: _onBottomNavTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchPosts,
        backgroundColor: _focusColor,
        foregroundColor: Colors.white, 
        child: const Icon(Icons.refresh),
        tooltip: 'Atualizar Feed',
      ),
    );
  }

  Widget _buildFeedContent() {
    if (_isLoadingPosts) return const Center(child: CircularProgressIndicator());
    if (_postsErrorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_postsErrorMessage, textAlign: TextAlign.center),
        ),
      );
    }

    if (_filteredPosts.isEmpty) {
      if (_searchController.text.isNotEmpty) {
        return Center(
          child: Text('Nenhum post encontrado com "${_searchController.text}".', style: TextStyle(color: Colors.grey[600])),
        );
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.find_in_page_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Nenhum post encontrado.', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            TextButton(onPressed: _fetchPosts, child: Text('Tentar novamente', style: TextStyle(color: _focusColor)))
          ],
        )
      );
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailScreen(post: post),
                ),
              );
            },
            child: _buildPostCard(post: post),
          );
        },
      ),
    );
  }

  Widget _buildNotificationsContent() {
    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Nenhuma notificação no momento.', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        )
      );
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
        contentPadding: const EdgeInsets.all(12),
        leading: SizedBox(
          width: 60,
          height: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  )
                : Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.photo_library_outlined, color: Colors.grey),
                  ),
          ),
        ),
        title: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style.copyWith(fontSize: 15, color: Colors.black87),
            children: <TextSpan>[
              TextSpan(text: autorNome, style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: ' postou um item '),
              TextSpan(
                text: situacao == 'achado' ? 'achado' : 'perdido',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: situacao == 'achado' ? Colors.green.shade700 : Colors.orange.shade800,
                ),
              ),
              const TextSpan(text: ': "'),
              TextSpan(text: itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: '"'),
            ],
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text('Em: $dataPostagem', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
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
            color: Colors.grey.withOpacity(0.15), 
            spreadRadius: 1,
            blurRadius: 6, 
            offset: const Offset(0, 3), 
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
                color: Colors.grey[200],
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Icon(Icons.broken_image_outlined, size: 50, color: Colors.grey)),
                      )
                    : Center(child: Icon(Icons.photo_library_outlined, size: 50, color: Colors.grey[400])),
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
                          fontSize: 18, // Ajustado para consistência
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
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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