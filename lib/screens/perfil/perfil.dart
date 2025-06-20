import 'package:flutter/material.dart';
import 'package:find_it/screens/editarPerfil/editar_perfil.dart';
import 'package:find_it/service/auth_service.dart';
import 'package:find_it/screens/login/Login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // <--- IMPORTANTE: Adicione esta linha!
import 'package:find_it/widgets/custom_bottom_navbar.dart';
import 'package:provider/provider.dart';
import 'package:find_it/service/theme_service.dart';

// Importa os novos componentes
import 'package:find_it/widgets/user_profile_header.dart';
import 'package:find_it/widgets/post_filter_buttons.dart';
import 'package:find_it/widgets/user_post_card.dart';

class Perfil extends StatefulWidget {
  const Perfil({super.key});

  @override
  State<Perfil> createState() => _PerfilState();
}

class _PerfilState extends State<Perfil> {
  String nome = 'Carregando...';
  String curso = 'Carregando...';
  String contato = 'Carregando...';
  String profilePictureUrl = '';
  List<dynamic> _userPosts = [];
  String _selectedTab = 'perdido';
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentUserId;

  final int _bottomNavCurrentIndex = 2; // Perfil é o índice 2

  @override
  void initState() {
    super.initState();
    _carregarDadosDaPagina();
  }

  Future<void> _carregarDadosDaPagina() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _currentUserId = await AuthService.getUserId();
      if (_currentUserId == null) {
        throw Exception('Usuário não autenticado para buscar ID.');
      }

      await _fetchUserData();
      await _fetchUserPosts(_currentUserId!);
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

  Future<void> _fetchUserData() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Usuário não autenticado');

    final response = await http.get(
      Uri.parse('http://localhost:8080/api/v1/users/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (!mounted) return;
    if (response.statusCode == 200) {
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      setState(() {
        nome = responseData['nome'] ?? 'Nome não informado';
        curso = responseData['curso'] ?? 'Curso não informado';
        contato = responseData['telefone'] ?? 'Contato não informado';
        profilePictureUrl = responseData['profilePicture'] ?? '';
        _currentUserId = responseData['_id'] ?? _currentUserId;
      });
    } else {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['message'] ?? 'Erro ao carregar dados do usuário');
    }
  }

