import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import 'chart_card.dart';

/// Barras de agua diaria con línea de meta.
class HydrationBarChart extends StatelessWidget {
  /// Crea el gráfico con los [totalsMl] de cada día de [days].
  const HydrationBarChart({
    super.key,
    required this.days,
    required this.totalsMl,
    required this.goalMl,
  });

  /// Días del periodo (orden ascendente).
  final List<DateTime> days;

  /// Mililitros por día, en el mismo orden que [days].
  final List<int> totalsMl;

  /// Meta diaria en mililitros.
  final int goalMl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasData = totalsMl.any((m) => m > 0);
    final top = totalsMl.fold<int>(goalMl, (a, b) => a > b ? a : b);
    final thin = days.length > 7;
    return ChartCard(
      title: 'Agua por día',
      subtitle: 'Línea punteada: meta de ${Fmt.ml(goalMl)}',
      child: !hasData
          ? const ChartEmpty(
              message: 'Aún no has registrado agua en este periodo',
              icon: Icons.water_drop_outlined,
            )
          : BarChart(
              BarChartData(
                maxY: top * 1.15,
                gridData: gridFor(context),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  bottomTitles: bottomDayTitles(context, days),
                  leftTitles: leftValueTitles(
                    context,
                    reservedSize: 44,
                    format: (v) => Fmt.liters(v),
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: goalMl.toDouble(),
                      color: scheme.tertiary,
                      strokeWidth: 2,
                      dashArray: [6, 4],
                    ),
                  ],
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => scheme.inverseSurface,
                    getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                      '${Fmt.shortDay(days[group.x])}\n${Fmt.ml(rod.toY.round())}',
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
                          toY: totalsMl[i].toDouble(),
                          color: totalsMl[i] >= goalMl
                              ? AppColors.steps
                              : AppColors.water,
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
