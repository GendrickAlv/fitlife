import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/utils/validators.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/section_header.dart';

/// Pantalla de perfil y ajustes.
class SettingsScreen extends StatefulWidget {
  /// Crea la pantalla.
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _height;
  late final TextEditingController _goalWeight;
  late final TextEditingController _water;
  late final TextEditingController _steps;
  late final TextEditingController _workouts;

  @override
  void initState() {
    super.initState();
    final p = context.read<ProfileProvider>().profile;
    _name = TextEditingController(text: p.name)..addListener(_onName);
    _height = TextEditingController(text: _num(p.heightCm));
    _goalWeight = TextEditingController(
      text: p.goalWeightKg == null ? '' : _num(p.goalWeightKg!),
    );
    _water = TextEditingController(text: '${p.dailyWaterGoalMl}');
    _steps = TextEditingController(text: '${p.dailyStepGoal}');
    _workouts = TextEditingController(text: '${p.weeklyWorkoutGoal}');
  }

  @override
  void dispose() {
    _name.dispose();
    _height.dispose();
    _goalWeight.dispose();
    _water.dispose();
    _steps.dispose();
    _workouts.dispose();
    super.dispose();
  }

  void _onName() => setState(() {});

  static String _num(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    if (parts.isEmpty) return '?';
    final list = parts.toList();
    final first = list.first[0];
    final second = list.length > 1 ? list[1][0] : '';
    return (first + second).toUpperCase();
  }

  /// Validador de entero dentro de [min]..[max].
  static String? Function(String?) _intInRange(int min, int max) {
    final base = Validators.numberInRange(min.toDouble(), max.toDouble());
    return (v) {
      final err = base(v);
      if (err != null) return err;
      final n = Validators.parseNumber(v)!;
      if (n != n.roundToDouble()) return 'Introduce un número entero';
      return null;
    };
  }

  String? _validateGoalWeight(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return Validators.numberInRange(20, 400)(v);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ProfileProvider>();
    final goalText = _goalWeight.text.trim();
    final updated = provider.profile.copyWith(
      name: _name.text.trim(),
      heightCm: Validators.parseNumber(_height.text)!,
      goalWeightKg: goalText.isEmpty ? null : Validators.parseNumber(goalText),
      clearGoalWeight: goalText.isEmpty,
      dailyWaterGoalMl: int.parse(_water.text.trim()),
      dailyStepGoal: int.parse(_steps.text.trim()),
      weeklyWorkoutGoal: int.parse(_workouts.text.trim()),
    );
    await provider.update(updated);
    if (!mounted) return;
    if (provider.error != null) {
      AppSnack.error(context, provider.error!);
    } else {
      AppSnack.success(context, 'Perfil guardado');
    }
  }

  void _changeTheme(ThemeMode mode) {
    final provider = context.read<ProfileProvider>();
    provider.update(provider.profile.copyWith(themeMode: mode));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = context.select<ProfileProvider, ThemeMode>(
      (p) => p.themeMode,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil y ajustes')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: Text(
                  _initials(_name.text),
                  style: theme.textTheme.headlineMedium,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const ValueKey('name_field'),
              controller: _name,
              maxLength: 30,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  Validators.required(v, 'El nombre') ??
                  Validators.maxLength(30)(v),
            ),
            const SizedBox(height: 12),
            _NumberField(
              fieldKey: const ValueKey('height_field'),
              controller: _height,
              label: 'Altura',
              suffix: 'cm',
              icon: Icons.height,
              validator: Validators.numberInRange(100, 250),
            ),
            const SizedBox(height: 12),
            _NumberField(
              fieldKey: const ValueKey('goal_weight_field'),
              controller: _goalWeight,
              label: 'Peso objetivo (opcional)',
              suffix: 'kg',
              icon: Icons.flag_outlined,
              validator: _validateGoalWeight,
            ),
            const SizedBox(height: 12),
            _NumberField(
              fieldKey: const ValueKey('water_field'),
              controller: _water,
              label: 'Meta diaria de agua',
              suffix: 'ml',
              icon: Icons.water_drop_outlined,
              validator: _intInRange(500, 6000),
            ),
            const SizedBox(height: 12),
            _NumberField(
              fieldKey: const ValueKey('steps_field'),
              controller: _steps,
              label: 'Meta diaria de pasos',
              suffix: 'pasos',
              icon: Icons.directions_walk,
              validator: _intInRange(1000, 50000),
            ),
            const SizedBox(height: 12),
            _NumberField(
              fieldKey: const ValueKey('workouts_field'),
              controller: _workouts,
              label: 'Meta semanal de entrenamientos',
              suffix: 'sesiones',
              icon: Icons.fitness_center,
              validator: _intInRange(1, 14),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar'),
            ),
            const SectionHeader(title: 'Tema'),
            SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto),
                  label: Text('Sistema'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Claro'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Oscuro'),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) => _changeTheme(s.first),
            ),
            const SectionHeader(title: 'Datos'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Acerca de FitLife'),
                subtitle: const Text('Versión 1.0.0'),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'FitLife',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(Icons.favorite, size: 40),
                  children: const [
                    Text(
                      'Aplicación de seguimiento de entrenamientos, peso, '
                      'hidratación y pasos. Desarrollada por el Equipo 4.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.suffix,
    required this.icon,
    required this.validator,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final String suffix;
  final IconData icon;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}
