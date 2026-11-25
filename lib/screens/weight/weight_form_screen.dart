import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/utils/date_utils.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../data/models/weight_entry.dart';
import '../../providers/weight_provider.dart';
import '../../widgets/app_snack.dart';

/// Formulario para crear (o editar si se pasa [entry]) un registro de peso.
class WeightFormScreen extends StatefulWidget {
  /// Crea el formulario.
  const WeightFormScreen({super.key, this.entry});

  /// Registro a editar; null para crear uno nuevo.
  final WeightEntry? entry;

  @override
  State<WeightFormScreen> createState() => _WeightFormScreenState();
}

class _WeightFormScreenState extends State<WeightFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weight;
  late final TextEditingController _note;
  late DateTime _date;
  bool _saving = false;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _weight = TextEditingController(
      text: e == null ? '' : e.weightKg.toString().replaceAll('.', ','),
    );
    _note = TextEditingController(text: e?.note ?? '');
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _weight.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(2000),
      lastDate: now,
      locale: const Locale('es'),
    );
    if (picked == null) return;
    setState(() {
      // Conserva la hora del registro para mantener el orden dentro del día.
      _date = DateUtilsX.isSameDay(picked, now)
          ? now
          : DateTime(picked.year, picked.month, picked.day, 12);
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final provider = context.read<WeightProvider>();
    final entry = WeightEntry(
      id: widget.entry?.id,
      weightKg: Validators.parseNumber(_weight.text)!,
      date: _date,
      note: _note.text.trim(),
    );
    if (_isEditing) {
      await provider.update(entry);
    } else {
      await provider.add(entry);
    }
    if (!mounted) return;
    final failed = provider.error != null;
    if (failed) {
      setState(() => _saving = false);
      AppSnack.error(context, provider.error!);
      return;
    }
    AppSnack.success(
      context,
      _isEditing ? 'Registro actualizado' : 'Peso registrado',
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar peso' : 'Registrar peso'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                key: const Key('weightField'),
                controller: _weight,
                autofocus: !_isEditing,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Peso',
                  suffixText: 'kg',
                  prefixIcon: Icon(Icons.monitor_weight_outlined),
                ),
                validator: Validators.numberInRange(20, 400),
              ),
              const SizedBox(height: 16),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha',
                    prefixIcon: Icon(Icons.event_outlined),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(Fmt.date(_date)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('noteField'),
                controller: _note,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Nota (opcional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                validator: Validators.maxLength(120),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
