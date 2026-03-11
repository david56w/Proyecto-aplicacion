import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

    @override
    _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends
State<LoginPage> {

    final TextEditingController
    emailController = TextEditingController();
    final TextEditingController
    passwordController = TextEditingController();

    Future<void> enviarDatos(String ruta) async {
        final url = Uri.parse('http://10.0.2.2: 3000/$ruta');

        final respuesta = await http.post(
            url,
            headers: {'Content-Type': 'aplication/json'},
            body: jsonEncode({
                'email': emailController.text,
                'password': passwordController.text,
            }),
        );

        final data = jsonDecode(respuesta.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['mensaje'])));
    }

    @override
    Widget build(BuildContext context){
        return Scaffold(
            appBar: AppBar(title: Text("Mi App en Arch")),
            body: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                    children: [
                        TextField(controller: emailController, decoration: InputDecoration(labelText: "Correo")),
                        TextField(controller: passwordController, decoration: InputDecoration(labelText: "Contraseña"),
                        obscureText: true,),
                        SizedBox(height: 20,),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                                ElevatedButton(onPressed: () => enviarDatos('login'), child: Text("Iniciar Sesion")),
                                OutlinedButton(onPressed: () => enviarDatos('registro'), child: Text("Registrarse")),
                            ],
                        )
                    ],
                ),
                ),
            );
    }
  }