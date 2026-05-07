import 'package:flutter/material.dart';
import 'package:travelex/view/login/widgets/diario_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardPage extends StatefulWidget {
  final String userName;
   const DashboardPage({super.key, required this.userName});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}
class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> misMisiones=[
  {"Titulo": "Hacer tarea", "Completada": false},];
  List<String> misNotas = [
    'Comprar leche',
    'estudiar flutter',
  ]; //lista de ejemplo mientras esta lista la DB.
  int nivelActual = 1;
  double nivelProgreso = 0.0; //la exp subira al 40%.

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton:
      FloatingActionButton(onPressed: () {
        
          _mostrarDialogoNuevaMision(context);
        
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
              Tab(icon: Icon(Icons.note), text: "Diario",),
              Tab(icon: Icon(Icons.assignment), text: "Misiones",)
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDiarioTab(),
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
    return Container(
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
            widget.userName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Niv: $nivelActual",
            style: TextStyle(color: Colors.white70,
            fontSize: 16),
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
    );
  }
      Widget _buildDiarioTab() {
        return Column(
          children: [
            Padding(padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const DiarioPage()),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text("Escribir en el diario"),
              ),
              ),
              Expanded(child: _buildListaDiarioRealTime(),
              ),
          ],
        );
        }

        Widget _buildListaDiarioRealTime() {
  final supabase = Supabase.instance.client;

  return StreamBuilder<List<Map<String, dynamic>>>(
    // Esto conecta con tu tabla de Supabase en tiempo real
    stream: supabase.from('diario').stream(primaryKey: ['id']).order('fecha'),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Center(child: Text("Aún no tienes notas en tu diario"));
      }

      final notas = snapshot.data!;

      return ListView.builder(
        itemCount: notas.length,
        itemBuilder: (context, index) {
          final nota = notas[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blueAccent,
            child: ListTile(
              title: Text(
                nota['titulo'] ?? 'Sin título',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                nota['contenido'] ?? '',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          );
        },
      );
    },
  );
}

      Widget _buildMisionesTab() {
        if (misMisiones.isEmpty){
          return const Center(child: Text("No hay misiones, ¡Agrega una!"));
        }

        return ListView.builder(
          itemCount: misMisiones.length,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(
                    (misMisiones[index]["Titulo"] ?? "Mision").toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Checkbox(value: misMisiones[index]["Completada"] == true,
                  activeColor: Colors.white,
                  checkColor: Colors.blueAccent,
                  onChanged: (value) {
                    setState(() {
                      misMisiones[index]["Completada"] = value;
                      if (value == true) {
                        nivelProgreso += 0.1;
                        if (nivelProgreso >= 1.0) {
                          nivelProgreso = 0.0;
                          nivelActual++;
                        }
                      }
                    });
                  },
                  ),
                ],
              ),
            );
          }
        );
  }

  void _mostrarDialogoNuevaMision(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(context: context,
    builder: (context){
      return AlertDialog(
        title: const Text("Nueva Mision"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "ej: estudiar flutter 1h"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar"),
          ),
          ElevatedButton(onPressed: () {
            if (controller.text.isNotEmpty){
            setState(() {
              misMisiones.add({
                "Titulo": controller.text,
                "Completada": false,
              });
            });
            controller.clear();
            Navigator.pop(context);
            }
          },
          child: const Text("Guardar"),
          ),
        ],
      );
    },
    );
  }
}