import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:find_it/service/auth_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:intl/intl.dart';
import 'package:find_it/widgets/custom_bottom_navbar.dart';
import 'package:find_it/service/theme_service.dart';

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

  final int _bottomNavCurrentIndex = 0;

  @override
  void initState() {
    super.initState();
    _internalConversationId = widget.conversationId;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _currentUserId = await AuthService.getUserId();
    if (!mounted) return;
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Usuário não autenticado."),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      Navigator.pop(context);
      return;
    }

    if (_internalConversationId != null) {
      setState(() => _isLoadingConversation = true);
      await _fetchMessages(); // Busca as mensagens históricas
      _connectToSocket(); // Conecta e configura o socket para tempo real
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
      _socket = IO.io('http://localhost:8080', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': {'token': token}
      });

      _socket!.connect();

      _socket!.onConnect((_) {
        print('ChatScreen: Conectado ao Socket.IO Server. Socket ID: ${_socket!.id}');
        _socket!.emit('joinRoom', _internalConversationId);
        print('ChatScreen: Emitindo "joinRoom" para sala: $_internalConversationId');
      });

      // ADICIONADO MAIS LOGS AQUI
      _socket!.on('newMessage', (data) {
        print('ChatScreen: Evento "newMessage" recebido!');
        print('ChatScreen: Dados brutos da nova mensagem: ${jsonEncode(data)}'); // Log dos dados brutos

        if (mounted) {
          setState(() {
            final newMessageId = data?['_id'];
            final newCreatedAt = data?['createdAt'];
            print('ChatScreen: newMessageId: $newMessageId, newCreatedAt: $newCreatedAt');

            // Verifica se as chaves essenciais existem e não são nulas
            if (newMessageId == null || newCreatedAt == null) {
                print('ChatScreen: Erro: Mensagem recebida sem _id ou createdAt. Ignorando.');
                return; // Ignora a mensagem malformada
            }

            final bool messageExists = _messages.any((msg) => msg['_id'] == newMessageId);
            print('ChatScreen: Mensagem com ID $newMessageId já existe na lista? $messageExists');

            if (!messageExists) {
              _messages.add(data);
              // Tenta parsear e ordenar, com tratamento de erro
              try {
                _messages.sort((a, b) =>
                    DateTime.parse(a['createdAt'] ?? '').compareTo(DateTime.parse(b['createdAt'] ?? '')));
                print('ChatScreen: Mensagens ordenadas.');
              } catch (e) {
                print('ChatScreen: Erro ao ordenar mensagens (problema de data?): $e');
              }
              print('ChatScreen: Mensagem adicionada. Total de mensagens: ${_messages.length}');
            } else {
              print('ChatScreen: Mensagem já existia, não adicionada para evitar duplicata.');
            }
          });
          _scrollToBottom();
        } else {
          print('ChatScreen: Widget não está montado ao tentar processar newMessage.');
        }
      });

      _socket!.on('auth_error', (data) {
        print('ChatScreen: Erro de autenticação do Socket: $data');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data?['message'] ?? 'Erro ao entrar na sala de chat (autenticação).'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      });
      _socket!.onDisconnect((_) => print('ChatScreen: Desconectado do Socket.IO Server'));
      _socket!.onError((data) => print('ChatScreen: Socket Error: $data'));
    } catch (e) {
      print('ChatScreen: Erro catastrófico ao conectar ao socket: $e');
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
        Uri.parse('http://localhost:8080/api/v1/conversations'),
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
        await _fetchMessages(); // Busca as mensagens históricas
        _connectToSocket(); // Conecta e configura o socket
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
      print('ChatScreen: Buscando mensagens históricas para $_internalConversationId');
      final response = await http.get(
        Uri.parse(
            'http://localhost:8080/api/v1/conversations/$_internalConversationId/messages'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final List<dynamic> fetchedMessages = jsonDecode(responseBody);
        setState(() {
          _messages = fetchedMessages;
          // Ordenar as mensagens históricas também
          _messages.sort((a, b) => DateTime.parse(a['createdAt']).compareTo(DateTime.parse(b['createdAt'])));
        });
        print('ChatScreen: Mensagens históricas carregadas: ${_messages.length}');
        _scrollToBottom();
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorData['message'] ?? 'Erro ao buscar mensagens históricas.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro de conexão ao buscar mensagens históricas: $e'),
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
      print('ChatScreen: Enviando mensagem via HTTP: ${_messageController.text.trim()}');
      final response = await http.post(
        Uri.parse(
            'http://localhost:8080/api/v1/conversations/$_internalConversationId/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'content': _messageController.text.trim()}),
      );
      if (!mounted) return;
      if (response.statusCode == 201) {
        print('ChatScreen: Mensagem HTTP enviada com sucesso (status 201).');
        _messageController.clear();
        // A mensagem deve vir via Socket.IO agora, então não adicionamos aqui diretamente.
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
    // Certifique-se de que o socket só é manipulado se não for nulo
    _socket?.emit('leaveRoom', _internalConversationId);
    _socket?.disconnect();
    _socket?.dispose();
    print('ChatScreen: Socket desconectado e dispose concluído.');
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    final currentRouteName = ModalRoute.of(context)?.settings.name;
    if (index == 0) {
      Navigator.popUntil(context, ModalRoute.withName('/feed'));
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leadingWidth: 30,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: theme.appBarTheme.iconTheme,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.cardColor.withOpacity(0.5),
              backgroundImage: widget.recipientProfilePic != null &&
                      widget.recipientProfilePic!.isNotEmpty
                  ? NetworkImage(widget.recipientProfilePic!)
                  : null,
              child: widget.recipientProfilePic == null ||
                      widget.recipientProfilePic!.isEmpty
                  ? Icon(
                      Icons.person,
                      size: 22,
                      color: theme.iconTheme.color,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              widget.recipientName,
              style: TextStyle(
                fontSize: 18,
                color: theme.textTheme.titleLarge?.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
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
                          return _buildMessageBubble(message, isMe);
                        },
                      ),
          ),
          _buildMessageInputField(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _bottomNavCurrentIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    final theme = Theme.of(context);
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final Color recipientBubbleColor = theme.cardColor;
    final Color recipientTextColor = theme.textTheme.bodyMedium?.color ?? Colors.black87;
    final Color myTextColor = theme.colorScheme.onPrimary;

    final timeAlignment = isMe ? TextAlign.right : TextAlign.left;
    final borderRadius = isMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
            topRight: Radius.circular(18),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: isMe
                ? BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.primaryColor,
                        theme.brightness == Brightness.light
                            ? ThemeNotifier.findItPrimaryDarkBlue
                            : theme.colorScheme.primaryContainer,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: borderRadius,
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      )
                    ],
                  )
                : BoxDecoration(
                    color: recipientBubbleColor,
                    borderRadius: borderRadius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      )
                    ],
                  ),
            child: Text(
              message['content'] ?? '',
              style: TextStyle(
                color: isMe ? myTextColor : recipientTextColor,
                fontSize: 15.5,
                height: 1.3,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 10.0, right: 10.0),
            child: Text(
              DateFormat('HH:mm').format(DateTime.parse(
                      message['createdAt'] ?? DateTime.now().toIso8601String())
                  .toLocal()),
              textAlign: timeAlignment,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 11,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMessageInputField() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                  )
                ],
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Digite uma mensagem...',
                  hintStyle: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 4,
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: _isSendingMessage ? null : _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor,
                      theme.brightness == Brightness.light
                          ? ThemeNotifier.findItPrimaryDarkBlue
                          : theme.colorScheme.primaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: _isSendingMessage
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : Icon(
                        Icons.send,
                        color: theme.colorScheme.onPrimary,
                        size: 22,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}