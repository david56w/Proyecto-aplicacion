import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AmigosPage extends StatefulWidget {
  const AmigosPage({super.key});

  @override
  State<AmigosPage> createState() => _AmigosPageState();
}

class _AmigosPageState extends State<AmigosPage> {
  final TextEditingController _searchController = TextEditingController();
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _usuariosEncontrados = [];

  // Función para buscar usuarios en la tabla 'profiles'
  Future<void> _buscarUsuario(String query) async {
    if (query.isEmpty) return;

    final data = await supabase
        .from('profiles') // Asegúrate de tener una tabla de perfiles
        .select()
        .ilike('username', '%$query%'); // Busca nombres parecidos

    setState(() {
      _usuariosEncontrados = List<Map<String, dynamic>>.from(data);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buscar Amigos"),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Nombre de usuario...",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _buscarUsuario(_searchController.text),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onSubmitted: _buscarUsuario,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _usuariosEncontrados.length,
              itemBuilder: (context, index) {
                final user = _usuariosEncontrados[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(user['username'] ?? 'Usuario'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Aquí irá la lógica para enviar solicitud
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Solicitud enviada (próximamente)")),
                      );
                    },
                    child: const Text("Agregar"),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}