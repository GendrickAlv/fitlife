import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/utils/validators.dart';
import '../../data/models/routine.dart';
import '../../providers/routine_provider.dart';
import '../../widgets/app_snack.dart';
import 'exercise_sheet.dart';
import 'form_helpers.dart';

/// Formulario para crear o editar una [Routine].
///
/// Si se pasa [routine] se edita; si no, se crea una nueva.
class RoutineFormScreen extends StatefulWidget {
  /// Crea el formulario.
  const RoutineFormScreen({super.key, this.routine});

  final Routine? routine;

  @override
  State<RoutineFormScreen> createState() => _RoutineFormScreenState();
}

class _RoutineFormScreenState extends State<RoutineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _duration;
  late final TextEditingController _calories;
  late String _category;
  late String _difficulty;
  late List<Exercise> _exercises;
  bool _exercisesError = false;
  bool _saving = false;
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  bool get _isEditing => widget.routine != null;

  @override
  void initState() {
    super.initState();
    final r = widget.routine;
    _name = TextEditingController(text: r?.name ?? '');
    _description = TextEditingController(text: r?.description ?? '');
    _duration = TextEditingController(
      text: r?.durationMinutes.toString() ?? '',
    );
    _calories = TextEditingController(
      text: r?.estimatedCalories.toString() ?? '',
    );
    _category = r?.category ?? RoutineCategory.all.first;
    _difficulty = r?.difficulty ?? Difficulty.all.first;
    _exercises = [...?r?.exercises];
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _duration.dispose();
    _calories.dispose();
    super.dispose();
  }

  Future<void> _addExercise() async {
    final e = await ExerciseSheet.show(context);
    if (e == null) return;
    setState(() {
      _exercises.add(e);
      _exercisesError = false;
    });
  }

  Future<void> _editExercise(int index) async {
    final e = await ExerciseSheet.show(context, exercise: _exercises[index]);
    if (e == null) return;
    setState(() => _exercises[index] = e);
  }

  void _removeExercise(int index) {
    setState(() => _exercises.removeAt(index));
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    setState(() => _exercisesError = _exercises.isEmpty);
    if (!valid || _exercises.isEmpty) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
    if (_saving) return;

    setState(() => _saving = true);
    final provider = context.read<RoutineProvider>();
    final base = widget.routine;
    final routine = Routine(
      id: base?.id,
      name: _name.text.trim(),
      description: _description.text.trim(),
      category: _category,
      difficulty: _difficulty,
      durationMinutes: Validators.parseNumber(_duration.text)!.round(),
      estimatedCalories: Validators.parseNumber(_calories.text)!.round(),
      exercises: List.unmodifiable(_exercises),
      isFavorite: base?.isFavorite ?? false,
      createdAt: base?.createdAt ?? DateTime.now(),
    );
    if (_isEditing) {
      await provider.update(routine);
    } else {
      await provider.add(routine);
    }
    if (!mounted) return;
    if (provider.error != null) {
      setState(() => _saving = false);
      AppSnack.error(context, provider.error!);
      return;
    }
    AppSnack.success(
      context,
      _isEditing ? 'Rutina actualizada' : 'Rutina creada',
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar rutina' : 'Nueva rutina'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_isEditing ? 'Guardar cambios' : 'Crear rutina'),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: _autovalidate,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.fitness_center),
              ),
              validator: (v) {
                final base = Validators.required(v, 'El nombre');
                if (base != null) return base;
                return Validators.maxLength(50)(v);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              maxLines: 3,
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes),
              ),
              validator: Validators.maxLength(300),
            ),
            const SizedBox(height: 16),
            _CategoryDropdown(
              value: _category,
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 16),
            Text('Dificultad', style: _labelStyle(context)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                for (final d in Difficulty.all)
                  ButtonSegment(
                    value: d,
                    label: Text(d, overflow: TextOverflow.ellipsis),
                  ),
              ],
              selected: {_difficulty},
              onSelectionChanged: (s) => setState(() => _difficulty = s.first),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _duration,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Duración (min)',
                      prefixIcon: Icon(Icons.timer_outlined),
                    ),
                    validator: FormRules.intInRange(1, 300),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _calories,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Calorías (kcal)',
                      prefixIcon: Icon(Icons.local_fire_department_outlined),
                    ),
                    validator: FormRules.intInRange(0, 3000),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _ExercisesSection(
              exercises: _exercises,
              showError: _exercisesError,
              onAdd: _addExercise,
              onEdit: _editExercise,
              onRemove: _removeExercise,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  TextStyle? _labelStyle(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.titleSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Categoría',
        prefixIcon: Icon(Icons.category_outlined),
      ),
      items: [
        for (final c in RoutineCategory.all)
          DropdownMenuItem(
            value: c,
            child: Row(
              children: [
                Icon(
                  CategoryStyle.icon(c),
                  size: 20,
                  color: CategoryStyle.color(c),
                ),
                const SizedBox(width: 12),
                Text(c),
              ],
            ),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _ExercisesSection extends StatelessWidget {
  const _ExercisesSection({
    required this.exercises,
    required this.showError,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  final List<Exercise> exercises;
  final bool showError;
  final VoidCallback onAdd;
  final void Function(int index) onEdit;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Ejercicios (${exercises.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Añadir'),
            ),
          ],
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Añade al menos un ejercicio',
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ),
        if (exercises.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Aún no hay ejercicios. Pulsa "Añadir" para empezar.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          for (var i = 0; i < exercises.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  title: Text(
                    exercises[i].name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(exerciseSummary(exercises[i])),
                  onTap: () => onEdit(i),
                  trailing: IconButton(
                    tooltip: 'Quitar ejercicio',
                    icon: Icon(Icons.delete_outline, color: scheme.error),
                    onPressed: () => onRemove(i),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

/// Resumen legible de un ejercicio: "3 x 12 · 20 kg · descanso 60 s".
String exerciseSummary(Exercise e) {
  final parts = <String>['${e.sets} x ${e.reps}'];
  if (e.weightKg != null) parts.add('${FormRules.num(e.weightKg!)} kg');
  if (e.restSeconds != null) parts.add('descanso ${e.restSeconds} s');
  return parts.join(' · ');
}
