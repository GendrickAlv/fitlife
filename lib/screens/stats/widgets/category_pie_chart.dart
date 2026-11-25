import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/constants.dart';
import 'chart_card.dart';

/// Gráfico circular de sesiones por categoría con leyenda de porcentajes.
class CategoryPieChart extends StatefulWidget {
  /// Crea el gráfico con las sesiones por categoría ([counts]).
  const CategoryPieChart({super.key, required this.counts});

  /// Categoría y número de sesiones, ordenado de mayor a menor.
  final List<MapEntry<String, int>> counts;

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final counts = widget.counts;
    final total = counts.fold<int>(0, (s, e) => s + e.value);
    if (total == 0) {
      return const ChartCard(
        title: 'Sesiones por categoría',
        child: ChartEmpty(
          message: 'Sin sesiones en este periodo',
          icon: Icons.pie_chart_outline,
        ),
      );
    }
    final theme = Theme.of(context);
    return ChartCard(
      title: 'Sesiones por categoría',
      height: 160,
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    final i =
                        response?.touchedSection?.touchedSectionIndex ?? -1;
                    final next = event.isInterestedForInteractions ? i : -1;
                    if (next != _touched) setState(() => _touched = next);
                  },
                ),
                sections: [
                  for (var i = 0; i < counts.length; i++)
                    PieChartSectionData(
                      value: counts[i].value.toDouble(),
                      color: CategoryStyle.color(counts[i].key),
                      radius: i == _touched ? 52 : 44,
                      title: i == _touched
                          ? '${counts[i].key}\n${counts[i].value}'
                          : '',
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: ListView(
              children: [
                for (final e in counts)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: CategoryStyle.color(e.key),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.key,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        Text(
                          '${(e.value * 100 / total).round()}%',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
