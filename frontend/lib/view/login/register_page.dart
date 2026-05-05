import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Cambio: Importa Supabase
import '../dashboard/dashboard.dart';
import 'widgets/custom_header.dart';

// Definimos el cliente de Supabase (asumiendo que lo inicializaste en main.dart)
final supabase = Supabase.instance.client;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final formGlobalKey = GlobalKey<FormState>();
  bool _obscureText = true;
  bool _isLoading = false;
  
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // 1. REEMPLAZAMOS enviarDatos POR LA LÓGICA DE SUPABASE
  Future<void> _handleRegister() async {
    if (!formGlobalKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Paso A: Crear el usuario en auth.users (Correo y Contraseña)
      final AuthResponse res = await supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = res.user;

      // Paso B: Si se creó el usuario, insertar el Username en la tabla 'profiles'
      if (user != null) {
        await supabase.from('profiles').insert({
          'id': user.id, // El ID que generó Supabase Auth
          'username': nameController.text.trim(), // Tu controlador del Alias
          'nivel': 1,
          'experiencia': 0,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Registro exitoso!')),
          );
          
          // Navegamos al Dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardPage(userName: nameController.text,)),
          );
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ocurrió un error inesperado'), backgroundColor: Colors.red),
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
      body: SafeArea(
        child: Column(
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
                          // NOMBRE DE USUARIO (Para la tabla profiles)
                          TextFormField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: "Nombre de Usuario",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (value) => (value == null || value.isEmpty) ? 'Campo obligatorio' : null,
                          ),
                          const SizedBox(height: 30),
                          // EMAIL (Para auth.users)
                          TextFormField(
                            controller: emailController,
                            decoration: InputDecoration(
                              labelText: "Correo Electrónico",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (value) => (value == null || value.isEmpty) ? 'Campo obligatorio' : null,
                          ),
                          const SizedBox(height: 20),
                          // CONTRASEÑA (Para auth.users)
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
                                onPressed: _isLoading? null: () async {
                                  setState(() { _isLoading = true;
                                        });
                          await Future.delayed(
                          const Duration(seconds: 2),
                                        );
                            setState(() { _isLoading = false;
                                        });
                          if (formGlobalKey.currentState!.validate()) {//await enviarDatos('login'); comentado hasta hacer la DB
                          if (context.mounted) {
                            Navigator.pushReplacement(context,
                            MaterialPageRoute(builder: (context) =>
                            DashboardPage(userName: nameController.text,),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                child: _isLoading ?
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,),)
                                    :const Text("Inicia Sesion"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          // BOTÓN PARA IR A LOGIN
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/login'),
                            child: const Text('Inicia Sesión', style: TextStyle(decoration: TextDecoration.underline)),
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
       ), //children
      ),
    );
  }
}