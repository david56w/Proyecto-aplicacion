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

  // --- 1. LÓGICA DE BÚSQUEDA ---
  Future<void> _buscarUsuario(String query) async {
    if (query.isEmpty) return;

    final data = await supabase
        .from('profiles') 
        .select()
        .ilike('username', '%$query%')
        .neq('id', supabase.auth.currentUser!.id); // No mostrarse a uno mismo

    setState(() {
      _usuariosEncontrados = List<Map<String, dynamic>>.from(data);
    });
  }

  Future<void> _enviarSolicitud(String receiverId) async {
    try {
      await supabase.from('amistades').insert({
        'sender_id': supabase.auth.currentUser!.id,
        'receiver_id': receiverId,
        'status': 'pendiente',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Solicitud enviada!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ya existe una solicitud con este usuario")),
        );
      }
    }
  }

  Future<void> _responderSolicitud(String id, String nuevoEstado) async {
    await supabase.from('amistades').update({'status': nuevoEstado}).eq('id', id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestión de Amigos"),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          _buildSolicitudesRecibidas(),
          
          const Divider(),

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
            child: _usuariosEncontrados.isEmpty 
              ? const Center(child: Text("Busca a alguien por su nombre"))
              : ListView.builder(
                  itemCount: _usuariosEncontrados.length,
                  itemBuilder: (context, index) {
                    final user = _usuariosEncontrados[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(user['username'] ?? 'Usuario'),
                      trailing: ElevatedButton(
                        onPressed: () => _enviarSolicitud(user['id']),
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

Widget _buildSolicitudesRecibidas() {
  return StreamBuilder<List<Map<String, dynamic>>>(
    stream: supabase
        .from('amistades')
        .stream(primaryKey: ['id']), 

    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const SizedBox();
      }

      final solicitudes = snapshot.data!.where((sol) => 
        sol['receiver_id'] == supabase.auth.currentUser!.id && 
        sol['status'] == 'pendiente'
      ).toList();

      if (solicitudes.isEmpty) return const SizedBox();

      return Container(
        padding: const EdgeInsets.all(8.0),
        color: Colors.blue.withValues(alpha: 0.1), 
        child: Column(
          children: [
            const Text("Solicitudes Pendientes", style: TextStyle(fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: solicitudes.length,
              itemBuilder: (context, index) {
                final sol = solicitudes[index];
                return ListTile(
                  title: const Text("Nueva solicitud"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _responderSolicitud(sol['id'], 'aceptada'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _responderSolicitud(sol['id'], 'rechazada'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    }, 
  ); 
}
}