import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'widgets/custom_header.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formGlobalKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> enviarDatos(String ruta) async {
    final url = Uri.parse('http://10.0.2.2:3000/$ruta');

    final respuesta = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': emailController.text,
        'password': passwordController.text,
      }),
    );

    final data = jsonDecode(respuesta.body);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(data['mensaje'])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 252, 252),
      body: Column(
        children: [
          CustomHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(150.0),
              child: Container(
                padding: const EdgeInsets.all(30.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 15,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: 400,
                  child: Form(
                    key: formGlobalKey,

                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Bienvenido",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 30),
                        TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: "Correo Electronico",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'este campo es obligatorio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: "Contraseña",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            ElevatedButton(
                              onPressed: () {
                                if (formGlobalKey.currentState!.validate()) {
                                  enviarDatos('login');
                                }
                              },
                              child: Text("Iniciar Sesion"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "¿No tienes cuenta?",
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 5),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/register');
                              },
                              child: const Text(
                                "Registrate",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ], //children
      ),
    );
  }
}
