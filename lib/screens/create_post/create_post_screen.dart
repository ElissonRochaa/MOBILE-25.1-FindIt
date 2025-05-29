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
import 'package:find_it/service/theme_service.dart';

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

  final FocusNode _nomeFocusNode = FocusNode();
  final FocusNode _descricaoFocusNode = FocusNode();
  final FocusNode _dataFocusNode = FocusNode();
  final FocusNode _localFocusNode = FocusNode();
  final FocusNode _statusFocusNode = FocusNode(); 

  bool _isNomeFocused = false;
  bool _isDescricaoFocused = false;
  bool _isDataFocused = false;
  bool _isLocalFocused = false;
  bool _isStatusFocused = false;

  final int _bottomNavCurrentIndex = 1;

  @override
  void initState() {
    super.initState();
    _nomeFocusNode.addListener(
      () => setState(() => _isNomeFocused = _nomeFocusNode.hasFocus),
    );
    _descricaoFocusNode.addListener(
      () => setState(() => _isDescricaoFocused = _descricaoFocusNode.hasFocus),
    );
    _dataFocusNode.addListener(
      () => setState(() => _isDataFocused = _dataFocusNode.hasFocus),
    );
    _localFocusNode.addListener(
      () => setState(() => _isLocalFocused = _localFocusNode.hasFocus),
    );
    _statusFocusNode.addListener(
      () => setState(() => _isStatusFocused = _statusFocusNode.hasFocus),
    );
  }

  void _onBottomNavTapped(int index) {
    final currentRouteName = ModalRoute.of(context)?.settings.name;
    if (index == 0) {
      if (currentRouteName != '/feed') {
        Navigator.pushReplacementNamed(context, '/feed');
      }
    } else if (index == 2) {
      if (currentRouteName != '/profile') {
        Navigator.pushNamed(context, '/profile');
      }
    }
  }

  InputDecoration _buildStandardInputDecoration({
    required String labelText,
    required IconData iconData,
    required bool isFocused,
  }) {
    final theme = Theme.of(context);
    final Color iconColor = isFocused ? theme.primaryColor : theme.iconTheme.color ?? Colors.grey;
    final Color focusedInputFillColor = theme.primaryColor.withOpacity(0.1);

    return InputDecoration(
      filled: true,
      fillColor: isFocused ? focusedInputFillColor : theme.cardTheme.color?.withOpacity(0.3) ?? Colors.grey[200],
      labelText: labelText,
      labelStyle: TextStyle(color: theme.hintColor, fontSize: 18),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 20, right: 12),
        child: Icon(iconData, color: iconColor, size: 24),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: theme.dividerColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: theme.dividerColor, width: 1),
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
    final Color endColor = theme.brightness == Brightness.light 
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
    final Color focusedInputFillColor = theme.primaryColor.withOpacity(0.1);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nova Postagem',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.9, 
                        child: GestureDetector(
                          onTap: _adicionarFoto,
                          child: Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: theme.cardColor.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.dividerColor,
                                width: 1,
                              ),
                              image: _imageFile != null
                                  ? DecorationImage(
                                      image: FileImage(_imageFile!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _imageFile == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo_outlined,
                                        size: 48,
                                        color: theme.iconTheme.color?.withOpacity(0.6),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Adicionar foto*',
                                        style: TextStyle(
                                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        controller: _nomeController,
                        focusNode: _nomeFocusNode,
                        validator: (value) =>
                            (value == null || value.isEmpty)
                                ? 'Nome do item é obrigatório.'
                                : null,
                        decoration: _buildStandardInputDecoration(
                          labelText: 'Nome do item*',
                          iconData: Icons.label_outline,
                          isFocused: _isNomeFocused,
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        cursorColor: theme.primaryColor,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        controller: _descricaoController,
                        focusNode: _descricaoFocusNode,
                        maxLines: 4,
                        validator: (value) =>
                            (value == null || value.isEmpty)
                                ? 'Descrição é obrigatória.'
                                : null,
                        decoration: _buildStandardInputDecoration(
                          labelText: 'Descrição detalhada*',
                          iconData: Icons.description_outlined,
                          isFocused: _isDescricaoFocused,
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        cursorColor: theme.primaryColor,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        controller: _localController,
                        focusNode: _localFocusNode,
                        validator: (value) =>
                            (value == null || value.isEmpty)
                                ? 'Local é obrigatório.'
                                : null,
                        decoration: _buildStandardInputDecoration(
                          labelText: 'Local onde foi encontrado/perdido*',
                          iconData: Icons.location_on_outlined,
                          isFocused: _isLocalFocused,
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        cursorColor: theme.primaryColor,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _dataController,
                            focusNode: _dataFocusNode,
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                    ? 'Data é obrigatória.'
                                    : null,
                            decoration: _buildStandardInputDecoration(
                              labelText: 'Data da ocorrência*',
                              iconData: Icons.calendar_today_outlined,
                              isFocused: _isDataFocused,
                            ),
                            style: TextStyle(
                              fontSize: 18,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                            cursorColor: theme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Focus(
                        focusNode: _statusFocusNode,
                        child: Container(
                          padding: const EdgeInsets.only(left: 5, right: 12),
                          decoration: BoxDecoration(
                            color: _isStatusFocused
                                ? focusedInputFillColor
                                : theme.cardTheme.color?.withOpacity(0.3) ?? Colors.grey[200],
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: _isStatusFocused
                                  ? theme.primaryColor
                                  : theme.dividerColor,
                              width: _isStatusFocused ? 2.0 : 1.0,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(left: 15, right: 12),
                                  child: Icon(
                                    Icons.help_outline,
                                    color: _isStatusFocused
                                        ? theme.primaryColor
                                        : theme.iconTheme.color?.withOpacity(0.6),
                                  ),
                                ),
                              ),
                              hint: Text(
                                'Status (achado/perdido)*',
                                style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                                  fontSize: 18,
                                ),
                              ),
                              items: ['achado', 'perdido'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value[0].toUpperCase() + value.substring(1),
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  _selectedStatus = newValue;
                                });
                              },
                              validator: (value) =>
                                  value == null
                                      ? 'Selecione um status'
                                      : null,
                              isExpanded: true,
                              dropdownColor: theme.cardColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildGradientButton(
                      onPressed: _isLoading ? null : _publicarPostagem,
                      isLoading: _isLoading,
                      child: const Text(
                        'PUBLICAR',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _bottomNavCurrentIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final theme = Theme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: theme.primaryColor,
              onPrimary: theme.colorScheme.onPrimary,
              surface: theme.cardColor,
              onSurface: theme.textTheme.bodyMedium?.color ?? Colors.black87,
            ),
            dialogBackgroundColor: theme.cardColor,
            textTheme: theme.textTheme,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dataController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _adicionarFoto() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
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
        SnackBar(
          content: const Text('Por favor, adicione uma foto para o item.'),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
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

      final mimeType =
          lookupMimeType(_imageFile!.path) ?? 'application/octet-stream';
      final mediaType = MediaType.parse(mimeType);
      var multipartFile = await http.MultipartFile.fromPath(
        'foto',
        _imageFile!.path,
        contentType: mediaType,
      );
      request.files.add(multipartFile);

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (!mounted) return;
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Post criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/feed');
      } else {
        final errorData = json.decode(responseBody);
        throw Exception(
          errorData['message'] ?? 'Erro ${response.statusCode} ao criar post',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
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
    _nomeFocusNode.dispose();
    _descricaoFocusNode.dispose();
    _dataFocusNode.dispose();
    _localFocusNode.dispose();
    _statusFocusNode.dispose();
    super.dispose();
  }
}