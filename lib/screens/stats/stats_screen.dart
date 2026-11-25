import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/formatters.dart';
import '../../providers/activity_provider.dart';
import '../../providers/hydration_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/weight_provider.dart';
import 'stats_metrics.dart';
import 'widgets/activity_minutes_chart.dart';
import 'widgets/calories_line_chart.dart';
import 'widgets/category_pie_chart.dart';
import 'widgets/hydration_bar_chart.dart';
import 'widgets/summary_tiles.dart';
import 'widgets/weight_line_chart.dart';

/// Pantalla "Progreso": gráficos de actividad, peso e hidratación.
class StatsScreen extends StatefulWidget {
  /// Crea la pantalla.
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _period = 7;

  @override
  Widget build(BuildContext context) {
    final days = DateUtilsX.lastDays(_period);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Progreso'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Actividad'),
              Tab(text: 'Peso'),
              Tab(text: 'Hidratación'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 7, label: Text('7 días')),
                    ButtonSegment(value: 30, label: Text('30 días')),
                  ],
                  selected: {_period},
                  onSelectionChanged: (s) => setState(() => _period = s.first),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ActivityTab(days: days),
                  _WeightTab(days: days),
                  _HydrationTab(days: days),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _tabPadding = EdgeInsets.fromLTRB(16, 8, 16, 24);

class _ActivityTab extends StatelessWidget {
  const _ActivityTab({required this.days});

  final List<DateTime> days;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();
    final inPeriod = activitiesInPeriod(provider.activities, days);
    final minutesMap = provider.minutesPerDay(days.length);
    final kcalMap = provider.caloriesPerDay(days.length);
    final minutes = [for (final d in days) minutesMap[d] ?? 0];
    final kcal = [for (final d in days) kcalMap[d] ?? 0];
    final totalMin = inPeriod.fold<int>(0, (s, a) => s + a.durationMinutes);
    final totalKcal = inPeriod.fold<int>(0, (s, a) => s + a.calories);
    final avg = inPeriod.isEmpty ? 0 : totalMin / inPeriod.length;
    return ListView(
      key: const PageStorageKey('stats-activity'),
      padding: _tabPadding,
      children: [
        SummaryTiles(
          items: [
            SummaryItem(
              Icons.event_available_outlined,
              'Sesiones',
              '${inPeriod.length}',
            ),
            SummaryItem(
              Icons.timer_outlined,
              'Minutos',
              Fmt.integer(totalMin),
              color: AppColors.minutes,
            ),
            SummaryItem(
              Icons.local_fire_department_outlined,
              'Kilocalorías',
              Fmt.integer(totalKcal),
              color: AppColors.calories,
            ),
            SummaryItem(
              Icons.speed_outlined,
              'Min por sesión',
              Fmt.integer(avg),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ActivityMinutesChart(days: days, minutes: minutes),
        const SizedBox(height: 12),
        CaloriesLineChart(days: days, calories: kcal),
        const SizedBox(height: 12),
        CategoryPieChart(counts: sessionsByCategory(inPeriod)),
      ],
    );
  }
}

class _WeightTab extends StatelessWidget {
  const _WeightTab({required this.days});

  final List<DateTime> days;

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<WeightProvider>().entries;
    final goal = context.select<ProfileProvider, double?>(
      (p) => p.profile.goalWeightKg,
    );
    // Entradas ordenadas DESC: el primer registro de cada día es el último.
    final perDay = <DateTime, double>{};
    for (final e in entries) {
      perDay.putIfAbsent(DateUtilsX.startOfDay(e.date), () => e.weightKg);
    }
    final weights = [for (final d in days) perDay[d]];
    final values = weights.whereType<double>().toList();
    final items = values.isEmpty
        ? const <SummaryItem>[]
        : [
            SummaryItem(
              Icons.arrow_downward,
              'Mínimo',
              Fmt.kg(values.reduce((a, b) => a < b ? a : b)),
              color: AppColors.weight,
            ),
            SummaryItem(
              Icons.arrow_upward,
              'Máximo',
              Fmt.kg(values.reduce((a, b) => a > b ? a : b)),
              color: AppColors.weight,
            ),
            SummaryItem(
              Icons.functions,
              'Promedio',
              Fmt.kg(values.reduce((a, b) => a + b) / values.length),
              color: AppColors.weight,
            ),
            if (goal != null)
              SummaryItem(Icons.flag_outlined, 'Objetivo', Fmt.kg(goal)),
          ];
    return ListView(
      key: const PageStorageKey('stats-weight'),
      padding: _tabPadding,
      children: [
        if (items.isNotEmpty) ...[
          SummaryTiles(items: items),
          const SizedBox(height: 12),
        ],
        WeightLineChart(days: days, weights: weights, goalKg: goal),
      ],
    );
  }
}

class _HydrationTab extends StatelessWidget {
  const _HydrationTab({required this.days});

  final List<DateTime> days;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HydrationProvider>();
    final goal = context.select<ProfileProvider, int>(
      (p) => p.profile.dailyWaterGoalMl,
    );
    final totals = [for (final d in days) provider.totalForDay(d)];
    final reached = totals.where((t) => t >= goal).length;
    final avg = totals.fold<int>(0, (s, t) => s + t) / days.length;
    return ListView(
      key: const PageStorageKey('stats-hydration'),
      padding: _tabPadding,
      children: [
        SummaryTiles(
          items: [
            SummaryItem(
              Icons.check_circle_outline,
              'Días con meta',
              '${(reached * 100 / days.length).round()}%',
              color: AppColors.steps,
            ),
            SummaryItem(
              Icons.water_drop_outlined,
              'Promedio diario',
              Fmt.ml(avg.round()),
              color: AppColors.water,
            ),
          ],
        ),
        const SizedBox(height: 12),
        HydrationBarChart(days: days, totalsMl: totals, goalMl: goal),
      ],
    );
  }
}
