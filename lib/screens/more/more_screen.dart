import 'package:material_ui/material_ui.dart';

import '../challenges/challenges_screen.dart';
import '../hydration/hydration_screen.dart';
import '../sensors/step_counter_screen.dart';
import '../settings/settings_screen.dart';
import '../weight/weight_screen.dart';

/// Menú "Más" con accesos a las pantallas secundarias.
class MoreScreen extends StatelessWidget {
  /// Crea la pantalla.
  const MoreScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Más')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.monitor_weight_outlined),
            title: const Text('Peso'),
            subtitle: const Text('Seguimiento de tu peso corporal'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(context, const WeightScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.water_drop_outlined),
            title: const Text('Hidratación'),
            subtitle: const Text('Registra el agua que bebes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(context, const HydrationScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: const Text('Desafíos semanales'),
            subtitle: const Text('Ponte metas cada semana'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(context, const ChallengesScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.directions_walk),
            title: const Text('Sensor de pasos'),
            subtitle: const Text('Cuenta tus pasos con el acelerómetro'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(context, const StepCounterScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Perfil y ajustes'),
            subtitle: const Text('Metas, tema y datos personales'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(context, const SettingsScreen()),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Acerca de'),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'FitLife',
              applicationVersion: '1.0.0',
              applicationIcon: const Icon(Icons.favorite, size: 40),
              children: const [
                Text(
                  'Tu compañero de entrenamiento, peso, hidratación y pasos.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
