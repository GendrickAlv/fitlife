import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../data/models/challenge.dart';
import '../../providers/challenge_provider.dart';
import '../../widgets/app_snack.dart';

/// Formulario para crear o editar un desafío semanal.
///
/// Si se pasa [challenge] se edita; si se pasa [template] se pre-rellena un
/// desafío nuevo con sus valores.
class ChallengeFormScreen extends StatefulWidget {
  /// Crea el formulario.
  const ChallengeFormScreen({super.key, this.challenge, this.template});

  /// Desafío a editar (null para crear).
  final Challenge? challenge;

  /// Plantilla para pre-rellenar un desafío nuevo.
  final Challenge? template;

  /// Máximo permitido del objetivo según el [type].
  static double maxTarget(ChallengeType type) => switch (type) {
    ChallengeType.workouts => 14,
    ChallengeType.minutes => 3000,
    ChallengeType.calories => 20000,
    ChallengeType.water => 50,
    ChallengeType.steps => 300000,
  };

  @override
  State<ChallengeFormScreen> createState() => _ChallengeFormScreenState();
}

class _ChallengeFormScreenState extends State<ChallengeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _target;
  late ChallengeType _type;
  late DateTime _weekStart;
  bool _saving = false;
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  bool get _isEditing => widget.challenge != null;

  @override
  void initState() {
    super.initState();
    final source = widget.challenge ?? widget.template;
    _title = TextEditingController(text: source?.title ?? '');
    _description = TextEditingController(text: source?.description ?? '');
    _target = TextEditingController(
      text: source == null ? '' : _formatTarget(source.target),
    );
    _type = source?.type ?? ChallengeType.workouts;
    _weekStart = DateUtilsX.startOfWeek(
      widget.challenge?.weekStart ?? DateTime.now(),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _target.dispose();
    super.dispose();
  }

  static String _formatTarget(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  DateTime get _thisWeek => DateUtilsX.startOfWeek(DateTime.now());

  DateTime get _nextWeek {
    final t = _thisWeek;
    return DateTime(t.year, t.month, t.day + 7);
  }

  String? _validateTarget(String? value) {
    final base = Validators.positiveNumber(value);
    if (base != null) return base;
    final max = ChallengeFormScreen.maxTarget(_type);
    final n = Validators.parseNumber(value)!;
    if (n > max) return 'No puede superar ${Fmt.integer(max)} ${_type.unit}';
    if (_type != ChallengeType.water && n != n.roundToDouble()) {
      return 'Introduce un número entero';
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
    setState(() => _saving = true);
    final provider = context.read<ChallengeProvider>();
    final navigator = Navigator.of(context);
    final now = DateTime.now();
    final base = widget.challenge;
    final challenge = Challenge(
      id: base?.id,
      title: _title.text.trim(),
      description: _description.text.trim(),
      type: _type,
      target: Validators.parseNumber(_target.text)!,
      weekStart: _weekStart,
      createdAt: base?.createdAt ?? now,
    );
    if (_isEditing) {
      await provider.update(challenge);
    } else {
      await provider.add(challenge);
    }
    if (!mounted) return;
    if (provider.error != null) {
      setState(() => _saving = false);
      AppSnack.error(context, provider.error!);
      return;
    }
    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar desafío' : 'Nuevo desafío'),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: _autovalidate,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              maxLength: 50,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Título',
                prefixIcon: Icon(Icons.emoji_events_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  Validators.required(v, 'El título') ??
                  Validators.maxLength(50)(v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLength: 200,
              maxLines: 3,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
              validator: Validators.maxLength(200),
            ),
            const SizedBox(height: 12),
            Text(
              'Tipo de desafío',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in ChallengeType.values)
                  ChoiceChip(
                    key: ValueKey('type_${t.name}'),
                    avatar: Icon(t.icon, size: 18),
                    label: Text(t.label),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('target_field'),
              controller: _target,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Objetivo',
                suffixText: _type.unit,
                helperText:
                    'Máximo ${Fmt.integer(ChallengeFormScreen.maxTarget(_type))} ${_type.unit}',
                prefixIcon: const Icon(Icons.flag_outlined),
                border: const OutlineInputBorder(),
              ),
              validator: _validateTarget,
            ),
            const SizedBox(height: 16),
            Text('Semana', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<DateTime>(
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: _thisWeek,
                  label: const Text('Esta semana'),
                ),
                ButtonSegment(
                  value: _nextWeek,
                  label: const Text('Próxima semana'),
                ),
              ],
              selected: {
                if (_weekStart == _thisWeek || _weekStart == _nextWeek)
                  _weekStart,
              },
              onSelectionChanged: (s) {
                if (s.isNotEmpty) setState(() => _weekStart = s.first);
              },
            ),
            const SizedBox(height: 8),
            Text(
              '${Fmt.date(_weekStart)} - '
              '${Fmt.date(DateTime(_weekStart.year, _weekStart.month, _weekStart.day + 6))}',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(_isEditing ? 'Guardar cambios' : 'Crear desafío'),
            ),
          ],
        ),
      ),
    );
  }
}
