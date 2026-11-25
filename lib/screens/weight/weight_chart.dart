import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/weight_entry.dart';

/// Gráfico de línea suave con la evolución del peso.
class WeightChart extends StatelessWidget {
  /// Crea el gráfico. [entries] debe estar en orden cronológico ascendente.
  const WeightChart({super.key, required this.entries, this.goalKg});

  /// Registros (más antiguo primero).
  final List<WeightEntry> entries;

  /// Peso objetivo para la línea punteada.
  final double? goalKg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final values = [for (final e in entries) e.weightKg, ?goalKg];
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    final pad = math.max(1.0, (hi - lo) * 0.2);
    final minY = (lo - pad).floorToDouble();
    final maxY = (hi + pad).ceilToDouble();
    final interval = math.max(1.0, ((maxY - minY) / 4).ceilToDouble());
    final last = entries.length - 1;
    final dayFmt = DateFormat('d MMM', 'es');
    final labelStep = math.max(1, (entries.length / 4).ceil());

    return AspectRatio(
      aspectRatio: 1.6,
      child: LineChart(
        LineChartData(
          minX: entries.length == 1 ? -1 : 0,
          maxX: entries.length == 1 ? 1 : last.toDouble(),
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: scheme.outlineVariant, strokeWidth: 0.6),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: interval,
                getTitlesWidget: (v, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(
                    v.toStringAsFixed(0),
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (v, meta) {
                  final i = v.round();
                  final show =
                      (v - i).abs() < 0.01 &&
                      i >= 0 &&
                      i <= last &&
                      (i % labelStep == 0 || i == last);
                  if (!show) return const SizedBox.shrink();
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      dayFmt.format(entries[i].date),
                      style: theme.textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (goalKg != null)
                HorizontalLine(
                  y: goalKg!,
                  color: scheme.tertiary,
                  strokeWidth: 1.5,
                  dashArray: const [6, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.tertiary,
                    ),
                    labelResolver: (_) => 'Meta',
                  ),
                ),
            ],
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => scheme.inverseSurface,
              getTooltipItems: (spots) => [
                for (final s in spots)
                  LineTooltipItem(
                    '${Fmt.date(entries[s.x.round()].date)}\n'
                    '${Fmt.kg(s.y)}',
                    TextStyle(
                      color: scheme.onInverseSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < entries.length; i++)
                  FlSpot(i.toDouble(), entries[i].weightKg),
              ],
              isCurved: true,
              preventCurveOverShooting: true,
              color: AppColors.weight,
              barWidth: 3,
              dotData: FlDotData(show: entries.length <= 15),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.weight.withValues(alpha: 0.35),
                    AppColors.weight.withValues(alpha: 0),
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
