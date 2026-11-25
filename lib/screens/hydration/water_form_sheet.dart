import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../data/models/water_entry.dart';
import '../../providers/hydration_provider.dart';
import '../../widgets/app_snack.dart';

/// Hoja inferior para registrar (o editar si se pasa [entry]) una toma de agua.
class WaterFormSheet extends StatefulWidget {
  /// Crea el formulario.
  const WaterFormSheet({super.key, this.entry});

  /// Registro a editar; null para crear uno nuevo.
  final WaterEntry? entry;

  /// Muestra la hoja como modal.
  static Future<void> show(BuildContext context, {WaterEntry? entry}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => WaterFormSheet(entry: entry),
    );
  }

  @override
  State<WaterFormSheet> createState() => _WaterFormSheetState();
}

class _WaterFormSheetState extends State<WaterFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late DateTime _date;
  String? _dateError;
  bool _saving = false;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _amount = TextEditingController(text: e?.amountMl.toString() ?? '');
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amount.dispose();
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
    final valid = _formKey.currentState?.validate() ?? false;
    final future = _date.isAfter(
      DateTime.now().add(const Duration(minutes: 1)),
    );
    setState(() => _dateError = future ? 'La hora no puede ser futura' : null);
    if (!valid || future) return;
    setState(() => _saving = true);
    final provider = context.read<HydrationProvider>();
    final entry = WaterEntry(
      id: widget.entry?.id,
      amountMl: Validators.parseNumber(_amount.text)!.round(),
      date: _date,
    );
    if (_isEditing) {
      await provider.update(entry);
    } else {
      await provider.add(entry);
    }
    if (!mounted) return;
    if (provider.error != null) {
      setState(() => _saving = false);
      AppSnack.error(context, provider.error!);
      return;
    }
    AppSnack.success(
      context,
      _isEditing ? 'Registro actualizado' : 'Agua registrada',
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Editar toma de agua' : 'Registrar agua',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('amountField'),
              controller: _amount,
              autofocus: !_isEditing,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                suffixText: 'ml',
                prefixIcon: Icon(Icons.water_drop_outlined),
              ),
              validator: Validators.numberInRange(50, 5000),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _PickerField(
                    label: 'Fecha',
                    icon: Icons.event_outlined,
                    value: Fmt.date(_date),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerField(
                    label: 'Hora',
                    icon: Icons.schedule,
                    value: TimeOfDay.fromDateTime(_date).format(context),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            if (_dateError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Text(
                  _dateError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
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
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
