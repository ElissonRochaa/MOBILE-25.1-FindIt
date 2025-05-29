import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:find_it/service/auth_service.dart';
import 'package:find_it/screens/chat/chat_screen.dart';
import 'package:find_it/widgets/custom_bottom_navbar.dart';
import 'package:provider/provider.dart';
import 'package:find_it/service/theme_service.dart';

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
  String profilePictureUrl = '';
  List<dynamic> _userPosts = [];
  String _selectedTab = 'perdido';
  bool _isLoading = true;
  String? _errorMessage;
  String? _loggedInUserId;

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

  void _onBottomNavTapped(int index) {
    if (index == 0) { // Feed
      Navigator.popUntil(context, ModalRoute.withName('/'));
    } else if (index == 1) { 
      Navigator.pushNamed(context, '/create-post');
    } else if (index == 2) { 
      if (widget.userId != _loggedInUserId) {
        Navigator.pushNamed(context, '/profile');
      } else {
        Navigator.popUntil(context, ModalRoute.withName('/profile'));
      }
    }
  }

  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required Widget child,
    double borderRadius = 20.0,
  }) {
    final ThemeData theme = Theme.of(context);
    final Color gradStart = theme.brightness == Brightness.light 
        ? theme.primaryColor 
        : theme.colorScheme.primary;
    final Color gradEnd = theme.brightness == Brightness.light 
        ? Color.lerp(theme.primaryColor, Colors.black, 0.3)!
        : Color.lerp(theme.colorScheme.primary, Colors.black, 0.4)!;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gradStart, gradEnd],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final ThemeData theme = Theme.of(context);
    final Color pageBackgroundColor = theme.scaffoldBackgroundColor;
    final Color appBarBackgroundColor = theme.appBarTheme.backgroundColor ?? pageBackgroundColor;
    final Color appBarForegroundColor = theme.appBarTheme.titleTextStyle?.color ?? theme.colorScheme.onSurface;
    final IconThemeData appBarIconTheme = theme.appBarTheme.iconTheme ?? IconThemeData(color: appBarForegroundColor);
    final Color primaryColor = theme.primaryColor;
    final Color? textSecondaryColor = theme.textTheme.bodyMedium?.color;

    final displayedPosts = _userPosts.where((post) {
      if (post['situacao'] == 'resolvido') return false;
      return post['situacao'] == _selectedTab;
    }).toList();

    return Scaffold(
      backgroundColor: pageBackgroundColor,
      appBar: AppBar(
        title: Text(nome == 'Carregando...' ? 'Perfil do Usuário' : nome, 
            style: TextStyle(fontWeight: FontWeight.bold, color: appBarForegroundColor)),
        centerTitle: true,
        backgroundColor: appBarBackgroundColor,
        elevation: theme.appBarTheme.elevation ?? 1,
        iconTheme: appBarIconTheme,
        actions: [
          if (_loggedInUserId != null && widget.userId == _loggedInUserId)
            PopupMenuButton<ThemeMode>(
              icon: Icon(Icons.palette_outlined, color: appBarIconTheme.color),
              tooltip: "Mudar Tema",
              onSelected: (ThemeMode mode) {
                themeNotifier.setThemeMode(mode);
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<ThemeMode>>[
                PopupMenuItem<ThemeMode>(
                  value: ThemeMode.light,
                  child: ListTile(
                    leading: Icon(Icons.wb_sunny_outlined),
                    title: Text('Claro'),
                  ),
                ),
                PopupMenuItem<ThemeMode>(
                  value: ThemeMode.dark,
                  child: ListTile(
                    leading: Icon(Icons.nightlight_round),
                    title: Text('Escuro'),
                  ),
                ),
                PopupMenuItem<ThemeMode>(
                  value: ThemeMode.system,
                  child: ListTile(
                    leading: Icon(Icons.settings_brightness_outlined),
                    title: Text('Padrão do Sistema'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _errorMessage != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(16.0), 
                  child: Text('Erro: $_errorMessage', 
                      textAlign: TextAlign.center, 
                      style: TextStyle(color: Colors.red[700]))))
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      color: theme.cardColor,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: theme.hoverColor,
                            backgroundImage: profilePictureUrl.isNotEmpty ? NetworkImage(profilePictureUrl) : null,
                            child: profilePictureUrl.isEmpty 
                                ? Icon(Icons.person, size: 45, color: textSecondaryColor?.withOpacity(0.7)) 
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nome, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                                const SizedBox(height: 4),
                                Text(curso, style: TextStyle(fontSize: 14, color: textSecondaryColor)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_loggedInUserId != null && widget.userId != _loggedInUserId)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: _buildGradientButton(
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
                          borderRadius: 12,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Conversar', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      color: theme.cardColor,
                      child: Row(
                        children: [
                          _buildFilterButton('Perdidos', 'perdido'),
                          const SizedBox(width: 12),
                          _buildFilterButton('Achados', 'achado'),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: theme.dividerColor.withOpacity(0.5)),
                    Expanded(
                      child: displayedPosts.isEmpty
                          ? Center(child: Text(
                              'Nenhum item $_selectedTab para mostrar.',
                              style: TextStyle(color: textSecondaryColor, fontSize: 16)))
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
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _bottomNavCurrentIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }

  Widget _buildFilterButton(String text, String status) {
    final bool isActive = _selectedTab == status;
    final theme = Theme.of(context);

    if (isActive) {
      return Expanded(
        child: _buildGradientButton(
          onPressed: () => setState(() => _selectedTab = status),
          borderRadius: 20.0,
          child: Text(text, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      );
    } else {
      return Expanded(
        child: ElevatedButton(
          onPressed: () => setState(() => _selectedTab = status),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.cardColor.withOpacity(0.8),
            foregroundColor: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: theme.dividerColor.withOpacity(0.5))
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            elevation: 0.5,
          ),
          child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ),
      );
    }
  }

  Widget _buildReadOnlyPostCard({required Map<String, dynamic> post}) {
    final itemName = post['nomeItem'] ?? '';
    final description = post['descricao'] ?? '';
    final date = _formatDate(post['dataOcorrencia'] ?? '');
    final imageUrl = post['fotoUrl'] ?? '';
    final isFound = post['situacao'] == 'achado';
    final isResolved = post['situacao'] == 'resolvido';

    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final titleColor = theme.colorScheme.primary;
    final descriptionColor = theme.textTheme.bodyMedium?.color ?? (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87);
    final dateColor = theme.textTheme.bodySmall?.color ?? Colors.grey[600];
    
    String statusText;
    Color statusTagBackgroundColor;
    Color statusTextColor;

    if (isResolved) {
      statusText = 'RESOLVIDO';
      statusTagBackgroundColor = Colors.blueGrey.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.1);
      statusTextColor = theme.brightness == Brightness.dark ? Colors.blueGrey.shade200 : Colors.blueGrey.shade700;
    } else if (isFound) {
      statusText = 'ACHADO';
      statusTagBackgroundColor = Colors.green.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.1);
      statusTextColor = theme.brightness == Brightness.dark ? Colors.green.shade300 : Colors.green.shade800;
    } else {
      statusText = 'PERDIDO';
      statusTagBackgroundColor = Colors.orange.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.1);
      statusTextColor = theme.brightness == Brightness.dark ? Colors.orange.shade300 : Colors.orange.shade900;
    }
    
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: theme.cardTheme.elevation ?? 2,
      color: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: theme.hoverColor,
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover,
                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                            color: theme.primaryColor,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => 
                          Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 40)),)
                  : Center(child: Icon(Icons.photo_library_outlined, size: 50, color: Colors.grey[400])),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(itemName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor)),
                Container(
                  margin: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusTagBackgroundColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isResolved
                          ? Colors.blueGrey.shade300.withAlpha((0.5 * 255).toInt())
                          : (isFound
                              ? Colors.green.shade300.withAlpha((0.5 * 255).toInt())
                              : Colors.orange.shade300.withAlpha((0.5 * 255).toInt())),
                    ),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusTextColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: descriptionColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text('Data: $date', style: TextStyle(fontSize: 12, color: dateColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}