import 'package:flutter/material.dart';
import 'package:find_it/screens/editarPerfil/editar_perfil.dart';
import 'package:find_it/service/auth_service.dart';
import 'package:find_it/screens/login/Login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

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
  String? _currentUserId; // Para verificar a autoria dos posts

  @override
  void initState() {
    super.initState();
    _carregarDadosDaPagina();
  }

  Future<void> _carregarDadosDaPagina() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Pega o ID do usuário logado primeiro
      _currentUserId = await AuthService.getUserId();
      if (_currentUserId == null) throw Exception('Usuário não autenticado para buscar ID.');
      
      final userData = await _fetchUserData();
      // Usa o _currentUserId que já pegamos, pois userData['_id'] pode ser o do perfil visitado (se fosse o caso)
      // Mas como estamos na tela de perfil do próprio usuário, userData['_id'] é igual a _currentUserId.
      await _fetchUserPosts(_currentUserId!); 
    } catch (e) {
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

  Future<Map<String, dynamic>> _fetchUserData() async {
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
        });
      }
      return responseData;
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
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair', style: TextStyle(color: Colors.red)),
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

  // NOVO: Função para deletar um post
  Future<void> _deleteUserPost(String postId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir este post? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmar != true) return;

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
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post excluído com sucesso!'), backgroundColor: Colors.green));
        _carregarDadosDaPagina(); // Recarrega os posts
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(errorData['message'] ?? 'Erro ao excluir post');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red));
    }
  }

  // NOVO: Função para marcar um post como resolvido
  Future<void> _resolveUserPost(String postId) async {
     final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar como Resolvido'),
        content: const Text('Tem certeza que deseja marcar este item como resolvido? Ele não aparecerá mais no feed principal.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Resolver', style: TextStyle(color: Colors.green))),
        ],
      ),
    );

    if (confirmar != true) return;

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
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post marcado como resolvido!'), backgroundColor: Colors.green));
        _carregarDadosDaPagina(); // Recarrega os posts
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(errorData['message'] ?? 'Erro ao resolver post');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedPosts = _userPosts.where((post) {
      // Se o post estiver resolvido, ele não deve aparecer em 'perdido' ou 'achado'
      if (post['situacao'] == 'resolvido') return false;
      return post['situacao'] == _selectedTab;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: _fazerLogout, tooltip: 'Sair'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Erro: $_errorMessage', textAlign: TextAlign.center)))
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.white,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: profilePictureUrl.isNotEmpty ? NetworkImage(profilePictureUrl) : null,
                            child: profilePictureUrl.isEmpty ? Icon(Icons.person, size: 40, color: Colors.grey[400]) : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1D8BC9))),
                                const SizedBox(height: 4),
                                Text(curso, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                                const SizedBox(height: 4),
                                Text(contato, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.edit, color: Color(0xFF1D8BC9)), onPressed: _navegarParaEdicao),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      color: Colors.white,
                      child: Row(
                        children: [
                          _buildFilterButton('Perdidos', 'perdido'),
                          const SizedBox(width: 12),
                          _buildFilterButton('Achados', 'achado'),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFEFEFEF)),
                    Expanded(
                      child: displayedPosts.isEmpty
                          ? Center(child: Text('Nenhum item $_selectedTab para mostrar.'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: displayedPosts.length,
                              itemBuilder: (context, index) {
                                final post = displayedPosts[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildPostCard(post: post),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: const Color(0xFF1D8BC9),
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/');
          else if (index == 1) Navigator.pushNamed(context, '/create-post');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Novo Post'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String text, String status) {
    final bool isActive = _selectedTab == status;
    return Expanded(
      child: ElevatedButton(
        onPressed: () => setState(() => _selectedTab = status),
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? const Color(0xFF1D8BC9) : Colors.grey[200],
          foregroundColor: isActive ? Colors.white : Colors.grey[700],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: isActive ? 2 : 0,
        ),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  // ALTERADO: _buildPostCard agora inclui um PopupMenuButton para ações
  Widget _buildPostCard({required Map<String, dynamic> post}) {
    final itemName = post['nomeItem'] ?? '';
    final description = post['descricao'] ?? '';
    final date = _formatDate(post['dataOcorrencia'] ?? '');
    final imageUrl = post['fotoUrl'] ?? '';
    final isFound = post['situacao'] == 'achado';
    final isResolved = post['situacao'] == 'resolvido'; // Verifica se o post já está resolvido
    final String postId = post['_id'] ?? '';

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.grey[200],
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image)),)
                  : const Center(child: Icon(Icons.photo, size: 50, color: Colors.grey)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start, // Alinha os itens ao topo
                  children: [
                    Expanded(child: Text(itemName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1D8BC9)))),
                    // NOVO: PopupMenuButton para ações
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onSelected: (value) {
                        if (value == 'resolver') {
                          _resolveUserPost(postId);
                        } else if (value == 'excluir') {
                          _deleteUserPost(postId);
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        if (!isResolved) // Só mostra "Resolver" se não estiver resolvido
                          const PopupMenuItem<String>(
                            value: 'resolver',
                            child: ListTile(leading: Icon(Icons.check_circle_outline, color: Colors.green), title: Text('Marcar como Resolvido')),
                          ),
                        const PopupMenuItem<String>(
                          value: 'excluir',
                          child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Excluir Post')),
                        ),
                      ],
                    ),
                  ],
                ),
                // Adiciona o status do post se ele estiver resolvido
                 if (isResolved)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                      child: Text(
                        'RESOLVIDO',
                        style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    )
                  else // Só mostra o status 'Achado'/'Perdido' se não estiver resolvido
                    Container(
                      margin: const EdgeInsets.only(top: 4.0, bottom: 8.0), // Espaçamento para o status
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isFound ? const Color(0xFF15AF12) : const Color(0xFFFF9900),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isFound ? 'Achado' : 'Perdido',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                // const SizedBox(height: 8), // Removido para usar o margin acima
                Text(description, style: const TextStyle(fontSize: 14, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text('Data: $date', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}