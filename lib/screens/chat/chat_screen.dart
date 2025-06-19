import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:find_it/service/auth_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:find_it/widgets/custom_bottom_navbar.dart';

// IMPORTS DOS WIDGETS CUSTOMIZADOS
import 'package:find_it/widgets/chat_app_bar_title.dart';
import 'package:find_it/widgets/message_bubble.dart';
import 'package:find_it/widgets/message_input_field.dart';

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
  // --- TODA A LÓGICA DE ESTADO E FUNÇÕES PERMANECE AQUI ---
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  bool _isLoadingConversation = true;
  bool _isSendingMessage = false;
  String? _internalConversationId;
  String? _currentUserId;
  IO.Socket? _socket;
  final int _bottomNavCurrentIndex = -1;

  @override
  void initState() {
    super.initState();
    _internalConversationId = widget.conversationId;
    _loadInitialData();
  }

  // As funções de lógica (initState, dispose, _loadInitialData, _connectToSocket,
  // _initiateOrGetConversation, _fetchMessages, _sendMessage, _scrollToBottom, _onBottomNavTapped)
  // permanecem exatamente as mesmas da versão anterior. Não precisam de alteração.

  Future<void> _loadInitialData() async {
    _currentUserId = await AuthService.getUserId();
    if (!mounted) return;
    if (_currentUserId == null) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Usuário não autenticado."),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
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
    } else if (widget.recipientId != null) {
      await _initiateOrGetConversation();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Erro: Informações da conversa ausentes."),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
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
        SnackBar(
          content: const Text("Autenticação necessária para o chat."),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    try {
      _socket = IO.io('http://10.0.0.110:8080', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': {'token': token}
      });
      _socket!.connect();
      _socket!.onConnect((_) {
        print('ChatScreen: Conectado ao Socket.IO Server');
        _socket!.emit('joinRoom', _internalConversationId);
      });
      _socket!.on('newMessage', (data) {
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data?['message'] ?? 'Erro ao entrar na sala de chat.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
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
    if (!mounted) return;
    setState(() => _isLoadingConversation = true);
    final token = await AuthService.getToken();
    if (token == null || widget.recipientId == null) {
      if (mounted) setState(() => _isLoadingConversation = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://10.0.0.110:8080/api/v1/conversations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'recipientId': widget.recipientId}),
      );
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        final conversationData = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _internalConversationId = conversationData['_id'];
        });
        await _fetchMessages();
        _connectToSocket();
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['message'] ?? 'Erro ao iniciar conversa.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro de conexão ao iniciar conversa: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
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
        Uri.parse(
            'http://10.0.0.110:8080/api/v1/conversations/$_internalConversationId/messages'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        setState(() {
          _messages = jsonDecode(responseBody);
        });
        _scrollToBottom();
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorData['message'] ?? 'Erro ao buscar mensagens.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro de conexão ao buscar mensagens: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty ||
        _internalConversationId == null ||
        _isSendingMessage) return;
    if (!mounted) return;
    setState(() => _isSendingMessage = true);
    final token = await AuthService.getToken();
    if (token == null) {
      if (mounted) setState(() => _isSendingMessage = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(
            'http://10.0.0.110:8080/api/v1/conversations/$_internalConversationId/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'content': _messageController.text.trim()}),
      );
      if (!mounted) return;
      if (response.statusCode == 201) {
        _messageController.clear();
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['message'] ?? 'Erro ao enviar mensagem.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro de conexão ao enviar mensagem: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingMessage = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.hasContentDimensions) {
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

  void _onBottomNavTapped(int index) {
    const feedRoute = '/feed';
    const createPostRoute = '/create-post';
    const profileRoute = '/profile';

    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, feedRoute, (route) => false);
        break;
      case 1:
        Navigator.pushNamed(context, createPostRoute);
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(context, profileRoute, (route) => false);
        break;
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leadingWidth: 30,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: theme.appBarTheme.iconTheme,
        title: ChatAppBarTitle(
          recipientName: widget.recipientName,
          recipientProfilePic: widget.recipientProfilePic,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingConversation
                ? Center(
                child: CircularProgressIndicator(color: theme.primaryColor))
                : _messages.isEmpty
                ? Center(
              child: Text(
                'Nenhuma mensagem ainda. Envie uma!',
                // CORREÇÃO APLICADA AQUI
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withAlpha(153)
                ),
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final bool isMe =
                    message['sender']?['_id'] == _currentUserId;
                return MessageBubble(message: message, isMe: isMe);
              },
            ),
          ),
          MessageInputField(
            controller: _messageController,
            onSendMessage: _sendMessage,
            isSendingMessage: _isSendingMessage,
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _bottomNavCurrentIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }
}