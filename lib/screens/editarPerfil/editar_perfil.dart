import 'package:flutter/material.dart';

class EditarPerfil extends StatefulWidget {
  final String nomeInicial;
  final String cursoInicial;
  final String contatoInicial;

  const EditarPerfil({
    Key? key,
    this.nomeInicial = '',
    this.cursoInicial = '',
    this.contatoInicial = '',
  }) : super(key: key);

  @override
  State<EditarPerfil> createState() => _EditarPerfilState();
}

class _EditarPerfilState extends State<EditarPerfil> {
  late final TextEditingController _nomeController;
  late final TextEditingController _cursoController;
  late final TextEditingController _contatoController;
  late final TextEditingController _emailController;
  late final TextEditingController _senhaController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.nomeInicial);
    _cursoController = TextEditingController(text: widget.cursoInicial);
    _contatoController = TextEditingController(text: widget.contatoInicial);
    _emailController = TextEditingController();
    _senhaController = TextEditingController();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cursoController.dispose();
    _contatoController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar Perfil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Foto de perfil
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF1D8BC9),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        'https://th.bing.com/th/id/R.dd92490fad30442dab135064c20e9871?rik=GguDgUvyyJLNvg&pid=ImgRaw&r=0',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    ),
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
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Alterar foto',
                style: TextStyle(
                  color: Color(0xFF1D8BC9),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Campos do formulário
            _buildFormField(
              controller: _nomeController,
              label: 'Nome completo',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 20),
            _buildFormField(
              controller: _emailController,
              label: 'E-mail',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _buildFormField(
              controller: _senhaController,
              label: 'Senha',
              icon: Icons.lock_outline,
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _buildFormField(
              controller: _contatoController,
              label: 'Telefone',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            _buildFormField(
              controller: _cursoController,
              label: 'Curso',
              icon: Icons.school_outlined,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1D8BC9),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            Navigator.pop(context, {
              'nome': _nomeController.text,
              'curso': _cursoController.text,
              'contato': _contatoController.text,
            });
          },
          child: const Text(
            'SALVAR ALTERAÇÕES',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFF1D8BC9)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1D8BC9), width: 2),
        ),
      ),
    );
  }
}