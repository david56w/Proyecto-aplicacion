import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AmigosPage extends StatefulWidget {
  const AmigosPage({super.key});

  @override
  State<AmigosPage> createState() => _AmigosPageState();
}

class _AmigosPageState extends State<AmigosPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _usuariosEncontrados = [];
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _obtenerInicioSemanaIso() {
    final ahora = DateTime.now();
    final diasRestar = ahora.weekday - 1; 
    final lunes = DateTime(ahora.year, ahora.month, ahora.day).subtract(Duration(days: diasRestar));
    return lunes.toUtc().toIso8601String();
  }

  String _obtenerInicioMesIso() {
    final ahora = DateTime.now();
    final primerDiaMes = DateTime(ahora.year, ahora.month, 1);
    return primerDiaMes.toUtc().toIso8601String();
  }

  Future<List<Map<String, dynamic>>> _obtenerRanking(bool esSemanal) async {
    final myId = supabase.auth.currentUser!.id;
    final fechaFiltro = esSemanal ? _obtenerInicioSemanaIso() : _obtenerInicioMesIso();
    final periodoActual = esSemanal ? 'semanal' : 'mensual';

    try {
      final listaAmistades = await supabase
          .from('amistades')
          .select('sender_id, receiver_id')
          .eq('status', 'aceptada');

      final Set<String> idsParaRanking = {myId};
      for (var amistar in listaAmistades) {
        final sender = amistar['sender_id'];
        final receiver = amistar['receiver_id'];
        if (sender == myId) {
        idsParaRanking.add(receiver);
        } else if (receiver == myId) {
        idsParaRanking.add(sender);
        }
       }

      final perfiles = await supabase
          .from('profiles')
          .select('id, username, avatar_url')
          .inFilter('id', idsParaRanking.toList());

      final List<Map<String, dynamic>> rankingFinal = [];

      for (var perfil in perfiles) {
        final userId = perfil['id'];
        
        final misiones = await supabase
            .from('misiones')
            .select('id')
            .eq('user_id', userId)
            .eq('completada', true)
            .gte('completada_at', fechaFiltro);

        final victorias = await supabase
            .from('historial_ganadores')
            .select('id')
            .eq('user_id', userId)
            .eq('tipo_periodo', periodoActual);

        rankingFinal.add({
          'username': perfil['username'] ?? 'Sin nombre',
          'avatar_url': perfil['avatar_url'],
          'total': misiones.length,
          'victorias_top1': victorias.length, 
          'esYo': userId == myId,
        });
      }

      rankingFinal.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
      return rankingFinal;

    } catch (e) {
      debugPrint("Error al obtener ranking: $e");
      return [];
    }
  }

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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Comunidad y Ranking", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.emoji_events), text: "Semanal"),
            Tab(icon: Icon(Icons.military_tech), text: "Mensual"),
            Tab(icon: Icon(Icons.people), text: "Mis Amigos"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListaRanking(esSemanal: true),  
          _buildListaRanking(esSemanal: false), 
          _buildPestanaGestionAmigos(),         
        ],
      ),
    );
  }

  Widget _buildListaRanking({required bool esSemanal}) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _obtenerRanking(esSemanal),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final ranking = snapshot.data ?? [];

        if (ranking.isEmpty) {
          return const Center(
            child: Text("No hay misiones completadas en este periodo.", style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: ranking.length,
          itemBuilder: (context, index) {
            final usuario = ranking[index];
            final posicion = index + 1;
            final esYo = usuario['esYo'] ?? false;

            Color colorPosicion = Colors.grey[600]!;
            if (posicion == 1) { colorPosicion = Colors.amber; }
            if (posicion == 2) { colorPosicion = Colors.grey[400]!; }
            if (posicion == 3) { colorPosicion = Colors.brown[300]!; }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: esYo ? Colors.blue.withValues(alpha: 0.08) : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: esYo ? Colors.blue : Colors.black12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(color: colorPosicion, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        posicion.toString(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      backgroundColor: Colors.grey[200],
                      backgroundImage: usuario['avatar_url'] != null ? NetworkImage(usuario['avatar_url']) : null,
                      child: usuario['avatar_url'] == null ? const Icon(Icons.person, color: Colors.blue) : null,
                    ),
                  ],
                ),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      esYo ? "${usuario['username']} (Tú)" : usuario['username'],
                      style: TextStyle(
                        fontWeight: esYo ? FontWeight.bold : FontWeight.w500,
                        color: esYo ? Colors.blue[900] : Colors.black87,
                      ),
                    ),
                    if (usuario['victorias_top1'] != null && usuario['victorias_top1'] > 0) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.workspace_premium, color: Colors.amber, size: 18),
                      const SizedBox(width: 2),
                      Text(
                        "${usuario['victorias_top1']}",
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${usuario['total']} hechas",
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPestanaGestionAmigos() {
    return Column(
      children: [
        _buildSolicitudesRecibidas(),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.black87),
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
              child: Text("Mis Amigos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: amigos.length,
                itemBuilder: (context, index) {
                  final amistad = amigos[index];
                  final amigoId = amistad['sender_id'] == supabase.auth.currentUser!.id
                      ? amistad['receiver_id']
                      : amistad['sender_id'];

                  return FutureBuilder(
                    future: supabase.from('profiles').select('username, avatar_url').eq('id', amigoId).single(),
                    builder: (context, AsyncSnapshot<Map<String, dynamic>> userSnap) {
                      final nombre = userSnap.data?['username'] ?? "Cargando...";
                      final urlFoto = userSnap.data?['avatar_url'];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          backgroundImage: urlFoto != null ? NetworkImage(urlFoto) : null,
                          child: urlFoto == null ? const Icon(Icons.person, color: Colors.blue) : null,
                        ),
                        title: Text(nombre, style: const TextStyle(color: Colors.black87)),
                        subtitle: const Text("Amigo"),
                        trailing: IconButton(
                          icon: const Icon(Icons.person_remove, color: Colors.redAccent),
                          tooltip: "Eliminar amigo",
                          onPressed: userSnap.hasData 
                              ? () => _mostrarDialogoConfirmarEliminar(context, amigoId, nombre)
                              : null, 
                        ),
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
                child: Text("Solicitudes Pendientes", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
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
                        title: Text("Solicitud de: $nombre", style: const TextStyle(color: Colors.black87)),
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

  Future<void> _eliminarAmistad(String amigoId) async {
    final myId = supabase.auth.currentUser!.id;

    try {
      await supabase
          .from('amistades')
          .delete()
          .or('and(sender_id.eq.$myId,receiver_id.eq.$amigoId),and(sender_id.eq.$amigoId,receiver_id.eq.$myId)');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Amistad eliminada correctamente")),
        );
      }
    } catch (e) {
      debugPrint("Error al eliminar amistad: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo eliminar la amistad")),
        );
      }
    }
  }

  void _mostrarDialogoConfirmarEliminar(BuildContext context, String amigoId, String nombreAmigo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar Amigo"),
        content: Text("¿Estás seguro de que quieres eliminar a $nombreAmigo de tu lista de amigos?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _eliminarAmistad(amigoId);
              navigator.pop();
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
 }