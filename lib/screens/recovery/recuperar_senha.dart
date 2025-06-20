import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Importe o pacote http
import 'dart:convert'; // Para codificar/decodificar JSON

class RecuperarSenha extends StatefulWidget {
  const RecuperarSenha({super.key});

  @override
  State<RecuperarSenha> createState() => _RecuperarSenhaState();
}

class _RecuperarSenhaState extends State<RecuperarSenha> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  bool _isEmailFocused = false;
  bool _isLoading = false; // Estado para controlar o carregamento do botão

  // CORREÇÃO AQUI: A _baseUrl deve ser a base da API de usuários
  static const String _baseUrl = 'http://localhost:8080/api/v1/users'; // Ajuste conforme seu ambiente!


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
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  // Método para exibir mensagens usando SnackBar
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return; // Garante que o widget ainda está montado
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Método para enviar a solicitação de recuperação de senha ao backend
  Future<void> _requestPasswordReset() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar("Por favor, digite seu email.", isError: true);
      return;
    }
    // Adicionar validação de formato de email básica, se desejar
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showSnackBar("Por favor, digite um email válido.", isError: true);
      return;
    }


    if (!mounted) return; // Verifica se o widget ainda está montado antes de atualizar o estado
    setState(() {
      _isLoading = true; // Ativa o estado de carregamento
    });

    try {
      // CORREÇÃO AQUI: Concatene _baseUrl com o endpoint 'forgot-password'
      final response = await http.post(
        Uri.parse('$_baseUrl/forgot-password'), // Endpoint para recuperar senha
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final responseData = jsonDecode(response.body);

      if (!mounted) return; // Verifica novamente após a chamada assíncrona
      if (response.statusCode == 200) {
        _showSnackBar(responseData['message'] ?? "Instruções enviadas para o seu email!");
        // Opcional: Navegar de volta para a tela de login após sucesso
        // Navigator.pop(context);
      } else {
        // Exibe a mensagem de erro do backend se houver
        _showSnackBar(responseData['message'] ?? 'Erro desconhecido ao enviar instruções.', isError: true);
      }
    } catch (e) {
      if (!mounted) return; // Verifica novamente após a chamada assíncrona
      _showSnackBar('Erro de conexão. Verifique se o backend está rodando e o IP está correto.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Desativa o estado de carregamento
        });
      }
    }
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
                    "Recuperar Senha",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, top: 8),
                  child: Text(
                    "Informe seu email para enviarmos as instruções de recuperação de senha.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor?.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
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
                            color: theme.dividerColor, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                            color: theme.primaryColor, width: 2.0),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                            color: theme.dividerColor, width: 1),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                            color: Colors.redAccent.shade400, width: 1.5),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                            color: Colors.redAccent.shade400, width: 2.0),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: _buildGradientButton(
                    onPressed: _isLoading ? null : _requestPasswordReset, // Desabilita o botão durante o carregamento
                    isLoading: _isLoading, // Passa o estado de carregamento para o construtor do botão
                    child: const Text(
                      "Enviar instruções",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 18, bottom: 18),
                  child: GestureDetector(
                    child: Text(
                      "Voltar para o Login",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor?.withOpacity(0.7),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}