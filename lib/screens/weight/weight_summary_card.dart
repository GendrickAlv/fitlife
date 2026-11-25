import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/weight_entry.dart';

/// Categoría de IMC en español.
String bmiCategory(double bmi) {
  if (bmi < 18.5) return 'Bajo peso';
  if (bmi < 25) return 'Normal';
  if (bmi < 30) return 'Sobrepeso';
  return 'Obesidad';
}

/// Tarjeta de resumen: peso actual, cambio, IMC y progreso hacia la meta.
class WeightSummaryCard extends StatelessWidget {
  /// Crea la tarjeta de resumen.
  const WeightSummaryCard({
    super.key,
    required this.latest,
    required this.first,
    required this.change,
    required this.bmi,
    required this.goalKg,
  });

  /// Registro más reciente.
  final WeightEntry latest;

  /// Registro más antiguo.
  final WeightEntry first;

  /// Variación desde el primer registro (null si hay un solo registro).
  final double? change;

  /// IMC actual.
  final double? bmi;

  /// Peso objetivo, si existe.
  final double? goalKg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Peso actual',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [
                Text(
                  Fmt.kg(latest.weightKg),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.weight,
                  ),
                ),
                if (change != null) _ChangeChip(change: change!),
              ],
            ),
            Text(
              Fmt.date(latest.date),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (bmi != null) ...[
              const SizedBox(height: 16),
              _BmiRow(bmi: bmi!),
            ],
            if (goalKg != null) ...[
              const SizedBox(height: 16),
              _GoalProgress(
                start: first.weightKg,
                current: latest.weightKg,
                goal: goalKg!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChangeChip extends StatelessWidget {
  const _ChangeChip({required this.change});

  final double change;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final neutral = change.abs() < 0.05;
    // Subir de peso se marca en rojo, bajar en verde.
    final color = neutral
        ? theme.colorScheme.onSurfaceVariant
        : (change > 0 ? theme.colorScheme.error : AppColors.steps);
    final icon = neutral
        ? Icons.remove
        : (change > 0 ? Icons.arrow_upward : Icons.arrow_downward);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${Fmt.kg(change.abs())} desde el inicio',
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _BmiRow extends StatelessWidget {
  const _BmiRow({required this.bmi});

  final double bmi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = bmiCategory(bmi);
    final normal = category == 'Normal';
    final color = normal ? AppColors.steps : theme.colorScheme.tertiary;
    return Row(
      children: [
        Icon(Icons.monitor_heart_outlined, color: color),
        const SizedBox(width: 8),
        Text('IMC ', style: theme.textTheme.bodyMedium),
        Text(
          bmi.toStringAsFixed(1).replaceAll('.', ','),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              category,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(color: color),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalProgress extends StatelessWidget {
  const _GoalProgress({
    required this.start,
    required this.current,
    required this.goal,
  });

  final double start;
  final double current;
  final double goal;

  double get _progress {
    final total = start - goal;
    if (total.abs() < 0.05) return (current - goal).abs() < 0.05 ? 1 : 0;
    return ((start - current) / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = (current - goal).abs();
    final reached = remaining < 0.05 || _progress >= 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.flag_outlined,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Meta: ${Fmt.kg(goal)}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Text(
              '${(_progress * 100).round()}%',
              style: theme.textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: _progress, minHeight: 10),
        ),
        const SizedBox(height: 6),
        Text(
          reached ? '¡Meta alcanzada!' : 'faltan ${Fmt.kg(remaining)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
