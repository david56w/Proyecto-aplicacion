import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiarioPage extends StatefulWidget {
  const DiarioPage({super.key});

  @override
  State<DiarioPage> createState() => _DiarioPageState();
}

class _DiarioPageState extends State<DiarioPage> {
  final _tituloController = TextEditingController();
  final _contenidoController = TextEditingController();
  final supabase = Supabase.instance.client;
  bool _isSaving = false;

  Future<void> _guardarNota() async {
    if (_contenidoController.text.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final userId = supabase.auth.currentUser!.id;
      
      await supabase.from('diario').insert({
        'user_id': userId,
        'titulo': _tituloController.text,
        'contenido': _contenidoController.text,
      });

      if (mounted) {
        Navigator.pop(context); // Regresa al dashboard al terminar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nota guardada en el diario')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva entrada del Diario')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(labelText: 'Título (Opcional)'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: TextField(
                controller: _contenidoController,
                maxLines: null, // Crece según escribes
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: '¿Cómo estuvo tu día hoy?',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _guardarNota,
              child: _isSaving ? const CircularProgressIndicator() : const Text('Guardar Nota'),
            ),
          ],
        ),
      ),
    );
  }
}