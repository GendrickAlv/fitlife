import 'package:material_ui/material_ui.dart';

/// Pantalla provisional: Inicio.
class DashboardScreen extends StatelessWidget {
  /// Crea la pantalla.
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio')),
      body: const Center(child: Text('En construcción')),
    );
  }
}
