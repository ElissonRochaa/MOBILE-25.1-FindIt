import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:find_it/service/auth_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:intl/intl.dart';
import 'package:find_it/widgets/custom_bottom_navbar.dart'; 

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

  // Define o índice para a BottomNavBar e cores de gradiente
  final int _bottomNavCurrentIndex = 0; 
  final Color _gradientStartColor = const Color(0xFF1D8BC9);
  final Color _gradientEndColor = const Color(0xFF01121B);
  final Color _pageBackgroundColor = const Color(0xffEFEFEF);


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
        const SnackBar(content: Text("Usuário não autenticado."), backgroundColor: Colors.red),
      );
      Navigator.pop(context);
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
    if (!mounted) return;
    setState(() => _isLoadingConversation = true);
    final token = await AuthService.getToken();
    if (token == null || widget.recipientId == null) {
      if(mounted) setState(() => _isLoadingConversation = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/v1/conversations'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
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
          SnackBar(content: Text(errorData['message'] ?? 'Erro ao iniciar conversa.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro de conexão ao iniciar conversa: $e'), backgroundColor: Colors.red),
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
      if (!mounted) return;
      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        setState(() {
          _messages = jsonDecode(responseBody);
        });
        _scrollToBottom();
      } else {
         final errorData = jsonDecode(utf8.decode(response.bodyBytes));
         if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorData['message'] ?? 'Erro ao buscar mensagens.'), backgroundColor: Colors.red),
            );
         }
      }
    } catch (e) {
       if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro de conexão ao buscar mensagens: $e'), backgroundColor: Colors.red),
            );
         }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _internalConversationId == null || _isSendingMessage) return;
    if (!mounted) return;
    setState(() => _isSendingMessage = true);
    final token = await AuthService.getToken();
    if (token == null) {
        if(mounted) setState(() => _isSendingMessage = false);
        return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/v1/conversations/$_internalConversationId/messages'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'content': _messageController.text.trim()}),
      );
      if (!mounted) return;
      if (response.statusCode == 201) {
        _messageController.clear();
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['message'] ?? 'Erro ao enviar mensagem.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
       if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de conexão ao enviar mensagem: $e'), backgroundColor: Colors.red),
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

  void _onBottomNavTapped(int index) {
    final currentRouteName = ModalRoute.of(context)?.settings.name;
    if (index == 0) {
      Navigator.popUntil(context, ModalRoute.withName('/feed'));
    } else if (index == 1) {
      if (currentRouteName != '/create-post') Navigator.pushNamed(context, '/create-post');
    } else if (index == 2) {
      if (currentRouteName != '/profile') Navigator.pushNamed(context, '/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackgroundColor, // COR DE FUNDO DA PÁGINA
      appBar: AppBar(
        leadingWidth: 30,
        backgroundColor: _pageBackgroundColor, // COR DE FUNDO DO APPBAR
        elevation: 0, // AppBar mais integrado
        iconTheme: const IconThemeData(color: Colors.black87), // Ícone de voltar
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
              backgroundImage: widget.recipientProfilePic != null && widget.recipientProfilePic!.isNotEmpty
                  ? NetworkImage(widget.recipientProfilePic!)
                  : null,
              child: widget.recipientProfilePic == null || widget.recipientProfilePic!.isEmpty
                  ? Icon(Icons.person, size: 22, color: Colors.grey[700])
                  : null,
            ),
            const SizedBox(width: 12),
            Text(widget.recipientName, style: const TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingConversation
                ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
                : _messages.isEmpty
                    ? const Center(child: Text('Nenhuma mensagem ainda. Envie uma!', style: TextStyle(color: Colors.grey)))
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
      // ADICIONADO: CustomBottomNavBar
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _bottomNavCurrentIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }

  // WIDGET DO BALÃO DE MENSAGEM ATUALIZADO COM GRADIENTE
  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    // A cor do balão do destinatário permanece cinza
    final Color recipientBubbleColor = Colors.grey[200]!; 
    final Color recipientTextColor = Colors.black87;
    final Color myTextColor = Colors.white;

    final timeAlignment = isMe ? TextAlign.right : TextAlign.left;
    final borderRadius = isMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4), // Canto menos arredondado para indicar a "ponta"
            topRight: Radius.circular(18), 
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(4), // Canto menos arredondado
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
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: isMe 
              ? BoxDecoration( // Aplica gradiente se a mensagem for minha
                  gradient: LinearGradient(
                    colors: [_gradientStartColor, _gradientEndColor],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: borderRadius,
                   boxShadow: [
                      BoxShadow(
                        color: _gradientStartColor.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      )
                    ]
                )
              : BoxDecoration( // Cor sólida se a mensagem for do destinatário
                  color: recipientBubbleColor,
                  borderRadius: borderRadius,
                   boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      )
                    ]
                ),
            child: Text(
              message['content'] ?? '',
              style: TextStyle(color: isMe ? myTextColor : recipientTextColor, fontSize: 15.5, height: 1.3),
            ),
          ),
           Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 10.0, right: 10.0),
            child: Text(
              DateFormat('HH:mm').format(DateTime.parse(message['createdAt'] ?? DateTime.now().toIso8601String()).toLocal()),
              textAlign: timeAlignment,
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: _pageBackgroundColor, // Fundo igual ao restante da tela
        border: Border(top: BorderSide(color: Colors.grey[300]!, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end, // Alinha itens ao final se o textfield crescer
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4), // Padding interno do container do textfield
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(24),
                 boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                    )
                  ]
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Digite uma mensagem...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0)
                ),
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 4, // Permite que o campo cresça um pouco
                // onSubmitted: (_) => _sendMessage(), // Opcional: enviar com enter do teclado
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material( // Para o efeito de splash no IconButton
             color: Colors.transparent,
            child: InkWell( // Para uma área de toque maior e feedback visual
              borderRadius: BorderRadius.circular(24),
              onTap: _isSendingMessage ? null : _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12), // Aumenta a área de toque
                decoration: BoxDecoration(
                  shape: BoxShape.circle, 
                  gradient: LinearGradient( // Gradiente no botão de enviar
                     colors: [_gradientStartColor, _gradientEndColor.withOpacity(0.8)],
                     begin: Alignment.topLeft,
                     end: Alignment.bottomRight,
                  ),
                ),
                child: _isSendingMessage 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) 
                    : const Icon(Icons.send, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}