  Future<void> _fetchUserPosts(String userId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Usuário não autenticado');

    final response = await http.get(
      Uri.parse('http://localhost:8080/api/v1/posts/user/$userId'),
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

  void _navegarParaEdicao() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditarPerfil()),
    );
    if (resultado == true && mounted) {
      _carregarDadosDaPagina();
    }
  }

  Future<void> _fazerLogout() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da Conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sair', style: TextStyle(color: Colors.redAccent.shade100)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final token = await AuthService.getToken();
      if (token != null) {
        try {
          await http.post(
            Uri.parse('http://localhost:8080/api/v1/auth/signout'),
            headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          );
        } catch (e) {
          print('Erro de conexão ao tentar fazer logout no backend: $e');
        }
      }
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _deleteUserPost(String postId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: Theme.of(context).dialogTheme.shape,
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir este post? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancelar', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Excluir', style: TextStyle(color: Colors.redAccent.shade100))),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    final token = await AuthService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro: Usuário não autenticado.')));
      return;
    }
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:8080/api/v1/posts/$postId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post excluído com sucesso!'), backgroundColor: Colors.green));
        _carregarDadosDaPagina();
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(errorData['message'] ?? 'Erro ao excluir post');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red));
    }
  }

  Future<void> _resolveUserPost(String postId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: Theme.of(context).dialogTheme.shape,
        title: const Text('Marcar como Resolvido'),
        content: const Text('Tem certeza que deseja marcar este item como resolvido? Ele não aparecerá mais no feed principal.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancelar', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Resolver', style: TextStyle(color: Colors.green.shade600))),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    final token = await AuthService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro: Usuário não autenticado.')));
      return;
    }
    try {
      final response = await http.patch(
        Uri.parse('http://localhost:8080/api/v1/posts/$postId/resolve'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post marcado como resolvido!'), backgroundColor: Colors.green));
        _carregarDadosDaPagina();
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(errorData['message'] ?? 'Erro ao resolver post');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red));
    }
  }

  void _onBottomNavTapped(int index) {
    final currentRouteName = ModalRoute.of(context)?.settings.name;
    if (index == 0) {
      if (currentRouteName != '/feed') Navigator.pushReplacementNamed(context, '/feed');
    } else if (index == 1) {
      if (currentRouteName != '/create-post') Navigator.pushNamed(context, '/create-post');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final ThemeData theme = Theme.of(context);
    final Color pageBackgroundColor = theme.scaffoldBackgroundColor;
    final Color appBarForegroundColor = theme.appBarTheme.titleTextStyle?.color ?? theme.colorScheme.onSurface;
    final IconThemeData appBarIconTheme = theme.appBarTheme.iconTheme ?? IconThemeData(color: appBarForegroundColor);
    final Color primaryColor = theme.primaryColor;
    final Color? textSecondaryColor = theme.textTheme.bodyMedium?.color;

    final displayedPosts = _userPosts.where((post) {
      if (_selectedTab == 'perdido' && post['situacao'] != 'perdido') return false;
      if (_selectedTab == 'achado' && post['situacao'] != 'achado') return false;
      if (_selectedTab == 'resolvido' && post['situacao'] != 'resolvido') return false;
      if (_selectedTab != 'resolvido' && post['situacao'] == 'resolvido') return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: pageBackgroundColor,
      appBar: AppBar(
        title: Text('Perfil', style: TextStyle(fontWeight: FontWeight.bold, color: appBarForegroundColor)),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation ?? 0,
        iconTheme: appBarIconTheme,
        actions: [
          PopupMenuButton<ThemeMode>(
            icon: Icon(Icons.palette_outlined, color: appBarIconTheme.color),
            tooltip: "Mudar Tema",
            onSelected: (ThemeMode mode) {
              themeNotifier.setThemeMode(mode);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<ThemeMode>>[
              const PopupMenuItem<ThemeMode>(
                value: ThemeMode.light,
                child: ListTile(leading: Icon(Icons.wb_sunny_outlined), title: Text('Claro')),
              ),
              const PopupMenuItem<ThemeMode>(
                value: ThemeMode.dark,
                child: ListTile(leading: Icon(Icons.nightlight_round), title: Text('Escuro')),
              ),
              const PopupMenuItem<ThemeMode>(
                value: ThemeMode.system,
                child: ListTile(leading: Icon(Icons.settings_brightness_outlined), title: Text('Padrão do Sistema')),
              ),
            ],
          ),
          IconButton(icon: Icon(Icons.logout, color: Colors.redAccent.shade200), onPressed: _fazerLogout, tooltip: 'Sair'),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _errorMessage != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Erro: $_errorMessage', textAlign: TextAlign.center, style: TextStyle(color: Colors.red[700]))))
              : Column(
                  children: [
                    UserProfileHeader(
                      nome: nome,
                      curso: curso,
                      contato: contato,
                      profilePictureUrl: profilePictureUrl,
                      onEditPressed: _navegarParaEdicao,
                    ),
                    PostFilterButtons(
                      selectedTab: _selectedTab,
                      onTabSelected: (tab) => setState(() => _selectedTab = tab),
                    ),
                    Divider(height: 1, color: theme.dividerColor.withOpacity(0.5)),
                    Expanded(
                      child: displayedPosts.isEmpty
                          ? Center(child: Text(
                              _isLoading ? 'Carregando posts...' : 'Nenhum item para mostrar nesta categoria.',
                              style: TextStyle(color: textSecondaryColor, fontSize: 16)
                            ))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: displayedPosts.length,
                              itemBuilder: (context, index) {
                                final post = displayedPosts[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: UserPostCard(
                                    post: post,
                                    currentUserId: _currentUserId,
                                    onDelete: _deleteUserPost,
                                    onResolve: _resolveUserPost,
                                    // Passando a função _formatDate para o UserPostCard
                                    formatDate: (rawDate) {
                                      try {
                                        return DateFormat('dd/MM/yyyy').format(DateTime.parse(rawDate));
                                      } catch (e) {
                                        return rawDate;
                                      }
                                    },
                                  ),
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
}