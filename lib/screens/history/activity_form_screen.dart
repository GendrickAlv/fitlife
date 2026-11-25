import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../data/models/activity.dart';
import '../../data/models/routine.dart';
import '../../providers/activity_provider.dart';
import '../../widgets/app_snack.dart';
import '../routines/form_helpers.dart';
import 'feeling.dart';

/// Formulario para registrar o editar una actividad.
///
/// Si se pasa [activity] se edita; si se pasa [fromRoutine] se precarga
/// con los datos de la rutina; si no, se crea una actividad vacía.
class ActivityFormScreen extends StatefulWidget {
  /// Crea el formulario.
  const ActivityFormScreen({super.key, this.activity, this.fromRoutine});

  final Activity? activity;
  final Routine? fromRoutine;

  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _duration;
  late final TextEditingController _calories;
  late final TextEditingController _notes;
  late String _category;
  late DateTime _date;
  late int _feeling;
  int? _routineId;
  String? _dateError;
  bool _saving = false;
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  bool get _isEditing => widget.activity != null;

  @override
  void initState() {
    super.initState();
    final a = widget.activity;
    final r = widget.fromRoutine;
    _title = TextEditingController(text: a?.title ?? r?.name ?? '');
    _duration = TextEditingController(
      text: (a?.durationMinutes ?? r?.durationMinutes)?.toString() ?? '',
    );
    _calories = TextEditingController(
      text: (a?.calories ?? r?.estimatedCalories)?.toString() ?? '',
    );
    _notes = TextEditingController(text: a?.notes ?? '');
    _category = a?.category ?? r?.category ?? RoutineCategory.all.first;
    _date = a?.date ?? DateTime.now();
    _feeling = a?.feeling ?? 3;
    _routineId = a?.routineId ?? r?.id;
  }

  @override
  void dispose() {
    _title.dispose();
    _duration.dispose();
    _calories.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _date.hour,
        _date.minute,
      );
      _dateError = null;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime(
        _date.year,
        _date.month,
        _date.day,
        picked.hour,
        picked.minute,
      );
      _dateError = null;
    });
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    final inFuture = _date.isAfter(DateTime.now());
    setState(() {
      _dateError = inFuture ? 'La fecha no puede estar en el futuro' : null;
    });
    if (!valid || inFuture) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
    if (_saving) return;

    setState(() => _saving = true);
    final provider = context.read<ActivityProvider>();
    final base = widget.activity;
    final activity = Activity(
      id: base?.id,
      routineId: _routineId,
      title: _title.text.trim(),
      category: _category,
      durationMinutes: Validators.parseNumber(_duration.text)!.round(),
      calories: Validators.parseNumber(_calories.text)!.round(),
      date: _date,
      notes: _notes.text.trim(),
      feeling: _feeling,
    );
    if (_isEditing) {
      await provider.update(activity);
    } else {
      await provider.add(activity);
    }
    if (!mounted) return;
    if (provider.error != null) {
      setState(() => _saving = false);
      AppSnack.error(context, provider.error!);
      return;
    }
    AppSnack.success(
      context,
      _isEditing ? 'Actividad actualizada' : 'Actividad registrada',
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar actividad' : 'Registrar actividad'),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: _autovalidate,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Título',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) => Validators.required(v, 'El título'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
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
              onChanged: (v) => setState(() => _category = v ?? _category),
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
                    validator: FormRules.intInRange(1, 600),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _calories,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Calorías (kcal)',
                      prefixIcon: Icon(Icons.local_fire_department_outlined),
                    ),
                    validator: FormRules.intInRange(0, 5000),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DateTimeRow(
              date: _date,
              errorText: _dateError,
              onPickDate: _pickDate,
              onPickTime: _pickTime,
            ),
            const SizedBox(height: 20),
            Text('¿Cómo te sentiste?', style: _labelStyle(context)),
            const SizedBox(height: 8),
            _FeelingSelector(
              value: _feeling,
              onChanged: (v) => setState(() => _feeling = v),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes),
              ),
              validator: Validators.maxLength(300),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_isEditing ? 'Guardar cambios' : 'Guardar actividad'),
            ),
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

class _DateTimeRow extends StatelessWidget {
  const _DateTimeRow({
    required this.date,
    required this.errorText,
    required this.onPickDate,
    required this.onPickTime,
  });

  final DateTime date;
  final String? errorText;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final time = TimeOfDay.fromDateTime(date);
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: OutlinedButton.icon(
                onPressed: onPickDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(Fmt.date(date), overflow: TextOverflow.ellipsis),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: onPickTime,
                icon: const Icon(Icons.schedule, size: 18),
                label: Text('$hh:$mm'),
              ),
            ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Text(
              errorText!,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.error),
            ),
          ),
      ],
    );
  }
}

class _FeelingSelector extends StatelessWidget {
  const _FeelingSelector({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 1; i <= 5; i++)
          Expanded(
            child: Column(
              children: [
                IconButton.filledTonal(
                  tooltip: FeelingStyle.label(i),
                  isSelected: i == value,
                  style: IconButton.styleFrom(
                    backgroundColor: i == value
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                    foregroundColor: i == value
                        ? scheme.onPrimary
                        : scheme.onSurfaceVariant,
                  ),
                  onPressed: () => onChanged(i),
                  icon: Icon(FeelingStyle.icon(i)),
                ),
                Text(
                  FeelingStyle.label(i),
                  style: Theme.of(context).textTheme.labelSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
