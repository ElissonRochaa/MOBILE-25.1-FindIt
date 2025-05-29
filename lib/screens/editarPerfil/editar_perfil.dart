import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:find_it/service/auth_service.dart';
import 'package:mime/mime.dart';

class EditarPerfil extends StatefulWidget {
  const EditarPerfil({Key? key}) : super(key: key);

  @override
  State<EditarPerfil> createState() => _EditarPerfilState();
}

class _EditarPerfilState extends State<EditarPerfil> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cursoController = TextEditingController();
  final TextEditingController _contatoController = TextEditingController();

  final FocusNode _nomeFocusNode = FocusNode();
  final FocusNode _cursoFocusNode = FocusNode();
  final FocusNode _contatoFocusNode = FocusNode();

  bool _isNomeFocused = false;
  bool _isCursoFocused = false;
  bool _isContatoFocused = false;
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  File? _imageFile;
  String _profilePictureUrl = '';
  String _userEmail = 'Carregando...';

  final Color _focusColor = const Color(0xFF1D8BC9);
  final Color _gradientStartColor = const Color(0xFF1D8BC9);
  final Color _gradientEndColor = const Color(0xFF01121B);
  final Color _pageBackgroundColor = const Color(0xffEFEFEF); // Cor de fundo padrão

  @override
  void initState() {
    super.initState();
    _nomeFocusNode.addListener(() {
      if(mounted) setState(() => _isNomeFocused = _nomeFocusNode.hasFocus);
    });
    _cursoFocusNode.addListener(() {
      if(mounted) setState(() => _isCursoFocused = _cursoFocusNode.hasFocus);
    });
    _contatoFocusNode.addListener(() {
      if(mounted) setState(() => _isContatoFocused = _contatoFocusNode.hasFocus);
    });
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Usuário não autenticado');

      final response = await http.get(
        Uri.parse('http://localhost:8080/api/v1/users/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;
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
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(errorData['message'] ?? 'Falha ao carregar dados do usuário.');
      }
    } catch (e) {
       if (!mounted) return;
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    if (!mounted) return;
    setState(() => _isSaving = true);

    try {
      await _updateProfileData();
      if (_imageFile != null) {
        await _updateProfilePicture();
      }
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); 
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
        );
       }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _updateProfileData() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Usuário não autenticado');
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
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['message'] ?? 'Falha ao atualizar dados.');
    }
  }

  Future<void> _updateProfilePicture() async {
    if (_imageFile == null) return;
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Usuário não autenticado');
    
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('http://localhost:8080/api/v1/users/profile/picture'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    
    final mimeType = lookupMimeType(_imageFile!.path) ?? 'image/jpeg';
    request.files.add(
      await http.MultipartFile.fromPath(
        'profilePicture',
        _imageFile!.path,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final response = await request.send();
    if (response.statusCode != 200) {
      final responseBody = await response.stream.bytesToString();
      final errorData = jsonDecode(responseBody);
      throw Exception(errorData['message'] ?? 'Falha ao atualizar foto de perfil.');
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cursoController.dispose();
    _contatoController.dispose();
    _nomeFocusNode.dispose();
    _cursoFocusNode.dispose();
    _contatoFocusNode.dispose();
    super.dispose();
  }
  
  InputDecoration _buildStandardInputDecoration({
    required String labelText,
    required IconData iconData,
    required bool isFocused,
    bool readOnly = false,
  }) {
    final Color iconColor = isFocused ? _focusColor : (readOnly ? Colors.grey.shade500 : Colors.grey[600]!);
    final Color effectiveFillColor = readOnly 
        ? Colors.grey.shade100 
        : (isFocused ? _focusColor.withOpacity(0.1) : Colors.transparent);
    final Color enabledBorderColor = readOnly ? Colors.grey.shade300 : Colors.grey.shade400;

    return InputDecoration(
      filled: true,
      fillColor: effectiveFillColor,
      labelText: labelText,
      labelStyle: TextStyle(color: readOnly ? Colors.grey.shade700 : Colors.grey[600], fontSize: 18),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 20, right: 12),
        child: Icon(iconData, color: iconColor, size: 24),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: enabledBorderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: enabledBorderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: _focusColor, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
         borderRadius: BorderRadius.circular(30),
         borderSide: const BorderSide(color: Colors.red, width: 2.0),
      ),
    );
  }

  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required Widget child,
    bool isLoading = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero, 
        backgroundColor: Colors.transparent, 
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), 
        ),
      ),
      child: Ink( 
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_gradientStartColor, _gradientEndColor],
            begin: Alignment.centerLeft, 
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16), 
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                )
              : child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // MUDANÇA: Cor de fundo do Scaffold
      backgroundColor: _pageBackgroundColor,
      appBar: AppBar(
        title: const Text('Editar Perfil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
        centerTitle: true,
        // MUDANÇA: Cor de fundo e elevação do AppBar
        backgroundColor: _pageBackgroundColor, 
        elevation: 0, // Sem sombra para integrar com o fundo
        iconTheme: const IconThemeData(color: Colors.black87), 
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _focusColor))
          : _errorMessage != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Erro: $_errorMessage!', textAlign: TextAlign.center, style: TextStyle(color: Colors.red[700])),
                ))
              : Form(
                key: _formKey,
                child: Center( 
                  child: ConstrainedBox( 
                     constraints: const BoxConstraints(maxWidth: 500),
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24), 
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch, 
                          children: [
                            const SizedBox(height: 10), 
                            Center(
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundColor: Colors.grey[300],
                                    backgroundImage: _imageFile != null
                                        ? FileImage(_imageFile!) as ImageProvider
                                        : (_profilePictureUrl.isNotEmpty ? NetworkImage(_profilePictureUrl) : null),
                                    child: _imageFile == null && _profilePictureUrl.isEmpty
                                        ? Icon(Icons.person, size: 70, color: Colors.grey[400])
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
                                        color: _focusColor,
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
                            Center(
                              child: TextButton(
                                onPressed: _pickImage,
                                child: Text(
                                  'Alterar foto',
                                  style: TextStyle(color: _focusColor, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: TextFormField(
                                controller: _nomeController,
                                focusNode: _nomeFocusNode,
                                keyboardType: TextInputType.name,
                                cursorColor: _focusColor,
                                style: const TextStyle(fontSize: 18),
                                validator: (value) => (value == null || value.isEmpty) ? 'Nome não pode ser vazio.' : null,
                                decoration: _buildStandardInputDecoration(
                                  labelText: 'Nome completo',
                                  iconData: Icons.person_outline,
                                  isFocused: _isNomeFocused,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: TextFormField(
                                key: ValueKey(_userEmail), 
                                initialValue: _userEmail,
                                readOnly: true,
                                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                                decoration: _buildStandardInputDecoration(
                                  labelText: 'E-mail (não pode ser alterado)',
                                  iconData: Icons.email_outlined,
                                  isFocused: false, 
                                  readOnly: true,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: TextFormField(
                                controller: _contatoController,
                                focusNode: _contatoFocusNode,
                                keyboardType: TextInputType.phone,
                                cursorColor: _focusColor,
                                style: const TextStyle(fontSize: 18),
                                validator: (value) => (value == null || value.isEmpty) ? 'Telefone não pode ser vazio.' : null,
                                decoration: _buildStandardInputDecoration(
                                  labelText: 'Telefone',
                                  iconData: Icons.phone_outlined,
                                  isFocused: _isContatoFocused,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: TextFormField(
                                controller: _cursoController,
                                focusNode: _cursoFocusNode,
                                keyboardType: TextInputType.text,
                                cursorColor: _focusColor,
                                style: const TextStyle(fontSize: 18),
                                validator: (value) => (value == null || value.isEmpty) ? 'Curso não pode ser vazio.' : null,
                                decoration: _buildStandardInputDecoration(
                                  labelText: 'Curso',
                                  iconData: Icons.school_outlined,
                                  isFocused: _isCursoFocused,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20), 
                            _buildGradientButton(
                              onPressed: _isSaving ? null : _saveChanges,
                              isLoading: _isSaving,
                              child: const Text(
                                'SALVAR ALTERAÇÕES',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 24), 
                          ],
                        ),
                      ),
                  ),
                ),
              ),
    );
  }
}