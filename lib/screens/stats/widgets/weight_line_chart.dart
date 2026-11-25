import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import 'chart_card.dart';

/// Evolución del peso en el periodo, con línea de objetivo opcional.
class WeightLineChart extends StatelessWidget {
  /// Crea el gráfico. [weights] tiene un valor (o null) por cada día de [days].
  const WeightLineChart({
    super.key,
    required this.days,
    required this.weights,
    this.goalKg,
  });

  /// Días del periodo (orden ascendente).
  final List<DateTime> days;

  /// Peso del día (último registro) o null si no hubo registro.
  final List<double?> weights;

  /// Peso objetivo del perfil.
  final double? goalKg;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spots = [
      for (var i = 0; i < days.length; i++)
        if (weights[i] != null) FlSpot(i.toDouble(), weights[i]!),
    ];
    if (spots.isEmpty) {
      return const ChartCard(
        title: 'Evolución del peso',
        child: ChartEmpty(
          message: 'Sin registros de peso en este periodo',
          icon: Icons.monitor_weight_outlined,
        ),
      );
    }
    final values = [for (final s in spots) s.y, ?goalKg];
    final lo = values.reduce((a, b) => a < b ? a : b);
    final hi = values.reduce((a, b) => a > b ? a : b);
    final pad = ((hi - lo) * 0.2).clamp(0.5, double.infinity);
    return ChartCard(
      title: 'Evolución del peso',
      subtitle: goalKg == null ? null : 'Línea punteada: objetivo',
      child: LineChart(
        LineChartData(
          minY: (lo - pad).floorToDouble(),
          maxY: (hi + pad).ceilToDouble(),
          minX: 0,
          maxX: (days.length - 1).toDouble(),
          gridData: gridFor(context),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            bottomTitles: bottomDayTitles(context, days),
            leftTitles: leftValueTitles(context),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (goalKg != null)
                HorizontalLine(
                  y: goalKg!,
                  color: scheme.tertiary,
                  strokeWidth: 2,
                  dashArray: [6, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    style: TextStyle(
                      color: scheme.tertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    labelResolver: (_) => 'Objetivo ${Fmt.kg(goalKg!)}',
                  ),
                ),
            ],
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => scheme.inverseSurface,
              getTooltipItems: (touched) => [
                for (final s in touched)
                  LineTooltipItem(
                    '${Fmt.shortDay(days[s.x.round()])}\n${Fmt.kg(s.y)}',
                    tooltipStyle(context),
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: spots.length > 2,
              preventCurveOverShooting: true,
              color: AppColors.weight,
              barWidth: 3,
              dotData: FlDotData(show: spots.length <= 15),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.weight.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
