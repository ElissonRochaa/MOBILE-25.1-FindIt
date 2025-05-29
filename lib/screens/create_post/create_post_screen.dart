import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:find_it/service/auth_service.dart';
import 'package:find_it/screens/feed/feed_screen.dart';
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
  final Color _focusColor = const Color(0xFF1D8BC9);
  final Color _gradientStartColor = const Color(0xFF1D8BC9);
  final Color _gradientEndColor = const Color(0xFF01121B);

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
    final Color iconColor = isFocused ? _focusColor : Colors.grey[600]!;
    final Color focusedInputFillColor = _focusColor.withOpacity(0.1);

    return InputDecoration(
      filled: true,
      fillColor: isFocused ? focusedInputFillColor : Colors.transparent,
      labelText: labelText,
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 18),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 20, right: 12),
        child: Icon(iconData, color: iconColor, size: 24),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
    final Color focusedInputFillColor = _focusColor.withOpacity(0.1);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nova Postagem',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xffEFEFEF), 
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),
      body: Container(
        color: const Color(0xffEFEFEF), 
        child: Center(
          // Centraliza o ConstrainedBox
          child: ConstrainedBox(
            // Limita a largura
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
                            width:
                                double
                                    .infinity, 
                            height: 200, 
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                              image:
                                  _imageFile != null
                                      ? DecorationImage(
                                        image: FileImage(_imageFile!),
                                        fit: BoxFit.cover,
                                      )
                                      : null,
                            ),
                            child:
                                _imageFile == null
                                    ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo_outlined,
                                          size: 48,
                                          color: Colors.grey[500],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Adicionar foto*',
                                          style: TextStyle(
                                            color: Colors.grey[600],
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
                      // Adicionado Padding
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        controller: _nomeController,
                        focusNode: _nomeFocusNode,
                        validator:
                            (value) =>
                                (value == null || value.isEmpty)
                                    ? 'Nome do item é obrigatório.'
                                    : null,
                        decoration: _buildStandardInputDecoration(
                          labelText: 'Nome do item*',
                          iconData: Icons.label_outline,
                          isFocused: _isNomeFocused,
                        ),
                        style: const TextStyle(fontSize: 18),
                        cursorColor: _focusColor,
                      ),
                    ),
                    Padding(
                      // Adicionado Padding
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        controller: _descricaoController,
                        focusNode: _descricaoFocusNode,
                        maxLines: 4,
                        validator:
                            (value) =>
                                (value == null || value.isEmpty)
                                    ? 'Descrição é obrigatória.'
                                    : null,
                        decoration: _buildStandardInputDecoration(
                          labelText: 'Descrição detalhada*',
                          iconData: Icons.description_outlined,
                          isFocused: _isDescricaoFocused,
                        ),
                        style: const TextStyle(fontSize: 18),
                        cursorColor: _focusColor,
                      ),
                    ),
                    Padding(
                      // Adicionado Padding
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        controller: _localController,
                        focusNode: _localFocusNode,
                        validator:
                            (value) =>
                                (value == null || value.isEmpty)
                                    ? 'Local é obrigatório.'
                                    : null,
                        decoration: _buildStandardInputDecoration(
                          labelText: 'Local onde foi encontrado/perdido*',
                          iconData: Icons.location_on_outlined,
                          isFocused: _isLocalFocused,
                        ),
                        style: const TextStyle(fontSize: 18),
                        cursorColor: _focusColor,
                      ),
                    ),
                    Padding(
                      // Adicionado Padding
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _dataController,
                            focusNode:
                                _dataFocusNode, 
                            validator:
                                (value) =>
                                    (value == null || value.isEmpty)
                                        ? 'Data é obrigatória.'
                                        : null,
                            decoration: _buildStandardInputDecoration(
                              labelText: 'Data da ocorrência*',
                              iconData: Icons.calendar_today_outlined,
                              isFocused: _isDataFocused,
                            ),
                            style: const TextStyle(fontSize: 18),
                            cursorColor: _focusColor,
                          ),
                        ),
                      ),
                    ),
                    // Dropdown estilizado
                    Padding(
                      // Adicionado Padding
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Focus(
                        focusNode: _statusFocusNode,
                        child: Container(
                          padding: const EdgeInsets.only(
                            left: 5,
                            right: 12,
                          ), 
                          decoration: BoxDecoration(
                            color:
                                _isStatusFocused
                                    ? focusedInputFillColor
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color:
                                  _isStatusFocused
                                      ? _focusColor
                                      : Colors.grey.shade400,
                              width: _isStatusFocused ? 2.0 : 1.0,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                prefixIcon: Padding(
                                  // Padding para o ícone do dropdown
                                  padding: const EdgeInsets.only(
                                    left: 15,
                                    right: 12,
                                  ),
                                  child: Icon(
                                    Icons.help_outline,
                                    color:
                                        _isStatusFocused
                                            ? _focusColor
                                            : Colors.grey[600],
                                  ),
                                ),
                              ),
                              hint: Text(
                                'Status (achado/perdido)*',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 18,
                                ),
                              ),
                              items:
                                  ['achado', 'perdido'].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value[0].toUpperCase() +
                                            value.substring(1),
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  _selectedStatus = newValue;
                                });
                              },
                              validator:
                                  (value) =>
                                      value == null
                                          ? 'Selecione um status'
                                          : null,
                              isExpanded:
                                  true,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24), // Espaço antes do botão
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

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    bool isRequired = false,
    FocusNode?
    focusNode, 
  }) {

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      decoration: _buildStandardInputDecoration(
        labelText:
            '$label${isRequired ? '*' : ''}', 
        iconData: icon,
        isFocused: focusNode?.hasFocus ?? false, 
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Este campo é obrigatório.';
        }
        return null;
      },
      style: const TextStyle(fontSize: 18),
      cursorColor: _focusColor,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        // Para estilizar o DatePicker
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: _focusColor),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
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
        const SnackBar(
          content: Text('Por favor, adicione uma foto para o item.'),
          backgroundColor: Colors.orange,
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
          const SnackBar(
            content: Text('Post criado com sucesso!'),
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
          backgroundColor: Colors.red,
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
