import 'package:flutter/material.dart';
import '../widgets/custom_bottom_navbar.dart';

class Feed extends StatefulWidget {
  const Feed({Key? key}) : super(key: key);

  @override
  State<Feed> createState() => _FeedState();
}

class _FeedState extends State<Feed> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Feed',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1D8BC9),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1D8BC9),
          tabs: const [
            Tab(text: 'Feed'),
            Tab(text: 'Notificações'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barra de pesquisa
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  hintText: 'Pesquisar',
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          
          // Conteúdo das abas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab Feed
                ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    final isFound = index % 2 == 0;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/post-detail',
                          arguments: {
                            'itemName': 'Nome do Item $index',
                            'description': 'Descrição detalhada do item $index. Aqui vai uma descrição mais longa sobre o item perdido ou encontrado.',
                            'userName': 'Usuário $index',
                            'date': '${index + 10}/05/2023',
                            'isFound': isFound,
                          },
                        );
                      },
                      child: _buildPostCard(isFound: isFound, index: index),
                    );
                  },
                ),
                
                // Tab Notificações
                const Center(
                  child: Text('Nenhuma notificação no momento'),
                ),
              ],
            ),
          ),
        ],
      ),
      
      // Barra de navegação inferior
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/create-post');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/perfil');
          }
        },
      ),
    );
  }

  Widget _buildPostCard({required bool isFound, required int index}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFD9D9D9),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto e descrição
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto do item
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo, size: 40, color: Colors.white),
                ),
                
                const SizedBox(width: 12),
                
                // Descrição
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nome do Item $index',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D8BC9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Descrição resumida do item. Aqui vai um texto mais curto sobre o item.',
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Informações do post
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Por: Usuário $index',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
                Text(
                  '${index + 10}/05/2023',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Status (Achado/Perdido)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
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
            ),
          ],
        ),
      ),
    );
  }
}