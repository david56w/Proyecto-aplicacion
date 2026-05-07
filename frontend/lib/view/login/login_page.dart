import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Importa Supabase
import 'widgets/custom_header.dart';
import '../dashboard/dashboard.dart';

// Cliente de Supabase
final supabase = Supabase.instance.client;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscureText = true;
  bool _isLoading = false;
  final formGlobalKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // 1. NUEVA FUNCIÓN DE LOGIN PARA SUPABASE
  Future<void> _handleLogin() async {
    if (!formGlobalKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Intenta iniciar sesión con correo y contraseña
      final AuthResponse res = await supabase.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (res.user != null && mounted) {
        // Si todo sale bien, vamos al Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>  DashboardPage(userName: emailController.text.trim()),),
        );
      }
    } on AuthException catch (error) {
      // Si el correo o contraseña son incorrectos, Supabase nos da el mensaje
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message), // Ejemplo: "Invalid login credentials"
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error inesperado'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  margin: const EdgeInsets.only(top: 80),
                  padding: const EdgeInsets.all(70),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
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
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 30),
                          TextFormField(
                            controller: emailController,
                            decoration: InputDecoration(
                              labelText: "Correo Electrónico",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (value) => (value == null || value.isEmpty) ? 'Campo obligatorio' : null,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: passwordController,
                            obscureText: _obscureText,
                            decoration: InputDecoration(
                              labelText: "Contraseña",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _obscureText = !_obscureText),
                              ),
                            ),
                            validator: (value) => (value == null || value.isEmpty) ? 'Campo obligatorio' : null,
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin, // Llamada a Supabase
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Colors.blue, strokeWidth: 2),
                                      )
                                    : const Text("Inicia Sesión"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text("¿No tienes cuenta?", style: TextStyle(color: Colors.black54, fontSize: 14)),
                              const SizedBox(height: 5),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, '/register'),
                                child: const Text(
                                  "Regístrate",
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
          ),
        ],
      ),
    );
  }
}