import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:find_it/service/auth_service.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:find_it/widgets/custom_bottom_navbar.dart'; 

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedStatus;
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _localController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  final int _bottomNavCurrentIndex = 1;

  void _onBottomNavTapped(int index) {
    final currentRouteName = ModalRoute.of(context)?.settings.name;

    if (index == 0) { // Feed
      if (currentRouteName != '/') {
        Navigator.pushReplacementNamed(context, '/');
      }
    } else if (index == 2) { // Perfil
      if (currentRouteName != '/profile') {
        Navigator.pushNamed(context, '/profile');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Postagem', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
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
                        Icon(Icons.help_outline, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        Text('Status (achado/perdido)*', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                    items: ['achado', 'perdido'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value[0].toUpperCase() + value.substring(1)),
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
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _bottomNavCurrentIndex, 
        onTap: _onBottomNavTapped,      
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
      validator: (value) {
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
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
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
    if (!_formKey.currentState!.validate()) return;

    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, adicione uma foto para o item.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Usuário não autenticado');

      var uri = Uri.parse('http://localhost:8080/api/v1/posts');
      var request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['nomeItem'] = _nomeController.text;
      request.fields['descricao'] = _descricaoController.text;
      request.fields['dataOcorrencia'] = _dataController.text;
      request.fields['situacao'] = _selectedStatus!;
      // request.fields['local'] = _localController.text; // Campo local não é enviado

      final mimeType = lookupMimeType(_imageFile!.path) ?? 'application/octet-stream';
      final mediaType = MediaType.parse(mimeType);
      var multipartFile = await http.MultipartFile.fromPath('foto', _imageFile!.path, contentType: mediaType);
      request.files.add(multipartFile);
      
      var response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post criado com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacementNamed(context, '/'); // Leva para o feed após criar
      } else {
        final errorData = json.decode(responseBody);
        throw Exception(errorData['message'] ?? 'Erro ${response.statusCode} ao criar post');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _dataController.dispose();
    _localController.dispose();
    super.dispose();
  }
}