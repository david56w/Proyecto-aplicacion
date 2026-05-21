import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../login/widgets/amigos_page.dart';
import '../login/login_page.dart';

class DashboardPage extends StatefulWidget {
  final String userName;
  const DashboardPage({super.key, required this.userName});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  late TabController _tabController;
  final supabase = Supabase.instance.client;
  late String currentUserName; 
  int nivelActual = 1;
  double nivelProgreso = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    currentUserName = widget.userName;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, 
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.settings, color: Colors.white, size: 45),
                  SizedBox(height: 10),
                  Text(
                    "Configuración",
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: const Text("Mi Cuenta", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              subtitle: const Text("Editar nombre o cerrar sesión"),
              onTap: () { 
                Navigator.pop(context);
                _mostrarDialogoMiCuenta(context);
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _mostrarDialogoNuevaNota(context);
          } else {
            _mostrarDialogoNuevaMision(context);
          }
        },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            buildUserHeader(),
            TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(icon: Icon(Icons.note), text: "Notas"),
                Tab(icon: Icon(Icons.assignment), text: "Misiones"),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNotasTab(),
                  _buildMisionesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildUserHeader() {
    return Stack(
      children: [
        Container(
          height: 250,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 50, color: Colors.cyan),
              ),
              const SizedBox(height: 10),
              Text(
                currentUserName, 
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Niv: $nivelActual",
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: LinearProgressIndicator(
                  value: nivelProgreso,
                  backgroundColor: Colors.blue[900],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.lightBlueAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 10,
          left: 10,
          child: IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 28),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer(); 
            },
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: supabase.from('amistades').stream(primaryKey: ['id']),
            builder: (context, snapshot) {
              final tienePendientes = snapshot.hasData &&
                  snapshot.data!.any((sol) =>
                      sol['receiver_id'] == supabase.auth.currentUser!.id &&
                      sol['status'] == 'pendiente');

              return Badge(
                isLabelVisible: tienePendientes, 
                child: IconButton(
                  icon: const Icon(Icons.person_add, color: Colors.white, size: 28),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AmigosPage()),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotasTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('diario')
          .stream(primaryKey: ['id'])
          .eq('user_id', supabase.auth.currentUser!.id)
          .order('fecha'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final notas = snapshot.data!;
        
        if (notas.isEmpty) {
          return const Center(
            child: Text("No hay notas en tu diario", style: TextStyle(color: Colors.white70)),
          );
        }

        return ListView.builder(
          itemCount: notas.length,
          itemBuilder: (context, index) {
            final nota = notas[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          nota['titulo'] ?? 'Sin título',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          nota['contenido'] ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _botonBorrarNota(nota),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMisionesTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('misiones')
          .stream(primaryKey: ['id'])
          .eq('user_id', supabase.auth.currentUser!.id)
          .order('created_at'), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final misiones = snapshot.data ?? [];

        if (misiones.isEmpty) {
          return const Center(child: Text("No hay misiones, ¡Agrega una!"));
        }

        return ListView.builder(
          itemCount: misiones.length,
          itemBuilder: (context, index) {
            final mision = misiones[index];
            
            bool estaExpirada = false;
            String textoFecha = "Sin límite";
            if (mision['fecha_limite'] != null) {
              final fechaLimite = DateTime.parse(mision['fecha_limite']).toLocal();
              estaExpirada = DateTime.now().isAfter(fechaLimite);
              textoFecha = "${fechaLimite.day}/${fechaLimite.month} a las ${fechaLimite.hour}:${fechaLimite.minute.toString().padLeft(2, '0')}";
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: estaExpirada ? Colors.redAccent[700] : Colors.blueAccent,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mision['titulo'] ?? "Misión",
                          style: const TextStyle(
                            color: Colors.white, 
                            fontSize: 16, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          estaExpirada ? "⚠️ ¡EXPIRADA! ($textoFecha)" : "⏰ Límite: $textoFecha",
                          style: TextStyle(
                            color: estaExpirada ? Colors.white : Colors.white70,
                            fontSize: 12,
                            fontWeight: estaExpirada ? FontWeight.bold : FontWeight.normal
                          ),
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: mision['completada'] ?? false,
                    activeColor: Colors.white,
                    checkColor: estaExpirada ? Colors.redAccent[700] : Colors.blueAccent,
                    onChanged: (value) async {
                      if (value == true) {
                        setState(() {
                          if (estaExpirada) {
                            nivelProgreso -= 0.1;
                            if (nivelProgreso < 0.0) {
                              if (nivelActual > 1) {
                                nivelActual--;
                                nivelProgreso = 0.9;
                              } else {
                                nivelProgreso = 0.0;
                              }
                            }
                          } else {
                            nivelProgreso += 0.1;
                            if (nivelProgreso >= 1.0) {
                              nivelProgreso = 0.0;
                              nivelActual++;
                            }
                          }
                        });

                        await supabase.from('misiones').delete().eq('id', mision['id']);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarDialogoNuevaNota(BuildContext context) {
    final tituloController = TextEditingController();
    final contenidoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nueva Nota"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tituloController,
              decoration: const InputDecoration(hintText: "Título (opcional)"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contenidoController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: "Contenido de la nota..."),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (contenidoController.text.isNotEmpty) {
                final navigator = Navigator.of(context);
                
                await supabase.from('diario').insert({
                  'user_id': supabase.auth.currentUser!.id,
                  'titulo': tituloController.text.trim().isEmpty 
                      ? 'Sin título' 
                      : tituloController.text.trim(),
                  'contenido': contenidoController.text.trim(), 
                }).select().single();

                if (mounted) navigator.pop();
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoNuevaMision(BuildContext context) {
    final controller = TextEditingController();
    DateTime? fechaSeleccionada;
    TimeOfDay? horaSeleccionada;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Nueva Misión"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller, 
                decoration: const InputDecoration(hintText: "ej: estudiar flutter 1h"),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Plazo límite:", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_month),
                    label: Text(fechaSeleccionada == null 
                        ? "Definir" 
                        : "${fechaSeleccionada!.day}/${fechaSeleccionada!.month}"),
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null) {
                        setDialogState(() => fechaSeleccionada = pickedDate);
                      }
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Hora límite:", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    icon: const Icon(Icons.access_time),
                    label: Text(horaSeleccionada == null 
                        ? "Definir" 
                        : "${horaSeleccionada!.hour}:${horaSeleccionada!.minute.toString().padLeft(2, '0')}"),
                    onPressed: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        setDialogState(() => horaSeleccionada = pickedTime);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  final navigator = Navigator.of(context);

                  String? fechaLimiteIso;
                  if (fechaSeleccionada != null && horaSeleccionada != null) {
                    final finalDateTime = DateTime(
                      fechaSeleccionada!.year,
                      fechaSeleccionada!.month,
                      fechaSeleccionada!.day,
                      horaSeleccionada!.hour,
                      horaSeleccionada!.minute,
                    );
                    fechaLimiteIso = finalDateTime.toIso8601String();
                  }

                  await supabase.from('misiones').insert({
                    'user_id': supabase.auth.currentUser!.id,
                    'titulo': controller.text.trim(),
                    'completada': false,
                    'fecha_limite': fechaLimiteIso,
                  });
                  
                  if (mounted) {
                    navigator.pop();
                  }
                }
              },
              child: const Text("Guardar"),
            ),
          ],
        ),
      ),
    );
  }

void _mostrarDialogoMiCuenta(BuildContext context) {
    final nombreController = TextEditingController(text: currentUserName);

    showDialog(
      context: context,
      builder: (context) {
        final navigator = Navigator.of(context);
        return AlertDialog(
          title: const Text("Configuración de la Cuenta"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: "Nombre de Usuario",
                  icon: Icon(Icons.edit),
                ),
              ),
            ],
          ),
          actions: [
            // --- BOTÓN 1: BORRAR CUENTA (ABRE CONFIRMACIÓN) ---
            TextButton(
              onPressed: () {
                navigator.pop(); // Cierra el diálogo actual de configuración
                _mostrarDialogoConfirmarBorrarCuenta(context); // Abre el de peligro
              },
              child: const Text("Borrar Cuenta", style: TextStyle(color: Colors.red)),
            ),

            // --- BOTÓN 2: CERRAR SESIÓN ---
            TextButton(
              onPressed: () async {
                try {
                  await supabase.auth.signOut();
                  if (mounted) {
                    navigator.pop(); 
                    navigator.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (Route<dynamic> route) => false,
                    );
                  }
                } catch (e) {
                  debugPrint("Error al cerrar sesión: $e");
                }
              },
              child: const Text("Cerrar Sesión", style: TextStyle(color: Colors.orange)),
            ),

            // --- BOTÓN 3: GUARDAR CAMBIOS ---
            ElevatedButton(
              onPressed: () async {
                final nuevoNombre = nombreController.text.trim();
                if (nuevoNombre.isNotEmpty) {
                  try {
                    final user = supabase.auth.currentUser;
                    if (user != null) {
                      await supabase.from('profiles').update({'username': nuevoNombre}).eq('id', user.id);
                      if (mounted) {
                        setState(() {
                          currentUserName = nuevoNombre;
                        });
                        navigator.pop();
                      }
                    }
                  } catch (e) {
                    debugPrint("Error al guardar: $e");
                  }
                }
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoConfirmarBorrarCuenta(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final navigator = Navigator.of(context);
        final messenger = ScaffoldMessenger.of(context);
        return AlertDialog(
          title: const Text("¿ELIMINAR CUENTA?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          content: const Text("Cuidado: Esto eliminará tus datos de perfil y cerrará tu sesión de forma permanente. Esta acción no se puede deshacer."),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  final user = supabase.auth.currentUser;
                  if (user != null) {
                    await supabase.from('profiles').delete().eq('id', user.id);
                    
                    await supabase.auth.signOut();

                    if (mounted) {
                      navigator.pop();
                      navigator.pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                        (Route<dynamic> route) => false,
                      );
                      messenger.showSnackBar(
                        const SnackBar(content: Text("Cuenta eliminada correctamente.")),
                      );
                    }
                  }
                } catch (e) {
                  debugPrint("Error al eliminar cuenta: $e");
                }
              },
              child: const Text("Sí, Eliminar Todo", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _botonBorrarNota(Map<String, dynamic> nota) {
    return IconButton(
      icon: const Icon(Icons.delete_outline, color: Colors.white70),
      onPressed: () async {
        final idDeLaNota = nota['id'];
        if (idDeLaNota == null) return;

        final messenger = ScaffoldMessenger.of(context);

        try {
          await supabase
              .from('diario')
              .delete()
              .match({
                'id': idDeLaNota,
                'user_id': supabase.auth.currentUser!.id
              });

          if (mounted) {
            messenger.showSnackBar(
              const SnackBar(content: Text("Nota eliminada")),
            );
          }
        } catch (error) {
          debugPrint("Error al borrar nota: $error");
        }
      },
    );
  }
}