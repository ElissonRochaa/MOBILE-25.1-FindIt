import 'package:flutter/material.dart';
import 'package:find_it/pages/EdicaoPerfil.dart';

class Perfil extends StatefulWidget {
  const Perfil({super.key});

  @override
  State<Perfil> createState() => _PerfilState();
}

class _PerfilState extends State<Perfil> {
  String nome = '';
  String curso = '';
  String contato = '';

  void _navegarParaEdicao() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EdicaoPerfil(
              nomeInicial: nome,
              cursoInicial: curso,
              contatoInicial: contato,
            ),
      ),
    );
    if (resultado != null) {
      setState(() {
        nome = resultado['nome'] ?? 'Nome';
        curso = resultado['curso'] ?? 'Curso';
        contato = resultado['contato'] ?? 'Contato';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Container(
                  margin: const EdgeInsets.all(20),
                  width: 100,
                  height: 100,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Image.network(
                    'https://th.bing.com/th/id/R.dd92490fad30442dab135064c20e9871?rik=GguDgUvyyJLNvg&pid=ImgRaw&r=0',
                    fit: BoxFit.cover,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: const TextStyle(fontSize: 16, color: Colors.blue),
                    ),
                    Text(curso, style: const TextStyle(fontSize: 12)),
                    Text(
                      contato,
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                    Container(
                      width: 100,
                      child: TextButton(onPressed: () {}, child: Text('Sair')),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.blue,
                  ),
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Perdidos',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                Container(
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey[200],
                  ),
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Achados',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _navegarParaEdicao,
                  child: const Text(
                    'Editar perfil',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.only(right: 20, left: 20),
            color: Colors.grey[200],
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 10),
                  width: 150,
                  height: 150,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Image.network(
                      'https://th.bing.com/th/id/OIP.Yb0-EPaB3uddjKkgztDfwQHaHa?rs=1&pid=ImgDetMain',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Garrafa de água',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Bom dia pessoal perdi essa garrafa na upe...',
                          style: const TextStyle(fontSize: 11),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Data: ',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                              TextSpan(
                                text: '01/01/2023',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(icon: const Icon(Icons.home), onPressed: () {}),
            IconButton(icon: const Icon(Icons.add), onPressed: () {}),
            IconButton(icon: const Icon(Icons.person), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
