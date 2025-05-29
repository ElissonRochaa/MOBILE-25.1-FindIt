import 'package:flutter/material.dart';
import 'package:find_it/screens/editarPerfil/editar_perfil.dart';
import 'package:find_it/service/auth_service.dart';
import 'package:find_it/screens/login/Login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:find_it/widgets/custom_bottom_navbar.dart'; 

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

  final int _bottomNavCurrentIndex = 2;

  final Color _gradientStartColor = const Color(0xFF1D8BC9);
  final Color _gradientEndColor = const Color(0xFF01121B);
  final Color _pageBackgroundColor = const Color(0xffEFEFEF); 

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

    if (response.statusCode == 200) {
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      if (mounted) {
        setState(() {
          nome = responseData['nome'] ?? 'Nome não informado';
          curso = responseData['curso'] ?? 'Curso não informado';
          contato = responseData['telefone'] ?? 'Contato não informado';
          profilePictureUrl = responseData['profilePicture'] ?? '';
          _currentUserId = responseData['_id'] ?? _currentUserId;
        });
      }
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

    if (response.statusCode == 200) {
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      if (mounted) {
        setState(() {
          _userPosts = responseData;
        });
      }
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
    if (resultado == true) {
      _carregarDadosDaPagina();
    }
  }

  Future<void> _fazerLogout() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Sair da Conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair', style: TextStyle(color: Colors.redAccent)),
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
    } catch (e) {
      return rawDate;
    }
  }

  Future<void> _deleteUserPost(String postId) async {
     final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir este post? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Excluir', style: TextStyle(color: Colors.redAccent))),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Marcar como Resolvido'),
        content: const Text('Tem certeza que deseja marcar este item como resolvido? Ele não aparecerá mais no feed principal.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Resolver', style: TextStyle(color: Colors.green))),
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
      if (currentRouteName != '/feed') {
        Navigator.pushReplacementNamed(context, '/feed');
      }
    } else if (index == 1) {
      if (currentRouteName != '/create-post') {
        Navigator.pushNamed(context, '/create-post');
      }
    }
  }

  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required Widget child,
    double borderRadius = 20.0, 
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero, 
        backgroundColor: Colors.transparent, 
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: Ink( 
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_gradientStartColor, _gradientEndColor],
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
    final displayedPosts = _userPosts.where((post) {
      if (post['situacao'] == 'resolvido') return false;
      return post['situacao'] == _selectedTab;
    }).toList();

    return Scaffold(
       backgroundColor: _pageBackgroundColor, 
      appBar: AppBar(
        title: const Text('Perfil', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)), 
        centerTitle: true,
        backgroundColor: _pageBackgroundColor, 
        elevation: 0, 
        iconTheme: const IconThemeData(color: Colors.black87), 
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.redAccent), onPressed: _fazerLogout, tooltip: 'Sair'),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
          : _errorMessage != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Erro: $_errorMessage', textAlign: TextAlign.center, style: TextStyle(color: Colors.red[700]))))
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      color: _pageBackgroundColor, 
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[300], 
                            backgroundImage: profilePictureUrl.isNotEmpty ? NetworkImage(profilePictureUrl) : null,
                            child: profilePictureUrl.isEmpty ? Icon(Icons.person, size: 45, color: Colors.grey[500]) : null,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nome, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark)),
                                const SizedBox(height: 6),
                                Text(curso, style: TextStyle(fontSize: 15, color: Colors.grey[700])),
                                const SizedBox(height: 4),
                                Text(contato, style: TextStyle(fontSize: 15, color: Colors.grey[700])),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit_outlined, color: Theme.of(context).primaryColor), 
                            onPressed: _navegarParaEdicao,
                            tooltip: 'Editar Perfil',
                          ),
                        ],
                      ),
                    ),
           
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      color: _pageBackgroundColor, 
                      child: Row(
                        children: [
                          _buildFilterButton('Perdidos', 'perdido'),
                          const SizedBox(width: 12),
                          _buildFilterButton('Achados', 'achado'),
                        ],
                      ),
                    ),
                  
                    Expanded(
                      child: Container( 
                        color: _pageBackgroundColor,
                        child: displayedPosts.isEmpty
                            ? Center(child: Text('Nenhum item $_selectedTab para mostrar.', style: TextStyle(color: Colors.grey[600], fontSize: 16)))
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
                                itemCount: displayedPosts.length,
                                itemBuilder: (context, index) {
                                  final post = displayedPosts[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _buildPostCard(post: post),
                                  );
                                },
                              ),
                      )
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
            backgroundColor: Colors.white,
            foregroundColor: Colors.grey[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
              side: BorderSide(color: Colors.grey[300]!) 
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            elevation: 1, 
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

    return Card(
      clipBehavior: Clip.antiAlias, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
      elevation: 3,
      color: Colors.white, 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.grey[200],
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover,
                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40)),)
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
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark)
                      )
                    ),
                    if (isCurrentUserPost)
                      SizedBox( 
                        width: 40,
                        height: 30,
                        child: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
                          tooltip: "Opções",
                          onSelected: (value) {
                            if (value == 'resolver') {
                              _resolveUserPost(postId);
                            } else if (value == 'excluir') {
                              _deleteUserPost(postId);
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            if (!isResolved)
                              const PopupMenuItem<String>(
                                value: 'resolver',
                                child: Row(children: [Icon(Icons.check_circle_outline, color: Colors.green), SizedBox(width: 8), Text('Resolvido')]),
                              ),
                            const PopupMenuItem<String>(
                              value: 'excluir',
                              child: Row(children: [Icon(Icons.delete_outline, color: Colors.redAccent), SizedBox(width: 8), Text('Excluir')]),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6), // Espaçamento ajustado
                 if (isResolved)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.green.shade300)
                      ),
                      child: Text(
                        'RESOLVIDO', 
                        style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 11)
                      ),
                    )
                  else
                    Container(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isFound ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                         border: Border.all(color: isFound ? Colors.green.shade300 : Colors.orange.shade300)
                      ),
                      child: Text(
                        isFound ? 'ACHADO' : 'PERDIDO',
                        style: TextStyle(
                          color: isFound ? Colors.green[800] : Colors.orange[900], 
                          fontWeight: FontWeight.bold, fontSize: 11
                        ),
                      ),
                    ),
                Text(description, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Text('Data: $date', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}