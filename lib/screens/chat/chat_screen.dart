import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:find_it/service/auth_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String? recipientId; 
  final String recipientName; 
  final String? recipientProfilePic; 
  final String? conversationId; 

  const ChatScreen({
    Key? key,
    this.recipientId,
    required this.recipientName,
    this.recipientProfilePic,
    this.conversationId,
  })  : assert(recipientId != null || conversationId != null,
            'Deve ser fornecido recipientId ou conversationId'),
        super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _messages = [];
  bool _isLoadingConversation = true;
  bool _isSendingMessage = false;
  String? _internalConversationId; 
  String? _currentUserId;

  IO.Socket? _socket;

  @override
  void initState() {
    super.initState();
 
    _internalConversationId = widget.conversationId;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _currentUserId = await AuthService.getUserId();
    if (_currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Usuário não autenticado."), backgroundColor: Colors.red),
        );
        Navigator.pop(context);
      }
      return;
    }

 
    if (_internalConversationId != null) {
      setState(() => _isLoadingConversation = true);
      await _fetchMessages();
      _connectToSocket(); 
      if (mounted) setState(() => _isLoadingConversation = false);
    } 
 
    else if (widget.recipientId != null) {
      await _initiateOrGetConversation();
    } 
    else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro: Informações da conversa ausentes."), backgroundColor: Colors.red),
        );
        Navigator.pop(context);
      }
    }
  }

  void _connectToSocket() async { 
    if (_internalConversationId == null || _socket != null) return;

    final token = await AuthService.getToken();
    if (token == null && mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Autenticação necessária para o chat."), backgroundColor: Colors.red),
        );
      return;
    }

    try {
      _socket = IO.io('http://localhost:8080', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false, 
        'auth': {
          'token': token
        }
      });

      _socket!.connect(); 

      _socket!.onConnect((_) {
        print('ChatScreen: Conectado ao Socket.IO Server');
        _socket!.emit('joinRoom', _internalConversationId);
      });

      _socket!.on('newMessage', (data) {
        print('ChatScreen: Nova mensagem recebida via socket: $data');
        if (mounted) {
          setState(() {
            final newMessageId = data?['_id'];
            if (newMessageId != null && !_messages.any((msg) => msg['_id'] == newMessageId)) {
              _messages.add(data);
              _messages.sort((a, b) => DateTime.parse(a['createdAt']).compareTo(DateTime.parse(b['createdAt'])));
            }
          });
          _scrollToBottom();
        }
      });
      
      _socket!.on('auth_error', (data) { 
          print('ChatScreen: Erro de autenticação na sala do Socket: $data');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data?['message'] ?? 'Erro ao entrar na sala de chat.'), backgroundColor: Colors.red),
            );
          }
      });

      _socket!.onDisconnect((_) => print('ChatScreen: Desconectado do Socket.IO Server'));
      _socket!.onError((data) => print('ChatScreen: Socket Error: $data'));

    } catch (e) {
      print('ChatScreen: Erro ao conectar ao socket: $e');
    }
  }

  Future<void> _initiateOrGetConversation() async {

    setState(() => _isLoadingConversation = true);
    final token = await AuthService.getToken();
    if (token == null || widget.recipientId == null) {
      if(mounted) setState(() => _isLoadingConversation = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/v1/conversations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'recipientId': widget.recipientId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final conversationData = jsonDecode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            _internalConversationId = conversationData['_id'];
          });
        }
        await _fetchMessages();
        _connectToSocket(); 
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        print('Erro ao iniciar conversa: ${errorData['message']}');
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorData['message'] ?? 'Erro ao iniciar conversa.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      print('Erro ao iniciar conversa (catch): $e');
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro de conexão ao iniciar conversa.'), backgroundColor: Colors.red),
          );
      }
    } finally {
      if (mounted) setState(() => _isLoadingConversation = false);
    }
  }

  Future<void> _fetchMessages() async {
    if (_internalConversationId == null) return;
    final token = await AuthService.getToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/v1/conversations/$_internalConversationId/messages'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        if (mounted) {
          setState(() {
            _messages = jsonDecode(responseBody);
          });
          _scrollToBottom();
        }
      } else {
         final errorData = jsonDecode(utf8.decode(response.bodyBytes));
         print('Erro ao buscar mensagens: ${errorData['message']}');
         if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorData['message'] ?? 'Erro ao buscar mensagens.'), backgroundColor: Colors.red),
            );
         }
      }
    } catch (e) {
      print('Erro ao buscar mensagens (catch): $e');
       if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro de conexão ao buscar mensagens.'), backgroundColor: Colors.red),
            );
         }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || _internalConversationId == null || _isSendingMessage) return;

    setState(() => _isSendingMessage = true);
    final token = await AuthService.getToken();
    if (token == null) {
        if(mounted) setState(() => _isSendingMessage = false);
        return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/v1/conversations/$_internalConversationId/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'content': _messageController.text}),
      );

      if (response.statusCode == 201) {
        _messageController.clear();
    
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        print('Erro ao enviar mensagem: ${errorData['message']}');
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorData['message'] ?? 'Erro ao enviar mensagem.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
       print('Erro ao enviar mensagem (catch): $e');
       if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de conexão ao enviar mensagem.'), backgroundColor: Colors.red),
        );
       }
    } finally {
      if (mounted) setState(() => _isSendingMessage = false);
    }
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _scrollController.position.hasContentDimensions) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _socket?.emit('leaveRoom', _internalConversationId);
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 30,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: widget.recipientProfilePic != null && widget.recipientProfilePic!.isNotEmpty
                  ? NetworkImage(widget.recipientProfilePic!)
                  : null,
              child: widget.recipientProfilePic == null || widget.recipientProfilePic!.isEmpty
                  ? const Icon(Icons.person, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(widget.recipientName, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingConversation
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('Nenhuma mensagem ainda. Envie uma!'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final bool isMe = message['sender']?['_id'] == _currentUserId;
                          return _buildMessageBubble(message, isMe);
                        },
                      ),
          ),
          _buildMessageInputField(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isMe ? Theme.of(context).primaryColor : Colors.grey[300];
    final textColor = isMe ? Colors.white : Colors.black87;
    final timeAlignment = isMe ? TextAlign.right : TextAlign.left;
    final borderRadius = isMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            topRight: Radius.circular(16), 
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: borderRadius,
            ),
            child: Text(
              message['content'] ?? '',
              style: TextStyle(color: textColor, fontSize: 15),
            ),
          ),
           Padding(
            padding: const EdgeInsets.only(top: 3.0, left: 8.0, right: 8.0),
            child: Text(
              DateFormat('HH:mm').format(DateTime.parse(message['createdAt'] ?? DateTime.now().toIso8601String()).toLocal()),
              textAlign: timeAlignment,
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Digite uma mensagem...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12.0)
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: _isSendingMessage 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.send, color: Theme.of(context).primaryColor),
            onPressed: _isSendingMessage ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}