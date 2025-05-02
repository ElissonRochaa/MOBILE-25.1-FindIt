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

  Widget build(BuildContext context) {
    return Material(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 200,
            height: 200,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(100)),
            child: Image.network(
              'https://th.bing.com/th/id/R.dd92490fad30442dab135064c20e9871?rik=GguDgUvyyJLNvg&pid=ImgRaw&r=0',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 20),
            child: TextButton(
              onPressed: () {},
              child: Text(
                'Mudar foto de perfil',
                style: TextStyle(fontSize: 20, color: Colors.blue),
              ),
            ),
          ),
          Column(
            children: [
              TextField(
                controller: nomeController,
                decoration: InputDecoration(
                  labelText: 'Digite seu nome',
                  icon: const Icon(Icons.emoji_emotions_outlined),
                ),
              ),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Digite seu email',
                  icon: const Icon(Icons.alternate_email),
                ),
              ),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Digite sua senha',
                  icon: const Icon(Icons.lock),
                ),
              ),
              TextField(
                controller: contatoController,
                decoration: InputDecoration(
                  labelText: 'Digite seu contato',
                  icon: const Icon(Icons.phone),
                ),
              ),
              TextField(
                controller: cursoController,
                decoration: InputDecoration(
                  labelText: 'Digite seu curso',
                  icon: const Icon(Icons.school),
                ),
              ),
              Container(
                width: double.infinity,
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
                  ),
                  child: const Text('Salvar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
