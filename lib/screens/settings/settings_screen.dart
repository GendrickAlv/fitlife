import 'package:material_ui/material_ui.dart';

/// Pantalla provisional: Perfil y ajustes.
class SettingsScreen extends StatelessWidget {
  /// Crea la pantalla.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil y ajustes')),
      body: const Center(child: Text('En construcción')),
    );
  }
}
