import 'package:material_ui/material_ui.dart';

import '../../core/utils/validators.dart';
import '../../data/models/routine.dart';
import 'form_helpers.dart';

/// Hoja inferior con formulario validado para crear o editar un [Exercise].
///
/// Devuelve el ejercicio resultante, o null si se cancela.
class ExerciseSheet extends StatefulWidget {
  /// Crea la hoja. [exercise] se pasa al editar.
  const ExerciseSheet({super.key, this.exercise});

  final Exercise? exercise;

  /// Muestra la hoja y devuelve el ejercicio guardado.
  static Future<Exercise?> show(BuildContext context, {Exercise? exercise}) {
    return showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ExerciseSheet(exercise: exercise),
    );
  }

  @override
  State<ExerciseSheet> createState() => _ExerciseSheetState();
}

class _ExerciseSheetState extends State<ExerciseSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _sets;
  late final TextEditingController _reps;
  late final TextEditingController _weight;
  late final TextEditingController _rest;
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    _name = TextEditingController(text: e?.name ?? '');
    _sets = TextEditingController(text: e?.sets.toString() ?? '');
    _reps = TextEditingController(text: e?.reps.toString() ?? '');
    _weight = TextEditingController(
      text: e?.weightKg == null ? '' : FormRules.num(e!.weightKg!),
    );
    _rest = TextEditingController(text: e?.restSeconds?.toString() ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _sets.dispose();
    _reps.dispose();
    _weight.dispose();
    _rest.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
    final weight = _weight.text.trim().isEmpty
        ? null
        : Validators.parseNumber(_weight.text);
    final rest = _rest.text.trim().isEmpty
        ? null
        : Validators.parseNumber(_rest.text)!.round();
    Navigator.of(context).pop(
      Exercise(
        name: _name.text.trim(),
        sets: Validators.parseNumber(_sets.text)!.round(),
        reps: Validators.parseNumber(_reps.text)!.round(),
        weightKg: weight,
        restSeconds: rest,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.exercise == null
                    ? 'Nuevo ejercicio'
                    : 'Editar ejercicio',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) {
                  final base = Validators.required(v, 'El nombre');
                  if (base != null) return base;
                  return Validators.maxLength(50)(v);
                },
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sets,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Series'),
                      validator: FormRules.intInRange(1, 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _reps,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Reps'),
                      validator: FormRules.intInRange(1, 100),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weight,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Peso (kg)',
                        helperText: 'Opcional',
                      ),
                      validator: FormRules.optionalInRange(0, 500),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _rest,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Descanso (s)',
                        helperText: 'Opcional',
                      ),
                      validator: FormRules.optionalIntInRange(0, 600),
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submit,
                child: Text(widget.exercise == null ? 'Añadir' : 'Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
