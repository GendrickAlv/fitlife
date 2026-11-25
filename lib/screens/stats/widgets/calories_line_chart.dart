import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import 'chart_card.dart';

/// Línea de calorías quemadas por día.
class CaloriesLineChart extends StatelessWidget {
  /// Crea el gráfico con las [calories] de cada día de [days].
  const CaloriesLineChart({
    super.key,
    required this.days,
    required this.calories,
  });

  /// Días del periodo (orden ascendente).
  final List<DateTime> days;

  /// Calorías por día, en el mismo orden que [days].
  final List<int> calories;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasData = calories.any((c) => c > 0);
    final maxY = (calories.fold<int>(0, (a, b) => a > b ? a : b) * 1.2)
        .clamp(50, double.infinity)
        .toDouble();
    return ChartCard(
      title: 'Calorías por día',
      child: !hasData
          ? const ChartEmpty(
              message: 'Aún no hay calorías registradas',
              icon: Icons.local_fire_department_outlined,
            )
          : LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                minX: 0,
                maxX: (days.length - 1).toDouble(),
                gridData: gridFor(context),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  bottomTitles: bottomDayTitles(context, days),
                  leftTitles: leftValueTitles(context, reservedSize: 40),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => scheme.inverseSurface,
                    getTooltipItems: (spots) => [
                      for (final s in spots)
                        LineTooltipItem(
                          '${Fmt.shortDay(days[s.x.round()])}\n${s.y.round()} kcal',
                          tooltipStyle(context),
                        ),
                    ],
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < days.length; i++)
                        FlSpot(i.toDouble(), calories[i].toDouble()),
                    ],
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: AppColors.calories,
                    barWidth: 3,
                    dotData: FlDotData(show: days.length <= 7),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.calories.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
