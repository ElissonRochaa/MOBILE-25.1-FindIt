import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

import 'package:find_it/widgets/user_profile_header.dart';
import 'package:find_it/widgets/post_filter_tabs.dart';
import 'package:find_it/widgets/post_card.dart';
import 'package:find_it/service/auth_service.dart';
import 'package:find_it/screens/chat/chat_screen.dart';
import 'package:find_it/widgets/custom_bottom_navbar.dart';
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

  // O índice do BottomNavBar para a tela de Perfil é 2.
  // Vamos usar 3 ou qualquer outro número se não for uma das telas principais.
  final int _bottomNavCurrentIndex = 2;

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
    // ... sua lógica de carregar dados permanece a mesma ...
  }

  Future<void> _fetchUserData(String userIdToFetch) async {
    // ... sua lógica de carregar dados permanece a mesma ...
  }

  Future<void> _fetchUserPosts(String userIdToFetch) async {
    // ... sua lógica de carregar dados permanece a mesma ...
  }

  // NAVEGAÇÃO: Lógica restaurada para o Navigator padrão do Flutter.
  void _onBottomNavTapped(int index) {
    // Definimos as rotas principais
    const feedRoute = '/feed';
    const createPostRoute = '/create-post';
    const profileRoute = '/profile';

    // Evita reconstruir a tela se já estivermos nela
    if (index == 2 && widget.userId == _loggedInUserId) return;

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
    // ... seu método build permanece o mesmo, ele já está correto e refatorado.
    // O código abaixo é uma cópia do que você já tem, que está ótimo.

    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final ThemeData theme = Theme.of(context);
    final Color pageBackgroundColor = theme.scaffoldBackgroundColor;
    final Color appBarBackgroundColor = theme.appBarTheme.backgroundColor ?? pageBackgroundColor;
    final Color appBarForegroundColor = theme.appBarTheme.titleTextStyle?.color ?? theme.colorScheme.onSurface;
    final IconThemeData appBarIconTheme = theme.appBarTheme.iconTheme ?? IconThemeData(color: appBarForegroundColor);

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
                PopupMenuItem<ThemeMode>(value: ThemeMode.light, child: ListTile(leading: Icon(Icons.wb_sunny_outlined), title: Text('Claro'))),
                PopupMenuItem<ThemeMode>(value: ThemeMode.dark, child: ListTile(leading: Icon(Icons.nightlight_round), title: Text('Escuro'))),
                PopupMenuItem<ThemeMode>(value: ThemeMode.system, child: ListTile(leading: Icon(Icons.settings_brightness_outlined), title: Text('Padrão do Sistema'))),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : _errorMessage != null
          ? Center(child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Erro: $_errorMessage', textAlign: TextAlign.center, style: TextStyle(color: Colors.red[700]))))
          : Column(
        children: [
          UserProfileHeader(
            profilePictureUrl: profilePictureUrl,
            nome: nome,
            curso: curso,
            isMyProfile: _loggedInUserId == widget.userId,
            onChatPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => ChatScreen(
                  recipientId: widget.userId,
                  recipientName: nome,
                  recipientProfilePic: profilePictureUrl,
                ),
              ),
              );
            },
          ),
          PostFilterTabs(
            selectedTab: _selectedTab,
            onTabSelected: (newTab) {
              setState(() {
                _selectedTab = newTab;
              });
            },
          ),
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.5)),
          Expanded(
            child: displayedPosts.isEmpty
                ? Center(child: Text(
                'Nenhum item $_selectedTab para mostrar.',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 16)))
                : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: displayedPosts.length,
              itemBuilder: (context, index) {
                return PostCard(post: displayedPosts[index]);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        // Ajustado para que o ícone de Perfil fique ativo nesta tela
        currentIndex: 2,
        onTap: _onBottomNavTapped,
      ),
    );
  }
}