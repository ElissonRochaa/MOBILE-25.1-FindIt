import 'package:flutter/material.dart';

class RecuperarSenha extends StatefulWidget {
  const RecuperarSenha({super.key});

  @override
  State<RecuperarSenha> createState() => _RecuperarSenhaState();
}

class _RecuperarSenhaState extends State<RecuperarSenha> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: Color(0xffEFEFEF)),
        padding: EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Image.asset(
                    "images/logo.png",
                    width: 173,
                    height: 310,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text(
                    "Recuperar Senha",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    "Informe seu email para enviarmos as instruções de recuperação de senha.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: TextField(
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    cursorColor: Color(0xff1D8BC9),
                    style: TextStyle(fontSize: 20),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(32, 16, 31, 16),
                      hintText: "Digite seu email",
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(left: 16, right: 8),
                        child: Image.asset(
                          "images/emailicon.png",
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child: ElevatedButton(
                    onPressed: () {
                      //  mostrar uma mensagem simples.
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Instruções de recuperação enviadas para o seu email!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff1D8BC9),
                      padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                      textStyle: TextStyle(fontSize: 20),
                    ),
                    child: Text(
                      "Enviar instruções",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 18, bottom: 18),
                  child: GestureDetector(
                    child: Text(
                      textAlign: TextAlign.center,
                      "Voltar para o Login",
                      style: TextStyle(color: Colors.black),
                    ),
                    onTap: () {
                      Navigator.pop(context); // retornar para a tela anterior (Login)
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