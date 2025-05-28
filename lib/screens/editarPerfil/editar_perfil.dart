import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:find_it/service/auth_service.dart';

class EditarPerfil extends StatefulWidget {
  // Não precisamos mais passar os dados iniciais, pois vamos buscá-los na API.
  const EditarPerfil({Key? key}) : super(key: key);

  @override
  State<EditarPerfil> createState() => _EditarPerfilState();
}

class _EditarPerfilState extends State<EditarPerfil> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores do formulário
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cursoController = TextEditingController();
  final TextEditingController _contatoController = TextEditingController();

  // Estados de controle
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  File? _imageFile;
  String _profilePictureUrl = '';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  // Função para buscar os dados mais recentes do usuário ao abrir a tela
  Future<void> _fetchCurrentUser() async {
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/v1/users/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _nomeController.text = userData['nome'] ?? '';
          _cursoController.text = userData['curso'] ?? '';
          _contatoController.text = userData['telefone'] ?? '';
          _profilePictureUrl = userData['profilePicture'] ?? '';
          _userEmail = userData['email'] ?? 'Email não encontrado';
        });
      } else {
        throw Exception('Falha ao carregar dados do usuário.');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Função para escolher uma nova imagem da galeria
  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
      });
    }
  }

  // Função principal que orquestra o salvamento
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      // Passo 1: Atualiza os dados de texto
      await _updateProfileData();

      // Passo 2: Atualiza a foto de perfil, se uma nova foi escolhida
      if (_imageFile != null) {
        await _updateProfilePicture();
      }

      // Se tudo deu certo, fecha a tela e avisa a tela anterior para recarregar
      if (mounted) {
        Navigator.pop(context, true); 
      }
    } catch (e) {
      // Mostra um diálogo de erro
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: ${e.toString()}'), backgroundColor: Colors.red),
        );
       }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // [API] Atualiza os dados de texto (nome, curso, telefone)
  Future<void> _updateProfileData() async {
    final token = await AuthService.getToken();
    final response = await http.put(
      Uri.parse('http://localhost:8080/api/v1/users/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nome': _nomeController.text,
        'telefone': _contatoController.text,
        'curso': _cursoController.text,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao atualizar dados.');
    }
  }

  // [API] Atualiza a foto de perfil
  Future<void> _updateProfilePicture() async {
    if (_imageFile == null) return;
    
    final token = await AuthService.getToken();
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('http://localhost:8080/api/v1/users/profile/picture'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath(
        'profilePicture',
        _imageFile!.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Falha ao atualizar foto de perfil.');
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cursoController.dispose();
    _contatoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Form(
                key: _formKey,
                child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        // Foto de perfil dinâmica
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey[200],
                                // Mostra a nova imagem, a antiga da URL, ou um ícone
                                backgroundImage: _imageFile != null
                                    ? FileImage(_imageFile!) as ImageProvider
                                    : (_profilePictureUrl.isNotEmpty ? NetworkImage(_profilePictureUrl) : null),
                                child: _imageFile == null && _profilePictureUrl.isEmpty
                                    ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF1D8BC9),
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                                    onPressed: _pickImage,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _pickImage,
                          child: const Text(
                            'Alterar foto',
                            style: TextStyle(color: Color(0xFF1D8BC9), fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Campos do formulário atualizados
                        _buildFormField(controller: _nomeController, label: 'Nome completo', icon: Icons.person_outline),
                        const SizedBox(height: 20),
                        
                        // Campo de E-mail (Apenas leitura)
                        TextFormField(
                          initialValue: _userEmail,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'E-mail (não pode ser alterado)',
                            labelStyle: const TextStyle(color: Colors.grey),
                            prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[400]),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildFormField(controller: _contatoController, label: 'Telefone', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                        const SizedBox(height: 20),
                        _buildFormField(controller: _cursoController, label: 'Curso', icon: Icons.school_outlined),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1D8BC9),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isSaving ? null : _saveChanges,
          child: _isSaving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'SALVAR ALTERAÇÕES',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Este campo não pode ser vazio.';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFF1D8BC9)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1D8BC9), width: 2)),
      ),
    );
  }
}