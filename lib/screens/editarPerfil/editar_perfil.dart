import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:find_it/service/auth_service.dart';
import 'package:mime/mime.dart';
import 'package:find_it/service/theme_service.dart';
import 'package:find_it/widgets/custom_profile_form_field.dart';

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

  @override
  void initState() {
    super.initState();
    _nomeFocusNode.addListener(() {
      if (mounted) setState(() => _isNomeFocused = _nomeFocusNode.hasFocus);
    });
    _cursoFocusNode.addListener(() {
      if (mounted) setState(() => _isCursoFocused = _cursoFocusNode.hasFocus);
    });
    _contatoFocusNode.addListener(() {
      if (mounted)
        setState(() => _isContatoFocused = _contatoFocusNode.hasFocus);
    });
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Usuário não autenticado');

      // Simulação de chamada de API
      await Future.delayed(const Duration(seconds: 1));
      // Dados mockados para demonstração sem backend real:
      if (!mounted) return;
      setState(() {
        _nomeController.text = 'Usuário Exemplo';
        _cursoController.text = 'Engenharia de Software';
        _contatoController.text = '(00) 91234-5678';
        _profilePictureUrl =
            'https://placehold.co/120x120/E0E0E0/BDBDBD?text=Foto';
        _userEmail = 'usuario@exemplo.com';
      });
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
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
          SnackBar(
            content: const Text('Perfil atualizado com sucesso!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao salvar: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
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

    await Future.delayed(const Duration(seconds: 1));
    debugPrint('Dados do perfil atualizados (simulado):');
    debugPrint('Nome: ${_nomeController.text}');
    debugPrint('Telefone: ${_contatoController.text}');
    debugPrint('Curso: ${_cursoController.text}');
  }

  Future<void> _updateProfilePicture() async {
    if (_imageFile == null) return;
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Usuário não autenticado');

    await Future.delayed(const Duration(seconds: 1));
    debugPrint('Foto do perfil atualizada (simulado): ${_imageFile!.path}');
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
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final Color iconColor =
        isFocused
            ? theme.primaryColor
            : (readOnly
                ? theme.disabledColor
                : theme.iconTheme.color ?? Colors.grey);

    final Color effectiveFillColor =
        readOnly
            ? theme.cardColor.withAlpha((0.5 * 255).toInt())
            : (isFocused
                ? theme.primaryColor.withAlpha((0.1 * 255).toInt())
                : theme.cardColor.withAlpha((0.3 * 255).toInt()));

    final Color enabledBorderColor =
        readOnly
            ? theme.dividerColor.withAlpha((0.5 * 255).toInt())
            : theme.dividerColor;

    return InputDecoration(
      filled: true,
      fillColor: effectiveFillColor,
      labelText: labelText,
      labelStyle: TextStyle(
        color:
            readOnly
                ? theme.textTheme.bodyMedium?.color?.withOpacity(0.5)
                : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
        fontSize: 18,
      ),
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
        borderSide: BorderSide(color: theme.primaryColor, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 2.0),
      ),
    );
  }

  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required Widget child,
    bool isLoading = false,
  }) {
    final theme = Theme.of(context);
    final Color startColor = theme.primaryColor;
    final Color endColor =
        theme.brightness == Brightness.light
            ? ThemeNotifier.findItPrimaryDarkBlue
            : theme.colorScheme.primaryContainer;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [startColor, endColor],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child:
              isLoading
                  ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.onPrimary,
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
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Editar Perfil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: theme.primaryColor),
              )
              : _errorMessage != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Erro: $_errorMessage!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              )
              : ProfileFormLayout(
                // Usando o novo widget de layout do formulário
                formKey: _formKey,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: theme.hoverColor,
                          backgroundImage:
                              _imageFile != null
                                  ? FileImage(_imageFile!) as ImageProvider
                                  : (_profilePictureUrl.isNotEmpty
                                      ? NetworkImage(_profilePictureUrl)
                                      : null),
                          child:
                              _imageFile == null && _profilePictureUrl.isEmpty
                                  ? Icon(
                                    Icons.person,
                                    size: 70,
                                    color: theme.iconTheme.color?.withOpacity(
                                      0.5,
                                    ),
                                  )
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
                              color: theme.primaryColor,
                              border: Border.all(
                                color: theme.cardColor,
                                width: 2,
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: theme.colorScheme.onPrimary,
                              ),
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
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  CustomProfileFormField(
                    controller: _nomeController,
                    focusNode: _nomeFocusNode,
                    labelText: 'Nome completo',
                    iconData: Icons.person_outline,
                    isFocused: _isNomeFocused,
                    keyboardType: TextInputType.name,
                    validator:
                        (value) =>
                            (value == null || value.isEmpty)
                                ? 'Nome não pode ser vazio.'
                                : null,
                    inputDecorationBuilder: _buildStandardInputDecoration,
                  ),
                  CustomProfileFormField(
                    initialValue: _userEmail,
                    labelText: 'E-mail (não pode ser alterado)',
                    iconData: Icons.email_outlined,
                    isFocused: false,
                    readOnly: true,
                    inputDecorationBuilder: _buildStandardInputDecoration,
                  ),
                  CustomProfileFormField(
                    controller: _contatoController,
                    focusNode: _contatoFocusNode,
                    labelText: 'Telefone',
                    iconData: Icons.phone_outlined,
                    isFocused: _isContatoFocused,
                    keyboardType: TextInputType.phone,
                    validator:
                        (value) =>
                            (value == null || value.isEmpty)
                                ? 'Telefone não pode ser vazio.'
                                : null,
                    inputDecorationBuilder: _buildStandardInputDecoration,
                  ),
                  CustomProfileFormField(
                    controller: _cursoController,
                    focusNode: _cursoFocusNode,
                    labelText: 'Curso',
                    iconData: Icons.school_outlined,
                    isFocused: _isCursoFocused,
                    keyboardType: TextInputType.text,
                    validator:
                        (value) =>
                            (value == null || value.isEmpty)
                                ? 'Curso não pode ser vazio.'
                                : null,
                    inputDecorationBuilder: _buildStandardInputDecoration,
                  ),

                  const SizedBox(height: 20),
                  _buildGradientButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    isLoading: _isSaving,
                    child: Text(
                      'SALVAR ALTERAÇÕES',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
    );
  }
}
