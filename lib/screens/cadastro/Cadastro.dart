import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 10),
              Text('Sucesso!', style: theme.textTheme.titleLarge),
            ],
          ),
          content: Text('Cadastro realizado com sucesso!', style: theme.textTheme.bodyMedium),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                );
              },
              child: Text(
                'OK',
                style: TextStyle(color: theme.primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 30),
              SizedBox(width: 10),
              Text('Erro', style: theme.textTheme.titleLarge),
            ],
          ),
          content: Text(message, style: theme.textTheme.bodyMedium),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(color: theme.primaryColor),
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
    final theme = Theme.of(context);
    final Color iconColor = isFocused ? theme.primaryColor : theme.hintColor;
    final Color focusedInputFillColor = theme.primaryColor.withOpacity(0.1);

    return InputDecoration(
      filled: true,
      fillColor: isFocused ? focusedInputFillColor : theme.cardColor.withOpacity(0.5),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
      hintText: hintText,
      hintStyle: TextStyle(color: theme.hintColor, fontSize: 18),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 20, right: 12),
        child: Image.asset(imagePath, width: 24, height: 24, color: iconColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: theme.dividerColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: theme.primaryColor, width: 2.0),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: theme.dividerColor, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.redAccent.shade400, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.redAccent.shade400, width: 2.0),
      ),
    );
  }

  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required Widget child,
    bool isLoading = false,
  }) {
    final theme = Theme.of(context);
    final Color gradStart = theme.primaryColor;
    final Color gradEnd = Color.lerp(theme.primaryColor, Colors.black, 0.3)!;

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
            colors: [gradStart, gradEnd],
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
    final theme = Theme.of(context);
    final Color pageBackgroundColor = theme.scaffoldBackgroundColor;
    final Color? textColor = theme.textTheme.bodyLarge?.color;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: pageBackgroundColor),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 40, bottom: 20),
                      child: Text(
                        "Cadastrar-se",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor,
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
                              color: theme.hoverColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.primaryColor.withOpacity(0.5),
                                width: 2,
                              ),
                              image: _imageFile != null
                                  ? DecorationImage(
                                      fit: BoxFit.cover,
                                      image: FileImage(_imageFile!),
                                    )
                                  : null,
                            ),
                            child: _imageFile == null
                                ? Icon(
                                    Icons.add_a_photo,
                                    size: 60,
                                    color: theme.hintColor,
                                  )
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
                          if (value == null || value.isEmpty) {
                            return 'Por favor, digite seu nome';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.text,
                        cursorColor: theme.primaryColor,
                        style: TextStyle(fontSize: 18, color: textColor),
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
                          if (value == null || value.isEmpty) {
                            return 'Por favor, digite seu email';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Digite um email válido';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.emailAddress,
                        cursorColor: theme.primaryColor,
                        style: TextStyle(fontSize: 18, color: textColor),
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
                          if (value == null || value.isEmpty) {
                            return 'Por favor, digite sua senha';
                          }
                          if (value.length < 6) {
                            return 'A senha deve ter pelo menos 6 caracteres';
                          }
                          return null;
                        },
                        obscureText: true,
                        cursorColor: theme.primaryColor,
                        style: TextStyle(fontSize: 18, color: textColor),
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
                          if (value == null || value.isEmpty) {
                            return 'Por favor, digite seu telefone';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.phone,
                        cursorColor: theme.primaryColor,
                        style: TextStyle(fontSize: 18, color: textColor),
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
                          if (value == null || value.isEmpty) {
                            return 'Por favor, digite seu curso';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.text,
                        cursorColor: theme.primaryColor,
                        style: TextStyle(fontSize: 18, color: textColor),
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
        selectedItemColor: theme.primaryColor,
        onTap: _onItemTapped,
        backgroundColor: theme.cardColor,
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