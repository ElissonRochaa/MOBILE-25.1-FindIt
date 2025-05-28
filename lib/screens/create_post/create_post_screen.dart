import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:find_it/service/auth_service.dart';
import 'package:find_it/screens/feed/feed_screen.dart';
import 'package:mime/mime.dart'; // Já estava importado, ótimo!
import 'package:http_parser/http_parser.dart'; // Já estava importado, ótimo!
import 'dart:convert';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>(); // Adicionado para validação de formulário

  String? _selectedStatus;
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _localController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Postagem', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        elevation: 0,
        // Removido automaticallyImplyLeading para evitar conflito se for pushNamed
      ),
      body: Form( // Envolve com um Form para usar o _formKey
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _adicionarFoto,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text('Adicionar foto do item*', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              _buildFormField(controller: _nomeController, label: 'Nome do item', icon: Icons.title, isRequired: true),
              const SizedBox(height: 16),
              _buildFormField(controller: _descricaoController, label: 'Descrição detalhada', icon: Icons.description, maxLines: 4, isRequired: true),
              const SizedBox(height: 16),
              _buildFormField(controller: _localController, label: 'Local onde foi encontrado/perdido', icon: Icons.location_on, isRequired: true),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: _buildFormField(controller: _dataController, label: 'Data da ocorrência', icon: Icons.calendar_today, isRequired: true),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(border: InputBorder.none),
                    hint: Row(
                      children: [
                        Icon(Icons.help_outline, color: Colors.grey[600]), // Ícone alterado para mais genérico
                        const SizedBox(width: 12),
                        Text('Status (achado/perdido)*', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                    items: ['achado', 'perdido'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value[0].toUpperCase() + value.substring(1)), // Capitalizado
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedStatus = newValue;
                      });
                    },
                    validator: (value) => value == null ? 'Selecione um status' : null,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _publicarPostagem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D8BC9),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text('PUBLICAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: const Color(0xFF1D8BC9),
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/profile');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Novo Post'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: '$label${isRequired ? '*' : ''}',
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: const Color(0xFF1D8BC9)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1D8BC9), width: 2),
        ),
      ),
      validator: (value) { // Adicionado validador básico
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Este campo é obrigatório.';
        }
        return null;
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)), // Limita a data futura
    );
    if (picked != null) {
      setState(() {
        // AJUSTE 2: Formato da data para YYYY-MM-DD
        _dataController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _adicionarFoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _publicarPostagem() async {
    // Adicionada validação de formulário e imagem
    if (!_formKey.currentState!.validate()) return;

    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, adicione uma foto para o item.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }


    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      var uri = Uri.parse('http://localhost:8080/api/v1/posts');
      var request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      // request.headers['Accept'] = 'application/json'; // Pode ser removido, Multer lida bem

      // Campos esperados pelo backend
      request.fields['nomeItem'] = _nomeController.text;
      request.fields['descricao'] = _descricaoController.text;
      // AJUSTE 1: Nome do campo da data corrigido para 'dataOcorrencia'
      request.fields['dataOcorrencia'] = _dataController.text; 
      request.fields['situacao'] = _selectedStatus!;
      // AJUSTE 3: Campo 'local' não é enviado para este endpoint,
      // pois o backend não o espera. O campo no formulário pode ser mantido
      // para uso futuro ou removido se não for necessário.
      // request.fields['local'] = _localController.text; 

      // Adiciona a imagem
      final mimeType = lookupMimeType(_imageFile!.path) ?? 'application/octet-stream';
      final mediaType = MediaType.parse(mimeType);

      var multipartFile = await http.MultipartFile.fromPath(
        'foto', // Nome do campo esperado pelo Multer no backend
        _imageFile!.path,
        contentType: mediaType,
      );
      request.files.add(multipartFile);
      

      var response = await request.send();
      final responseBody = await response.stream.bytesToString(); // Ler o corpo para qualquer caso

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement( // Usar pushReplacement para não poder voltar para a tela de criar
          context,
          MaterialPageRoute(builder: (context) => const FeedScreen()),
        );
      } else {
        final errorData = json.decode(responseBody);
        throw Exception(errorData['message'] ?? 'Erro ${response.statusCode} ao criar post');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Removido _validateForm() pois TextFormField já faz a validação com _formKey

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _dataController.dispose();
    _localController.dispose();
    super.dispose();
  }
}