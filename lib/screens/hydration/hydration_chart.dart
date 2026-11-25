import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

/// Gráfico de barras con el consumo de agua de los últimos días.
class HydrationWeekChart extends StatelessWidget {
  /// Crea el gráfico. [totals] va del día más antiguo al más reciente.
  const HydrationWeekChart({
    super.key,
    required this.totals,
    required this.goalMl,
  });

  /// Total en ml por día.
  final Map<DateTime, int> totals;

  /// Meta diaria en ml.
  final int goalMl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final days = totals.keys.toList();
    final maxValue = totals.values.fold(goalMl, math.max);
    final maxY = (maxValue * 1.2 / 500).ceil() * 500.0;
    return AspectRatio(
      aspectRatio: 1.7,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
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
                reservedSize: 36,
                interval: maxY / 4,
                getTitlesWidget: (v, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(
                    Fmt.decimal(v / 1000),
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= days.length) return const SizedBox.shrink();
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      Fmt.weekdayInitial(days[i]),
                      style: theme.textTheme.labelMedium,
                    ),
                  );
                },
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: goalMl.toDouble(),
                color: scheme.tertiary,
                strokeWidth: 1.5,
                dashArray: const [6, 4],
              ),
            ],
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => scheme.inverseSurface,
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                '${Fmt.shortDay(days[group.x])}\n${Fmt.ml(rod.toY.round())}',
                TextStyle(
                  color: scheme.onInverseSurface,
                  fontWeight: FontWeight.w600,
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
                    toY: totals[days[i]]!.toDouble(),
                    width: 18,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                    color: totals[days[i]]! >= goalMl
                        ? AppColors.steps
                        : AppColors.water,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
