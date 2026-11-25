import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import 'chart_card.dart';

/// Barras de minutos de actividad por día.
class ActivityMinutesChart extends StatelessWidget {
  /// Crea el gráfico con los [minutes] de cada día de [days].
  const ActivityMinutesChart({
    super.key,
    required this.days,
    required this.minutes,
  });

  /// Días del periodo (orden ascendente).
  final List<DateTime> days;

  /// Minutos por día, en el mismo orden que [days].
  final List<int> minutes;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasData = minutes.any((m) => m > 0);
    final maxY = (minutes.fold<int>(0, (a, b) => a > b ? a : b) * 1.2)
        .clamp(10, double.infinity)
        .toDouble();
    final thin = days.length > 7;
    return ChartCard(
      title: 'Minutos por día',
      child: !hasData
          ? const ChartEmpty(
              message: 'Aún no hay entrenamientos en este periodo',
            )
          : BarChart(
              BarChartData(
                maxY: maxY,
                gridData: gridFor(context),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  bottomTitles: bottomDayTitles(context, days),
                  leftTitles: leftValueTitles(context),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => scheme.inverseSurface,
                    getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                      '${Fmt.shortDay(days[group.x])}\n${rod.toY.round()} min',
                      tooltipStyle(context),
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < days.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: minutes[i].toDouble(),
                          color: AppColors.minutes,
                          width: thin ? 5 : 16,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}
