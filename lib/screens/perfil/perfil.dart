import 'package:flutter/material.dart';
import 'package:find_it/screens/editarPerfil/editar_perfil.dart';
import 'package:find_it/service/auth_service.dart';
import 'package:find_it/screens/login/Login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:find_it/widgets/custom_bottom_navbar.dart'; 
import 'package:provider/provider.dart'; // Importa o Provider
import 'package:find_it/service/theme_service.dart'; // Importa seu ThemeNotifier

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

  // Cores para o gradiente do botão de filtro (podem vir do tema se preferir)
  // Estas são usadas no _buildGradientButton, que por sua vez usa cores do tema.
  // Portanto, não são estritamente necessárias aqui se _buildGradientButton for atualizado
  // para pegar as cores do gradiente do ThemeNotifier também, ou usar a cor primária do tema.
  // final Color _gradientStartColor = const Color(0xFF1D8BC9); 
  // final Color _gradientEndColor = const Color(0xFF01121B); 


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
      if (_currentUserId == null) throw Exception('Usuário não autenticado para buscar ID.');
      
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

  String _formatDate(String rawDate) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(rawDate));
    } catch (e) { return rawDate; }
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

  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required Widget child,
    double borderRadius = 20.0,
  }) {
    // Usando cores do tema para o gradiente
    final ThemeData theme = Theme.of(context);
    // Para o tema claro, usa o azul primário e uma variação escura.
    // Para o tema escuro, usa o azul claro de acento e uma variação mais escura dele.
    final Color gradStart = theme.brightness == Brightness.light 
        ? theme.primaryColor 
        : theme.colorScheme.primary; // Que é Colors.blue[300] no tema escuro
    final Color gradEnd = theme.brightness == Brightness.light 
        ? Color.lerp(theme.primaryColor, Colors.black, 0.3)!
        : Color.lerp(theme.colorScheme.primary, Colors.black, 0.4)!; // Escurece o azul de acento

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
      // Lógica de filtro original: não mostra resolvidos nas abas 'perdido' ou 'achado'
      if (_selectedTab == 'perdido' && post['situacao'] != 'perdido') return false;
      if (_selectedTab == 'achado' && post['situacao'] != 'achado') return false;
      // Se a aba for 'resolvido', mostra apenas os resolvidos
      if (_selectedTab == 'resolvido' && post['situacao'] != 'resolvido') return false;
      // Se não for a aba 'resolvido', e o post estiver resolvido, não mostra
      if (_selectedTab != 'resolvido' && post['situacao'] == 'resolvido') return false;

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: pageBackgroundColor,
      appBar: AppBar(
        title: Text('Perfil', style: TextStyle(fontWeight: FontWeight.bold, color: appBarForegroundColor)),
        centerTitle: true,
        backgroundColor: appBarBackgroundColor,
        elevation: theme.appBarTheme.elevation ?? 0,
        iconTheme: appBarIconTheme,
        actions: [
          // BOTÃO DE SELEÇÃO DE TEMA ADICIONADO AQUI
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
              : Container(
                  color: pageBackgroundColor,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: theme.hoverColor,
                              backgroundImage: profilePictureUrl.isNotEmpty ? NetworkImage(profilePictureUrl) : null,
                              child: profilePictureUrl.isEmpty ? Icon(Icons.person, size: 45, color: textSecondaryColor?.withOpacity(0.7)) : null,
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(nome, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
                                  const SizedBox(height: 6),
                                  Text(curso, style: TextStyle(fontSize: 15, color: textSecondaryColor)),
                                  const SizedBox(height: 4),
                                  Text(contato, style: TextStyle(fontSize: 15, color: textSecondaryColor)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit_outlined, color: primaryColor),
                              onPressed: _navegarParaEdicao,
                              tooltip: 'Editar Perfil',
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            _buildFilterButton('Perdidos', 'perdido'),
                            const SizedBox(width: 12),
                            _buildFilterButton('Achados', 'achado'),
                            const SizedBox(width: 12),
                            _buildFilterButton('Resolvidos', 'resolvido'), // Botão para resolvidos
                          ],
                        ),
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
                                    child: _buildPostCard(post: post),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
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
          borderRadius: 25.0,
          child: Text(text, style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600)),
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
              borderRadius: BorderRadius.circular(25),
              side: BorderSide(color: theme.dividerColor.withOpacity(0.5))
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            elevation: 0.5,
          ),
          child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ),
      );
    }
  }

  Widget _buildPostCard({required Map<String, dynamic> post}) {
    final itemName = post['nomeItem'] ?? '';
    final description = post['descricao'] ?? '';
    final date = _formatDate(post['dataOcorrencia'] ?? '');
    final imageUrl = post['fotoUrl'] ?? '';
    final isFound = post['situacao'] == 'achado';
    final isResolved = post['situacao'] == 'resolvido';
    final String postId = post['_id'] ?? '';
    final String postAuthorId = post['autor']?['_id']?.toString() ?? '';
    final bool isCurrentUserPost = (_currentUserId != null && postAuthorId == _currentUserId);

    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final titleColor = theme.colorScheme.primary;
    final descriptionColor = theme.textTheme.bodyMedium?.color ?? (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87);
    final dateColor = theme.textTheme.bodySmall?.color ?? Colors.grey[600];
    final iconMoreColor = (theme.iconTheme.color ?? (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black54)).withOpacity(0.7);
    
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 40)),)
                  : Center(child: Icon(Icons.photo_library_outlined, size: 50, color: Colors.grey[400])),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        itemName,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: titleColor)
                      )
                    ),
                    if (isCurrentUserPost)
                      SizedBox(
                        width: 40,
                        height: 30,
                        child: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: iconMoreColor, size: 22),
                          tooltip: "Opções",
                          onSelected: (value) {
                            if (value == 'resolver') _resolveUserPost(postId);
                            else if (value == 'excluir') _deleteUserPost(postId);
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            if (!isResolved)
                              PopupMenuItem<String>(
                                value: 'resolver',
                                child: Row(children: [Icon(Icons.check_circle_outline, color: Colors.green.shade600), const SizedBox(width: 8), const Text('Resolvido')]),
                              ),
                            PopupMenuItem<String>(
                              value: 'excluir',
                              child: Row(children: [Icon(Icons.delete_outline, color: Colors.redAccent.shade100), const SizedBox(width: 8), const Text('Excluir')]),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusTagBackgroundColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isResolved 
                             ? Colors.blueGrey.shade300.withOpacity(0.5)
                             : (isFound ? Colors.green.shade300.withOpacity(0.5) : Colors.orange.shade300.withOpacity(0.5))
                    )
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusTextColor, fontWeight: FontWeight.bold, fontSize: 11)
                  ),
                ),
                Text(description, style: TextStyle(fontSize: 14, color: descriptionColor, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Text('Data: $date', style: TextStyle(fontSize: 12, color: dateColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}