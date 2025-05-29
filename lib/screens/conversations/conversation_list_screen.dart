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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Minhas Conversas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline, 
                          color: theme.colorScheme.error, 
                          size: 50,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage!, 
                          textAlign: TextAlign.center, 
                          style: TextStyle(
                            fontSize: 16, 
                            color: theme.colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar Novamente'),
                          onPressed: _fetchConversations,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: theme.colorScheme.onPrimary,
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
                          Icon(
                            Icons.chat_bubble_outline_rounded, 
                            size: 70, 
                            color: theme.iconTheme.color?.withOpacity(0.5),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Nenhuma conversa encontrada.', 
                            style: TextStyle(
                              fontSize: 17, 
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Inicie uma conversa visitando o perfil de um usuário.', 
                            style: TextStyle(
                              fontSize: 14, 
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                            ), 
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchConversations,
                      color: theme.primaryColor,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        itemCount: _conversations.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 0, 
                          indent: 86, 
                          endIndent: 16, 
                          thickness: 0.5,
                          color: theme.dividerColor,
                        ),
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
                            color: theme.scaffoldBackgroundColor,
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
                                    SnackBar(
                                      content: const Text('Não foi possível abrir a conversa. Tente novamente.'),
                                      backgroundColor: theme.colorScheme.errorContainer,
                                    )
                                  );
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: theme.cardColor.withAlpha((0.5 * 255).toInt()),
                                      backgroundImage: otherParticipantProfilePic != null && otherParticipantProfilePic.isNotEmpty
                                          ? NetworkImage(otherParticipantProfilePic)
                                          : null,
                                      child: (otherParticipantProfilePic == null || otherParticipantProfilePic.isEmpty)
                                          ? Text(
                                              otherParticipantName.isNotEmpty ? otherParticipantName[0].toUpperCase() : '?',
                                              style: TextStyle(
                                                fontSize: 22, 
                                                color: theme.colorScheme.onSurface, 
                                                fontWeight: FontWeight.bold,
                                              ),
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
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold, 
                                              fontSize: 16, 
                                              color: theme.textTheme.titleMedium?.color,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            lastMessageContent,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                                              fontSize: 14,
                                              fontWeight: isLastMessageFromMe ? FontWeight.normal : FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      lastMessageTime, 
                                      style: TextStyle(
                                        fontSize: 12, 
                                        color: theme.textTheme.bodySmall?.color,
                                      ),
                                    ),
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