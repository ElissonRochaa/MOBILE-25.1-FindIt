import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:find_it/service/auth_service.dart';
import 'package:find_it/screens/chat/chat_screen.dart';
import 'package:intl/intl.dart';
import 'package:find_it/widgets/custom_bottom_navbar.dart'; 

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({Key? key}) : super(key: key);

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  List<dynamic> _conversations = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentUserId;
  final int _bottomNavCurrentIndex = 0; 

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _currentUserId = await AuthService.getUserId();
    if (!mounted) return;
    if (_currentUserId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Usuário não autenticado.";
      });
      return;
    }
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final token = await AuthService.getToken();
    if (token == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Autenticação necessária.";
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/v1/conversations'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        setState(() {
          _conversations = jsonDecode(responseBody);
          _isLoading = false;
        });
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _errorMessage = errorData['message'] ?? 'Erro ao carregar conversas';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro de conexão: $e';
        _isLoading = false;
      });
    }
  }

  String _getOtherParticipantName(List<dynamic> participants) {
    if (_currentUserId == null) return 'Desconhecido';
    final otherParticipant = participants.firstWhere(
      (p) => p['_id'] != _currentUserId,
      orElse: () => null,
    );
    return otherParticipant?['nome'] ?? 'Desconhecido';
  }

  String? _getOtherParticipantProfilePic(List<dynamic> participants) {
    if (_currentUserId == null) return null;
    final otherParticipant = participants.firstWhere(
      (p) => p['_id'] != _currentUserId,
      orElse: () => null,
    );
    return otherParticipant?['profilePicture'];
  }

  String _getOtherParticipantId(List<dynamic> participants) {
    if (_currentUserId == null) return '';
    final otherParticipant = participants.firstWhere(
      (p) => p['_id'] != _currentUserId,
      orElse: () => {'_id': ''},
    );
    return otherParticipant['_id'] ?? '';
  }

  void _onBottomNavTapped(int index) {
    final currentRouteName = ModalRoute.of(context)?.settings.name;

    if (index == 0) { // Feed
      if (currentRouteName != '/') {
        Navigator.popUntil(context, ModalRoute.withName('/'));
      }
    } else if (index == 1) { // Novo Post
      Navigator.pushNamed(context, '/create-post');
    } else if (index == 2) { // Perfil
      if (currentRouteName != '/profile') {
        Navigator.pushNamed(context, '/profile');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Conversas', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_errorMessage!, textAlign: TextAlign.center),
                ))
              : _conversations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text('Nenhuma conversa encontrada.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      )
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchConversations,
                      child: ListView.separated(
                        itemCount: _conversations.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, indent: 70, endIndent: 16),
                        itemBuilder: (context, index) {
                          final conversation = _conversations[index];
                          final List<dynamic> participants = conversation['participants'] ?? [];
                          final otherParticipantName = _getOtherParticipantName(participants);
                          final otherParticipantProfilePic = _getOtherParticipantProfilePic(participants);
                          final otherParticipantId = _getOtherParticipantId(participants);
                          final lastMessage = conversation['lastMessage'];
                          
                          String lastMessageContent = "Inicie a conversa!";
                          String lastMessageTime = "";

                          if (lastMessage != null) {
                            lastMessageContent = lastMessage['content'] ?? "Mensagem...";
                            if (lastMessage['sender']?['_id'] == _currentUserId) {
                              lastMessageContent = "Você: $lastMessageContent";
                            }
                            if (lastMessage['createdAt'] != null) {
                                try {
                                  lastMessageTime = DateFormat('HH:mm').format(DateTime.parse(lastMessage['createdAt']).toLocal());
                                } catch (e) {
                                  lastMessageTime = ""; 
                                }
                            }
                          }

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: otherParticipantProfilePic != null && otherParticipantProfilePic.isNotEmpty
                                  ? NetworkImage(otherParticipantProfilePic)
                                  : null,
                              child: (otherParticipantProfilePic == null || otherParticipantProfilePic.isEmpty)
                                  ? const Icon(Icons.person, size: 28, color: Colors.white)
                                  : null,
                            ),
                            title: Text(otherParticipantName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              lastMessageContent,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            trailing: Text(lastMessageTime, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            onTap: () {
                              if (otherParticipantId.isNotEmpty) { 
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      conversationId: conversation['_id'],
                                      recipientId: otherParticipantId, 
                                      recipientName: otherParticipantName,
                                      recipientProfilePic: otherParticipantProfilePic,
                                    ),
                                  ),
                                ).then((_) => _fetchConversations()); 
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Não foi possível abrir a conversa. Tente novamente.'), backgroundColor: Colors.orange)
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _bottomNavCurrentIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }
}