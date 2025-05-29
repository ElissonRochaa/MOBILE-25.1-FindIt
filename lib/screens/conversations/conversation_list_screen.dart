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
  final Color _pageBackgroundColor = const Color(0xffEFEFEF);

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
    if (index == 0) { 
      if (currentRouteName != '/feed') {

        Navigator.popUntil(context, ModalRoute.withName('/feed'));
      }
    } else if (index == 1) { 
      Navigator.pushNamed(context, '/create-post');
    } else if (index == 2) { 
      if (currentRouteName != '/profile') {
        Navigator.pushNamed(context, '/profile');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackgroundColor, 
      appBar: AppBar(
        title: const Text('Minhas Conversas', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        centerTitle: true,
        backgroundColor: _pageBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87), 
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[300], size: 50),
                        const SizedBox(height: 10),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.red[700])),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar Novamente'),
                          onPressed: _fetchConversations,
                           style: ElevatedButton.styleFrom(
                             backgroundColor: Theme.of(context).primaryColor,
                             foregroundColor: Colors.white
                           ),
                        )
                      ],
                    ),
                  )
                )
              : _conversations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 70, color: Colors.grey[400]),
                          const SizedBox(height: 20),
                          Text('Nenhuma conversa encontrada.', style: TextStyle(fontSize: 17, color: Colors.grey[600])),
                          const SizedBox(height: 8),
                           Text('Inicie uma conversa visitando o perfil de um usuário.', style: TextStyle(fontSize: 14, color: Colors.grey[500]), textAlign: TextAlign.center,),
                        ],
                      )
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchConversations,
                      color: Theme.of(context).primaryColor,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        itemCount: _conversations.length,
                        separatorBuilder: (context, index) => const Divider(height: 0, indent: 86, endIndent: 16, thickness: 0.5),
                        itemBuilder: (context, index) {
                          final conversation = _conversations[index];
                          final List<dynamic> participants = conversation['participants'] ?? [];
                          final otherParticipantName = _getOtherParticipantName(participants);
                          final otherParticipantProfilePic = _getOtherParticipantProfilePic(participants);
                          final otherParticipantId = _getOtherParticipantId(participants);
                          final lastMessageData = conversation['lastMessage'];
                          
                          String lastMessageContent = "Inicie a conversa!";
                          String lastMessageTime = "";
                          bool isLastMessageFromMe = false;

                          if (lastMessageData != null) {
                            lastMessageContent = lastMessageData['content'] ?? "Mensagem...";
                            if (lastMessageData['sender']?['_id'] == _currentUserId) {
                              isLastMessageFromMe = true;
                              lastMessageContent = "Você: $lastMessageContent";
                            }
                            if (lastMessageData['createdAt'] != null) {
                                try {
                                  lastMessageTime = DateFormat('HH:mm').format(DateTime.parse(lastMessageData['createdAt']).toLocal());
                                } catch (e) {
                                  lastMessageTime = ""; 
                                }
                            }
                          }

                          return Material( 
                            color: _pageBackgroundColor,
                            child: InkWell(
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
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Colors.grey[300],
                                      backgroundImage: otherParticipantProfilePic != null && otherParticipantProfilePic.isNotEmpty
                                          ? NetworkImage(otherParticipantProfilePic)
                                          : null,
                                      child: (otherParticipantProfilePic == null || otherParticipantProfilePic.isEmpty)
                                          ? Text(
                                              otherParticipantName.isNotEmpty ? otherParticipantName[0].toUpperCase() : '?',
                                              style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            otherParticipantName, 
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            lastMessageContent,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.grey[600], 
                                              fontSize: 14,
                                              fontWeight: isLastMessageFromMe ? FontWeight.normal : FontWeight.w500, // Destaca se não for minha
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(lastMessageTime, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                  ],
                                ),
                              ),
                            ),
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