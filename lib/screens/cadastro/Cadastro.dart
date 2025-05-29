import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:find_it/screens/login/Login.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class Cadastro extends StatefulWidget {
  const Cadastro({super.key});

  @override
  State<Cadastro> createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {
  int _selectedIndex = 1;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  File? _imageFile;

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _cursoController = TextEditingController();

  final FocusNode _nomeFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _senhaFocusNode = FocusNode();
  final FocusNode _telefoneFocusNode = FocusNode();
  final FocusNode _cursoFocusNode = FocusNode();

  bool _isNomeFocused = false;
  bool _isEmailFocused = false;
  bool _isSenhaFocused = false;
  bool _isTelefoneFocused = false;
  bool _isCursoFocused = false;

  final Color _focusColor = const Color(0xFF1D8BC9);
  // Cores do gradiente para o botão
  final Color _gradientStartColor = const Color(0xFF1D8BC9);
  final Color _gradientEndColor = const Color(0xFF01121B);

  @override
  void initState() {
    super.initState();
    _nomeFocusNode.addListener(
      () => setState(() => _isNomeFocused = _nomeFocusNode.hasFocus),
    );
    _emailFocusNode.addListener(
      () => setState(() => _isEmailFocused = _emailFocusNode.hasFocus),
    );
    _senhaFocusNode.addListener(
      () => setState(() => _isSenhaFocused = _senhaFocusNode.hasFocus),
    );
    _telefoneFocusNode.addListener(
      () => setState(() => _isTelefoneFocused = _telefoneFocusNode.hasFocus),
    );
    _cursoFocusNode.addListener(
      () => setState(() => _isCursoFocused = _cursoFocusNode.hasFocus),
    );
  }

  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    }
  }

  Future<void> _cadastrarUsuario() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_imageFile == null) {
      _showErrorDialog('Por favor, adicione uma foto de perfil.');
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('http://localhost:8080/api/v1/users');
    final request = http.MultipartRequest('POST', url);

    request.fields['nome'] = _nomeController.text;
    request.fields['email'] = _emailController.text;
    request.fields['senha'] = _senhaController.text;
    request.fields['telefone'] = _telefoneController.text;
    request.fields['curso'] = _cursoController.text;

    if (_imageFile != null) {
      final mimeType = lookupMimeType(_imageFile!.path) ?? 'image/jpeg';
      request.files.add(
        await http.MultipartFile.fromPath(
          'profilePicture',
          _imageFile!.path,
          contentType: MediaType.parse(mimeType),
        ),
      );
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;
      if (response.statusCode == 201) {
        _showSuccessDialog();
      } else {
        final errorMessage =
            jsonDecode(response.body)['message'] ?? 'Erro ao cadastrar';
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Erro de conexão. Verifique se o backend está rodando.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 10),
              Text('Sucesso!'),
            ],
          ),
          content: const Text('Cadastro realizado com sucesso!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                );
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xff1D8BC9)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 30),
              SizedBox(width: 10),
              Text('Erro'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xff1D8BC9)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _telefoneController.dispose();
    _cursoController.dispose();
    _nomeFocusNode.dispose();
    _emailFocusNode.dispose();
    _senhaFocusNode.dispose();
    _telefoneFocusNode.dispose();
    _cursoFocusNode.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required String imagePath,
    required bool isFocused,
  }) {
    final Color iconColor = isFocused ? _focusColor : Colors.grey[600]!;
    final Color focusedInputFillColor = _focusColor.withOpacity(0.1);

    return InputDecoration(
      filled: true,
      fillColor: isFocused ? focusedInputFillColor : Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[600], fontSize: 18),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 20, right: 12),
        child: Image.asset(imagePath, width: 24, height: 24, color: iconColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: _focusColor, width: 2.0),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
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
          borderRadius: BorderRadius.circular(
            30,
          ), 
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
          padding: const EdgeInsets.symmetric(
            vertical: 16,
          ), 
          alignment: Alignment.center,
          child:
              isLoading
                  ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                  : child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Color(0xffEFEFEF)),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ), 
        child: Center(
          child: ConstrainedBox(
            // Limita a largura máxima do formulário
            constraints: const BoxConstraints(
              maxWidth: 500,
            ), 
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 40,
                        bottom: 20,
                      ), // Aumenta padding no topo
                      child: const Text(
                        "Cadastrar-se",
                        textAlign: TextAlign.center, 
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 5, bottom: 30),
                      child: Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _focusColor.withOpacity(0.5),
                                width: 2,
                              ), 
                              image:
                                  _imageFile != null
                                      ? DecorationImage(
                                        fit:
                                            BoxFit
                                                .cover, 
                                        image: FileImage(_imageFile!),
                                      )
                                      : null,
                            ),
                            child:
                                _imageFile == null
                                    ? Icon(
                                      Icons.add_a_photo,
                                      size: 60,
                                      color: Colors.grey[500],
                                    ) // Ícone maior
                                    : null,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        controller: _nomeController,
                        focusNode: _nomeFocusNode,
                        validator: (value) {
                          /* ... */
                        },
                        keyboardType: TextInputType.text,
                        cursorColor: _focusColor,
                        style: const TextStyle(fontSize: 18),
                        decoration: _buildInputDecoration(
                          hintText: "Digite seu nome",
                          imagePath: "images/smile.png",
                          isFocused: _isNomeFocused,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        validator: (value) {
                          /* ... */
                        },
                        keyboardType: TextInputType.emailAddress,
                        cursorColor: _focusColor,
                        style: const TextStyle(fontSize: 18),
                        decoration: _buildInputDecoration(
                          hintText: "Digite seu email",
                          imagePath: "images/emailicon.png",
                          isFocused: _isEmailFocused,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        controller: _senhaController,
                        focusNode: _senhaFocusNode,
                        validator: (value) {
                          /* ... */
                        },
                        obscureText: true,
                        cursorColor: _focusColor,
                        style: const TextStyle(fontSize: 18),
                        decoration: _buildInputDecoration(
                          hintText: "Digite sua senha",
                          imagePath: "images/lock.png",
                          isFocused: _isSenhaFocused,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        controller: _telefoneController,
                        focusNode: _telefoneFocusNode,
                        validator: (value) {
                          /* ... */
                        },
                        keyboardType: TextInputType.phone,
                        cursorColor: _focusColor,
                        style: const TextStyle(fontSize: 18),
                        decoration: _buildInputDecoration(
                          hintText: "Telefone para contato",
                          imagePath: "images/phone.png",
                          isFocused: _isTelefoneFocused,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        controller: _cursoController,
                        focusNode: _cursoFocusNode,
                        validator: (value) {
                          /* ... */
                        },
                        keyboardType: TextInputType.text,
                        cursorColor: _focusColor,
                        style: const TextStyle(fontSize: 18),
                        decoration: _buildInputDecoration(
                          hintText: "Curso de origem",
                          imagePath: "images/book.png",
                          isFocused: _isCursoFocused,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 40, bottom: 20),
                      child: _buildGradientButton(
                        onPressed: _isLoading ? null : _cadastrarUsuario,
                        isLoading: _isLoading,
                        child: const Text(
                          "Cadastrar-se",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18, 
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: _focusColor,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xffEFEFEF),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.login), label: 'Login'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Cadastro',
          ),
        ],
      ),
    );
  }
}
