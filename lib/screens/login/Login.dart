import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:find_it/service/auth_service.dart';
import 'package:find_it/screens/cadastro/Cadastro.dart';
import 'package:find_it/screens/feed/feed_screen.dart';
import 'package:find_it/screens/recovery/RecuperarSenha.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _senhaFocusNode = FocusNode();

  bool _isEmailFocused = false;
  bool _isSenhaFocused = false;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isEmailFocused = _emailFocusNode.hasFocus;
        });
      }
    });
    _senhaFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isSenhaFocused = _senhaFocusNode.hasFocus;
        });
      }
    });
  }

  Future<void> _loginUsuario() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/v1/auth/signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": _emailController.text,
          "senha": _senhaController.text,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (!mounted) return;
      if (response.statusCode == 200) {
        final userId = responseData['user']['_id'].toString();
        final token = responseData['token'];

        await AuthService.saveUserData(token, _emailController.text, userId);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FeedScreen()),
        );
      } else {
        final errorMessage = responseData['message'] ?? 'Erro ao fazer login';
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
          title: Row(children: [
            Icon(Icons.error, color: Colors.red, size: 30),
            SizedBox(width: 10),
            Text('Erro no Login', style: theme.textTheme.titleLarge),
          ]),
          content: Text(message, style: theme.textTheme.bodyMedium),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: TextStyle(color: theme.primaryColor)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _emailFocusNode.dispose();
    _senhaFocusNode.dispose();
    super.dispose();
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
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          alignment: Alignment.center,
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white, 
                    strokeWidth: 3),
                )
              : child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color pageBackgroundColor = theme.scaffoldBackgroundColor;
    final Color? textColor = theme.textTheme.bodyLarge?.color;
    final Color focusedInputFillColor = theme.primaryColor.withOpacity(0.1);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: pageBackgroundColor),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2, top: 20),
                    child: Image.asset(
                      isDarkMode ? "images/logo-dark.png" : "images/logo.png",
                      width: 173,
                      height: 310,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
                    child: Text(
                      "Login",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
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
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _isEmailFocused 
                            ? focusedInputFillColor 
                            : theme.cardColor.withOpacity(0.5),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 18, horizontal: 25),
                        hintText: "Digite seu email",
                        hintStyle: TextStyle(color: theme.hintColor),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 20, right: 12),
                          child: Image.asset(
                            "images/emailicon.png", 
                            width: 24, 
                            height: 24,
                            color: _isEmailFocused 
                                ? theme.primaryColor 
                                : theme.hintColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: theme.dividerColor, 
                            width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: theme.primaryColor, 
                            width: 2.0),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: theme.dividerColor, 
                            width: 1),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: Colors.redAccent.shade400, 
                            width: 1.5),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: Colors.redAccent.shade400, 
                            width: 2.0),
                        ),
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
                      style: TextStyle(fontSize: 18, color: textColor),
                      cursorColor: theme.primaryColor,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _isSenhaFocused 
                            ? focusedInputFillColor 
                            : theme.cardColor.withOpacity(0.5),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 18, horizontal: 25),
                        hintText: "Digite sua senha",
                        hintStyle: TextStyle(color: theme.hintColor),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 20, right: 12),
                          child: Image.asset(
                            "images/lock.png", 
                            width: 24, 
                            height: 24,
                            color: _isSenhaFocused 
                                ? theme.primaryColor 
                                : theme.hintColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: theme.dividerColor, 
                            width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: theme.primaryColor, 
                            width: 2.0),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: theme.dividerColor, 
                            width: 1),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: Colors.redAccent.shade400, 
                            width: 1.5),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: Colors.redAccent.shade400, 
                            width: 2.0),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 18, bottom: 18),
                    child: GestureDetector(
                      child: Text(
                        "Esqueci minha senha",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor?.withOpacity(0.7), 
                          decoration: TextDecoration.underline),
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, '/recuperar-senha');
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: _buildGradientButton(
                      onPressed: _isLoading ? null : _loginUsuario,
                      isLoading: _isLoading,
                      child: const Text(
                        "Entrar",
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 20),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: Text(
                      "Ainda não possui uma conta?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 15),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: _buildGradientButton(
                      onPressed: _isLoading ? null : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (builder) => const Cadastro()),
                        );
                      },
                      child: const Text(
                        "Cadastrar-se",
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}