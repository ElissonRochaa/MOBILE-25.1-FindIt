import 'package:flutter/material.dart';

class EditarPerfil extends StatefulWidget {
  final String nomeInicial;
  final String cursoInicial;
  final String contatoInicial;

  const EditarPerfil({
    this.nomeInicial = '',
    this.cursoInicial = '',
    this.contatoInicial = '',
    super.key,
  });

  @override
  State<EditarPerfil> createState() => _EditarPerfilState();
}

class _EditarPerfilState extends State<EditarPerfil> {
  late final TextEditingController nomeController;
  late final TextEditingController cursoController;
  late final TextEditingController contatoController;

  @override
  void initState() {
    super.initState();
    nomeController = TextEditingController(text: widget.nomeInicial);
    cursoController = TextEditingController(text: widget.cursoInicial);
    contatoController = TextEditingController(text: widget.contatoInicial);
  }

  @override
  void dispose() {
    nomeController.dispose();
    cursoController.dispose();
    contatoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil')),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Foto de perfil
            Container(
              margin: const EdgeInsets.only(top: 20),
              width: 100,
              height: 100,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.grey, width: 2),
              ),
              child: Image.network(
                'https://th.bing.com/th/id/R.dd92490fad30442dab135064c20e9871?rik=GguDgUvyyJLNvg&pid=ImgRaw&r=0',
                fit: BoxFit.cover,
              ),
            ),

            // Botão para mudar foto
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 20),
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  'Mudar foto de perfil',
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ),
            ),

            // Campos de formulário
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  TextField(
                    controller: nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Digite seu nome',
                      icon: Icon(Icons.emoji_emotions_outlined),
                    ),
                  ),
                  const SizedBox(height: 25),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Digite seu email',
                      icon: Icon(Icons.alternate_email),
                    ),
                  ),
                  const SizedBox(height: 25),
                  TextField(
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Digite sua senha',
                      icon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 25),
                  TextField(
                    controller: contatoController,
                    decoration: const InputDecoration(
                      labelText: 'Telefone para contato',
                      icon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 25),
                  TextField(
                    controller: cursoController,
                    decoration: const InputDecoration(
                      labelText: 'Curso de origem',
                      icon: Icon(Icons.school),
                    ),
                  ),
                  const SizedBox(height: 25),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'nome': nomeController.text,
              'curso': cursoController.text,
              'contato': contatoController.text,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('Salvar', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}
