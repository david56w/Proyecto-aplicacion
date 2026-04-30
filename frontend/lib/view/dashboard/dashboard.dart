import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}
class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> misMisiones=[
  {"titulo": "Mision de prueba", "Completada": false},];
  List<String> misNotas = [
    'Comprar leche',
    'estudiar flutter',
  ]; //lista de ejemplo mientras esta lista la DB.
  int nivel = 1;
  double experiencia = 4.0; //la exp subira al 40%.

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
      FloatingActionButton(onPressed: () =>
      _mostrarDialogoNuevaMision(context),
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
              Tab(icon: Icon(Icons.note), text: "Notas",),
              Tab(icon: Icon(Icons.assignment), text: "Misiones",)
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
          const Text(
            "user",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            "Niv: 1",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: LinearProgressIndicator(
              value: 0.4,
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
      Widget _buildNotasTab() {
        return ListView.builder(
          itemCount: misNotas.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: const Icon(Icons.note_alt),
              title: Text(misNotas[index]),
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
            return CheckboxListTile(
              title: Text(misMisiones[index]["titulo"]),
              value: misMisiones[index]["Completada"],
              onChanged: (bool? valor){
                setState(() {
                  misMisiones[index]["Completada"] = valor;
                });
              },
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
                "titulo": controller.text,
                "COmpletada": false,
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
