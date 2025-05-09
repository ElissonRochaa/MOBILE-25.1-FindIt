import 'package:flutter/material.dart';
import '../widgets/custom_bottom_navbar.dart';

class PostDetail extends StatelessWidget {
  final String itemName;
  final String description;
  final String userName;
  final String date;
  final bool isFound;
  final String imageUrl;

  const PostDetail({
    Key? key,
    required this.itemName,
    required this.description,
    required this.userName,
    required this.date,
    required this.isFound,
    this.imageUrl = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Post'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem do post
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                image: imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl.isEmpty
                  ? const Icon(Icons.photo, size: 60, color: Colors.white)
                  : null,
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome do item
                  Text(
                    itemName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D8BC9),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Seção usuário + descrição
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Foto e nome do usuário
                        Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[400],
                              ),
                              child: const Icon(Icons.person, size: 30, color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              userName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Descrição e data
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                description,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                date,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Status (Achado/Perdido)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isFound ? const Color(0xFF15AF12) : const Color(0xFFFF9900),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isFound ? 'Achado' : 'Perdido',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Seção de comentários
                  const Text(
                    'Comentários',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Lista de comentários
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 3, // Número de comentários de exemplo
                    itemBuilder: (context, index) {
                      return _buildComment(
                        userName: 'Usuário ${index + 1}',
                        comment: 'Este é um comentário de exemplo sobre o post.',
                        time: '${index + 1}h atrás',
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Campo para novo comentário
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Adicione um comentário...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFF1D8BC9)),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      
      // Barra de navegação inferior
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0, // Índice da home
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/feed');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/create-post');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/profile');
          }
        },
      ),
    );
  }

  Widget _buildComment({
    required String userName,
    required String comment,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                ),
                child: const Icon(Icons.person, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                time,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(comment),
        ],
      ),
    );
  }
}