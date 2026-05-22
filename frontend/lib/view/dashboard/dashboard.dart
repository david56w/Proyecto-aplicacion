import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../login/widgets/amigos_page.dart';
import '../login/login_page.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
  String? avatarUrl;
  int nivelActual = 1;
  double nivelProgreso = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    currentUserName = widget.userName;
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final datos = await supabase
            .from('profiles')
            .select('avatar_url, username, nivel, progreso')
            .eq('id', user.id)
            .maybeSingle();

        if (datos != null) {
          setState(() {
            if (datos['avatar_url'] != null) avatarUrl = datos['avatar_url'];
            if (datos['username'] != null) currentUserName = datos['username'];
            if (datos['nivel'] != null) nivelActual = datos['nivel'];
            if (datos['progreso'] != null) nivelProgreso = (datos['progreso'] as num).toDouble();
          });
        }
      }
    } catch (e) {
      debugPrint("Error al cargar los datos del usuario: $e");
    }
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
              GestureDetector(
                onTap: _cambiarFotoPerfil, 
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                  child: avatarUrl == null
                      ? const Icon(Icons.person, size: 50, color: Colors.cyan)
                      : null,
                ),
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
                            color: Colors.white,
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
                          estaExpirada ? "¡EXPIRADA! ($textoFecha)" : "Límite: $textoFecha",
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

                        try {
                          final user = supabase.auth.currentUser;
                          if (user != null) {
                            await supabase.from('profiles').update({
                              'nivel': nivelActual,
                              'progreso': nivelProgreso,
                            }).eq('id', user.id);
                          }

                          await supabase.from('misiones').delete().eq('id', mision['id']);
                        } catch (e) {
                          debugPrint("Error al actualizar experiencia: $e");
                        }
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
          backgroundColor: Colors.white, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Nueva Misión", 
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller, 
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: "ej: estudiar flutter 1h",
                  hintStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () async {
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: fechaSeleccionada == null ? Colors.grey[100] : Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: fechaSeleccionada == null ? Colors.black12 : Colors.blue),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month, size: 18, color: fechaSeleccionada == null ? Colors.grey : Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            fechaSeleccionada == null ? "Fecha" : "${fechaSeleccionada!.day}/${fechaSeleccionada!.month}",
                            style: TextStyle(color: fechaSeleccionada == null ? Colors.grey[700] : Colors.blue[900], fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),

                  InkWell(
                    onTap: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                        initialEntryMode: TimePickerEntryMode.inputOnly, 
                        builder: (BuildContext context, Widget? child) {
                          return MediaQuery(
                            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                            child: Theme(
                              data: ThemeData.light().copyWith( 
                                colorScheme: const ColorScheme.light(
                                  primary: Colors.blue, 
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Colors.black87,
                                ),
                                timePickerTheme: TimePickerThemeData(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  inputDecorationTheme: InputDecorationTheme(
                                    fillColor: Colors.blue.withValues(alpha: 0.05),
                                    filled: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                              child: child!,
                            ),
                          );
                        },
                      );
                      if (pickedTime != null) {
                        setDialogState(() => horaSeleccionada = pickedTime);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: horaSeleccionada == null ? Colors.grey[100] : Colors.cyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: horaSeleccionada == null ? Colors.black12 : Colors.cyan),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 18, color: horaSeleccionada == null ? Colors.grey : Colors.cyan[800]),
                          const SizedBox(width: 8),
                          Text(
                            horaSeleccionada == null 
                                ? "Hora" 
                                : "${horaSeleccionada!.hourOfPeriod == 0 ? 12 : horaSeleccionada!.hourOfPeriod}:${horaSeleccionada!.minute.toString().padLeft(2, '0')} ${horaSeleccionada!.period.name.toUpperCase()}",
                            style: TextStyle(color: horaSeleccionada == null ? Colors.grey[700] : Colors.cyan[900], fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  final navigator = Navigator.of(context);

                  String? fechaLimiteIso;
                  if (fechaSeleccionada != null && horaSeleccionada != null) {
                    final finalDateTimeLocal = DateTime(
                      fechaSeleccionada!.year,
                      fechaSeleccionada!.month,
                      fechaSeleccionada!.day,
                      horaSeleccionada!.hour,
                      horaSeleccionada!.minute,
                    );
                    
                    fechaLimiteIso = finalDateTimeLocal.toUtc().toIso8601String();
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
              child: const Text("Guardar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            TextButton(
              onPressed: () {
                navigator.pop(); 
                _mostrarDialogoConfirmarBorrarCuenta(context); 
              },
              child: const Text("Borrar Cuenta", style: TextStyle(color: Colors.red)),
            ),

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

  Future<void> _cambiarFotoPerfil() async {
    final messenger = ScaffoldMessenger.of(context);
    final picker = ImagePicker();
    
    final XFile? imagenSeleccionada = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, 
    );

    if (imagenSeleccionada == null) return; 

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final file = File(imagenSeleccionada.path);
      final String extension = imagenSeleccionada.path.split('.').last;
      final String pathArchivo = '${user.id}/avatar.$extension';

      await supabase.storage.from('avatars').upload(
        pathArchivo,
        file,
        fileOptions: const FileOptions(upsert: true), 
      );

      final String urlPublica = supabase.storage.from('avatars').getPublicUrl(pathArchivo);

      await supabase.from('profiles').update({
        'avatar_url': urlPublica,
      }).eq('id', user.id);

      if (mounted) {
        setState(() {
          avatarUrl = urlPublica;
        });
        messenger.showSnackBar(
          const SnackBar(content: Text("¡Foto de perfil actualizada!")),
        );
      }
    } catch (e) {
      debugPrint("Error al subir foto de perfil: $e");
    }
  }
 }