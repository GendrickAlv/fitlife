import 'package:material_ui/material_ui.dart';

/// Pantalla provisional: Progreso.
class StatsScreen extends StatelessWidget {
  /// Crea la pantalla.
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progreso')),
      body: const Center(child: Text('En construcción')),
    );
  }
}
