// lib/screens/perfil/meus_posts.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:find_it/service/auth_service.dart'; 

class MeusPosts extends StatefulWidget {
  final String tipo; // "perdido" ou "achado"

  const MeusPosts({super.key, required this.tipo});

  @override
  State<MeusPosts> createState() => _MeusPostsState();
}

class _MeusPostsState extends State<MeusPosts> {
  List<dynamic> posts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    carregarPosts();
  }

Future<void> carregarPosts() async {
  final userId = await AuthService.getUserId(); // <- OBTER ID

  if (userId == null || userId.isEmpty) {
    debugPrint('ID do usuário não encontrado.');
    setState(() => loading = false);
    return;
  }

  final url = Uri.parse('http://localhost:8080/api/v1/posts/$userId'); // <- USAR ID
  final response = await http.get(url, headers: {
    'Content-Type': 'application/json',
  });

  if (response.statusCode == 200) {
    final List data = json.decode(response.body);
    final filtrados = data.where((post) => post['situacao'] == widget.tipo).toList();

    setState(() {
      posts = filtrados;
      loading = false;
    });
  } else {
    setState(() => loading = false);
    debugPrint('Erro ao carregar posts: ${response.body}');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tipo == 'perdido' ? 'Meus Itens Perdidos' : 'Meus Itens Achados'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : posts.isEmpty
              ? const Center(child: Text('Nenhum post encontrado.'))
              : ListView.builder(
                  itemCount: posts.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _buildPostCard(
                      itemName: post['titulo'] ?? '',
                      description: post['descricao'] ?? '',
                      date: post['createdAt']?.substring(0, 10) ?? '',
                      imageUrl: post['fotoUrl'] ?? '', // ou campo correspondente
                      isFound: post['situacao'] == 'achado',
                    );
                  },
                ),
    );
  }

  Widget _buildPostCard({
    required String itemName,
    required String description,
    required String date,
    required String imageUrl,
    required bool isFound,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 150,
              color: Colors.grey[200],
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.photo, size: 50, color: Colors.grey)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        itemName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D8BC9),
                        ),
                      ),
                    ),
                    Container(
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
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  'Data: $date',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
