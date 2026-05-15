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

  Future<void> _buscarUsuario(String query) async {
    if (query.isEmpty) {
      setState(() => _usuariosEncontrados = []);
      return;
    }

    final data = await supabase
        .from('profiles')
        .select()
        .ilike('username', '%$query%')
        .neq('id', supabase.auth.currentUser!.id);

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
    try {
      await supabase
          .from('amistades')
          .update({'status': nuevoEstado})
          .eq('id', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Solicitud $nuevoEstado")),
        );
      }
    } catch (e) {
      debugPrint("Error al responder: $e");
    }
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
              onChanged: (value) {
                if (value.isEmpty) setState(() => _usuariosEncontrados = []);
              },
              onSubmitted: _buscarUsuario,
            ),
          ),

          Expanded(
            child: _searchController.text.isNotEmpty
                ? _buildResultadosBusqueda()
                : _buildListaAmigosAceptados(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultadosBusqueda() {
    if (_usuariosEncontrados.isEmpty) {
      return const Center(child: Text("No se encontraron usuarios"));
    }
    return ListView.builder(
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
    );
  }

  Widget _buildListaAmigosAceptados() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('amistades').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final amigos = snapshot.data!.where((sol) {
          return sol['status'] == 'aceptada' &&
              (sol['sender_id'] == supabase.auth.currentUser!.id ||
                  sol['receiver_id'] == supabase.auth.currentUser!.id);
        }).toList();

        if (amigos.isEmpty) {
          return const Center(child: Text("Aún no tienes amigos agregados"));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text("Mis Amigos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: amigos.length,
                itemBuilder: (context, index) {
                  final amistad = amigos[index];
                  // El ID del amigo es el que NO soy yo
                  final amigoId = amistad['sender_id'] == supabase.auth.currentUser!.id
                      ? amistad['receiver_id']
                      : amistad['sender_id'];

                  return FutureBuilder(
                    future: supabase.from('profiles').select('username').eq('id', amigoId).single(),
                    builder: (context, AsyncSnapshot<Map<String, dynamic>> userSnap) {
                      final nombre = userSnap.data?['username'] ?? "Cargando...";
                      return ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.person, color: Colors.white)),
                        title: Text(nombre),
                        subtitle: const Text("Amigo"),
                        trailing: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSolicitudesRecibidas() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('amistades').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox();

        final solicitudes = snapshot.data!.where((sol) {
          return sol['receiver_id'] == supabase.auth.currentUser!.id && sol['status'] == 'pendiente';
        }).toList();

        if (solicitudes.isEmpty) return const SizedBox();

        return Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Solicitudes Pendientes", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: solicitudes.length,
                itemBuilder: (context, index) {
                  final sol = solicitudes[index];
                  return FutureBuilder(
                    future: supabase.from('profiles').select('username').eq('id', sol['sender_id']).single(),
                    builder: (context, AsyncSnapshot<Map<String, dynamic>> userSnap) {
                      if (!userSnap.hasData) return const ListTile(title: Text("Cargando..."));
                      final nombre = userSnap.data!['username'];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text("Solicitud de: $nombre"),
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