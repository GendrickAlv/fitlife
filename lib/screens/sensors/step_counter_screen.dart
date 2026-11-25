import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/utils/date_utils.dart';
import '../../core/utils/formatters.dart';
import '../../providers/profile_provider.dart';
import '../../providers/step_provider.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/progress_ring.dart';

/// Pantalla del contador de pasos basado en el acelerómetro.
///
/// El conteo NO se detiene al salir de la pantalla: el [StepProvider] vive
/// durante toda la app para seguir contando entre pantallas.
class StepCounterScreen extends StatelessWidget {
  /// Crea la pantalla.
  const StepCounterScreen({super.key});

  Future<void> _addManual(BuildContext context) async {
    final provider = context.read<StepProvider>();
    final count = await showDialog<int>(
      context: context,
      builder: (_) => const _ManualStepsDialog(),
    );
    if (count == null) return;
    await provider.addManualSteps(count);
    if (context.mounted) {
      AppSnack.success(
        context,
        '${Fmt.integer(count)} ${count == 1 ? 'paso agregado' : 'pasos agregados'}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = context.watch<StepProvider>();
    final profile = context.watch<ProfileProvider>().profile;
    final goal = profile.dailyStepGoal;
    return Scaffold(
      appBar: AppBar(title: const Text('Sensor de pasos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!steps.isSupported) ...[
            const _UnsupportedCard(),
            const SizedBox(height: 16),
          ],
          _StepRing(steps: steps.todaySteps, goal: goal),
          const SizedBox(height: 16),
          _Metrics(steps: steps.todaySteps, heightCm: profile.heightCm),
          const SizedBox(height: 16),
          _Controls(
            isTracking: steps.isTracking,
            isSupported: steps.isSupported,
            onToggle: () => steps.isTracking ? steps.stop() : steps.start(),
            onManual: () => _addManual(context),
          ),
          const SizedBox(height: 24),
          Text(
            'Últimos 7 días',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _WeekChart(steps: steps, goal: goal),
          const SizedBox(height: 16),
          const _HowItWorksTile(),
        ],
      ),
    );
  }
}

class _StepRing extends StatelessWidget {
  const _StepRing({required this.steps, required this.goal});

  final int steps;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = goal <= 0 ? 1 : goal;
    final ratio = (steps / target).clamp(0.0, 1.0);
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: ratio),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (_, value, _) => ProgressRing(
          progress: value,
          size: 220,
          strokeWidth: 16,
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.directions_walk, color: theme.colorScheme.primary),
              Text(
                Fmt.integer(steps),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'de ${Fmt.integer(goal)} pasos',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.steps, required this.heightCm});

  final int steps;
  final double heightCm;

  @override
  Widget build(BuildContext context) {
    final strideM = heightCm > 0 ? heightCm * 0.415 / 100 : 0.762;
    final km = steps * strideM / 1000;
    final kcal = steps * 0.04;
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            icon: Icons.straighten,
            label: 'Distancia',
            value: '${Fmt.decimal(km, maxDecimals: 2)} km',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricTile(
            icon: Icons.local_fire_department_outlined,
            label: 'Calorías',
            value: '${Fmt.integer(kcal)} kcal',
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.isTracking,
    required this.isSupported,
    required this.onToggle,
    required this.onManual,
  });

  final bool isTracking;
  final bool isSupported;
  final VoidCallback onToggle;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isTracking) const _TrackingIndicator(),
        if (isSupported)
          FilledButton.icon(
            onPressed: onToggle,
            icon: Icon(isTracking ? Icons.stop : Icons.play_arrow),
            label: Text(isTracking ? 'Detener conteo' : 'Iniciar conteo'),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onManual,
          icon: const Icon(Icons.add),
          label: const Text('Agregar pasos'),
        ),
      ],
    );
  }
}

/// Indicador pulsante mostrado mientras se cuentan pasos.
class _TrackingIndicator extends StatefulWidget {
  const _TrackingIndicator();

  @override
  State<_TrackingIndicator> createState() => _TrackingIndicatorState();
}

class _TrackingIndicatorState extends State<_TrackingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (_, _) => Container(
              width: 12 + 6 * _controller.value,
              height: 12 + 6 * _controller.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.error.withValues(
                  alpha: 0.5 + 0.5 * _controller.value,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Contando pasos...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _UnsupportedCard extends StatelessWidget {
  const _UnsupportedCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: scheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Este dispositivo no tiene acelerómetro disponible. '
                'Puedes registrar tus pasos manualmente.',
                style: TextStyle(color: scheme.onSecondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gráfico de barras de los últimos 7 días con línea de meta.
class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.steps, required this.goal});

  final StepProvider steps;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days = DateUtilsX.lastDays(7);
    final byDay = {for (final r in steps.history) r.day: r.steps};
    final todayKey = DateUtilsX.dayKey(DateTime.now());
    final values = [
      for (final d in days)
        DateUtilsX.dayKey(d) == todayKey
            ? (steps.todaySteps > (byDay[todayKey] ?? 0)
                  ? steps.todaySteps
                  : (byDay[todayKey] ?? 0))
            : (byDay[DateUtilsX.dayKey(d)] ?? 0),
    ];
    final top = [...values, goal].reduce((a, b) => a > b ? a : b);
    final maxY = top * 1.2;
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(enabled: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: goal.toDouble(),
                color: scheme.tertiary,
                strokeWidth: 2,
                dashArray: [6, 4],
              ),
            ],
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, meta) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    Fmt.weekdayInitial(days[v.toInt()]),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < days.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i].toDouble(),
                    width: 18,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                    color: values[i] >= goal ? scheme.tertiary : scheme.primary,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksTile extends StatelessWidget {
  const _HowItWorksTile();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.sensors),
        title: Text('¿Cómo se detectan los pasos?'),
        subtitle: Text(
          'Se mide la magnitud de la aceleración del acelerómetro. Cada pico '
          'por encima de un umbral (con un intervalo mínimo de 300 ms entre '
          'picos) cuenta como un paso. Es una estimación aproximada.',
        ),
      ),
    );
  }
}

/// Diálogo para agregar pasos manualmente (1 a 50.000).
class _ManualStepsDialog extends StatefulWidget {
  const _ManualStepsDialog();

  @override
  State<_ManualStepsDialog> createState() => _ManualStepsDialogState();
}

class _ManualStepsDialogState extends State<_ManualStepsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? v) {
    if (v == null || v.trim().isEmpty) return 'Introduce un número';
    final n = int.tryParse(v.trim());
    if (n == null) return 'Introduce un número entero';
    if (n < 1 || n > 50000) return 'Debe estar entre 1 y 50.000';
    return null;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(int.parse(_controller.text.trim()));
    } else {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar pasos'),
      content: Form(
        key: _formKey,
        autovalidateMode: _autovalidate,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Pasos',
            suffixText: 'pasos',
            border: OutlineInputBorder(),
          ),
          validator: _validate,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Agregar')),
      ],
    );
  }
}
