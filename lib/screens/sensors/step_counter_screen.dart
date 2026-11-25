import 'package:material_ui/material_ui.dart';

/// Pantalla provisional: Sensor de pasos.
class StepCounterScreen extends StatelessWidget {
  /// Crea la pantalla.
  const StepCounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sensor de pasos')),
      body: const Center(child: Text('En construcción')),
    );
  }
}
