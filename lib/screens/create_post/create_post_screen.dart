import 'package:flutter/material.dart';
import '../../widgets/custom_bottom_navbar.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  String? _selectedStatus;
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();

  int _currentIndex = 1; // Índice para controlar a navbar

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nova postagem',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Container para adicionar foto
            GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Adicionar foto', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Campo Nome do Item
            _buildInputField(
              icon: Icons.title,
              placeholder: 'Nome do item',
              controller: _nomeController,
            ),
            
            const SizedBox(height: 16),
            
            // Campo Descrição (corrigido o alinhamento)
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start, // Alinhamento corrigido
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0), // Ajuste para alinhar com o texto
                    child: Icon(Icons.description, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _descricaoController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Descrição',
                        contentPadding: EdgeInsets.only(top: 16, bottom: 16), // Padding ajustado
                      ),
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Campo Data
            _buildInputField(
              icon: Icons.calendar_today,
              placeholder: 'Data',
              controller: _dataController,
              onTap: () => _selectDate(context),
            ),
            
            const SizedBox(height: 16),
            
            // Dropdown Achado/Perdido
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.find_in_page, color: Colors.grey),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Achado ou Perdido',
                        contentPadding: EdgeInsets.only(bottom: 4), // Ajuste de alinhamento
                      ),
                      items: ['Achado', 'Perdido'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedStatus = newValue;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Botão Publicar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D8BC9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Publicar'),
              ),
            ),
          ],
        ),
      ),
      
      // Barra de navegação inferior
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/profile');
          }
        },
      ),
      
      // Botão flutuante central (já incluso na navbar)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildInputField({
    required IconData icon,
    required String placeholder,
    required TextEditingController controller,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: placeholder,
                contentPadding: const EdgeInsets.only(bottom: 4), // Ajuste de alinhamento
              ),
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dataController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _dataController.dispose();
    super.dispose();
  }
}