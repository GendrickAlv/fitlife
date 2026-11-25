import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/activity.dart';
import '../../providers/activity_provider.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/empty_state.dart';
import '../routines/filter_chip_bar.dart';
import 'activity_form_screen.dart';
import 'feeling.dart';

/// Periodo de filtrado del historial.
enum HistoryPeriod { week, month, all }

/// Historial de actividades agrupado por día, con filtros y resumen.
class HistoryScreen extends StatefulWidget {
  /// Crea la pantalla.
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryPeriod _period = HistoryPeriod.week;
  String? _category;

  /// Ids ocultos mientras se completa el borrado (evita Dismissible huérfano).
  final Set<int> _hidden = {};

  void _openForm([Activity? activity]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ActivityFormScreen(activity: activity),
      ),
    );
  }

  List<Activity> _filter(List<Activity> all) {
    final now = DateTime.now();
    final DateTime? from = switch (_period) {
      HistoryPeriod.week => DateUtilsX.startOfWeek(now),
      HistoryPeriod.month => DateTime(now.year, now.month),
      HistoryPeriod.all => null,
    };
    return all.where((a) {
      if (a.id != null && _hidden.contains(a.id)) return false;
      if (_category != null && a.category != _category) return false;
      if (from != null && a.date.isBefore(from)) return false;
      return true;
    }).toList();
  }

  Future<void> _delete(Activity a) async {
    final id = a.id;
    if (id == null) return;
    final provider = context.read<ActivityProvider>();
    setState(() => _hidden.add(id));
    await provider.delete(id);
    if (!mounted) return;
    setState(() => _hidden.remove(id));
    AppSnack.action(
      context,
      'Actividad eliminada',
      label: 'Deshacer',
      onPressed: () => provider.add(a),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();
    final all = provider.activities;
    final items = _filter(all);
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Registrar actividad'),
      ),
      body: provider.isLoading && all.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _PeriodSelector(
                  period: _period,
                  onChanged: (p) => setState(() => _period = p),
                ),
                FilterChipBar(
                  chips: [
                    FilterChipSpec(
                      label: 'Todas',
                      selected: _category == null,
                      onTap: () => setState(() => _category = null),
                    ),
                    for (final c in RoutineCategory.all)
                      FilterChipSpec(
                        label: c,
                        selected: _category == c,
                        onTap: () => setState(
                          () => _category = _category == c ? null : c,
                        ),
                      ),
                  ],
                ),
                _SummaryRow(activities: items),
                Expanded(child: _list(all, items)),
              ],
            ),
    );
  }

  Widget _list(List<Activity> all, List<Activity> items) {
    if (all.isEmpty) {
      return EmptyState(
        icon: Icons.history,
        title: 'Sin actividades',
        message: 'Registra tu primer entrenamiento para ver tu historial.',
        actionLabel: 'Registrar actividad',
        onAction: _openForm,
      );
    }
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.filter_alt_off_outlined,
        title: 'Sin resultados',
        message: 'No hay actividades con estos filtros.',
      );
    }
    final rows = _buildRows(items);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: rows.length,
      itemBuilder: (context, i) {
        final row = rows[i];
        if (row is DateTime) return _DayHeader(day: row);
        final a = row as Activity;
        return _ActivityTile(
          key: ValueKey('activity-${a.id}'),
          activity: a,
          onTap: () => _openForm(a),
          onDismissed: () => _delete(a),
        );
      },
    );
  }

  /// Intercala cabeceras de día (DateTime) y actividades.
  List<Object> _buildRows(List<Activity> items) {
    final rows = <Object>[];
    DateTime? current;
    for (final a in items) {
      final day = DateUtilsX.startOfDay(a.date);
      if (current == null || current != day) {
        rows.add(day);
        current = day;
      }
      rows.add(a);
    }
    return rows;
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.period, required this.onChanged});

  final HistoryPeriod period;
  final ValueChanged<HistoryPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<HistoryPeriod>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: HistoryPeriod.week, label: Text('Semana')),
            ButtonSegment(value: HistoryPeriod.month, label: Text('Mes')),
            ButtonSegment(value: HistoryPeriod.all, label: Text('Todo')),
          ],
          selected: {period},
          onSelectionChanged: (s) => onChanged(s.first),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.activities});

  final List<Activity> activities;

  @override
  Widget build(BuildContext context) {
    final minutes = activities.fold<int>(0, (s, a) => s + a.durationMinutes);
    final kcal = activities.fold<int>(0, (s, a) => s + a.calories);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _SummaryTile(
              icon: Icons.fitness_center,
              value: '${activities.length}',
              label: 'Sesiones',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryTile(
              icon: Icons.timer_outlined,
              value: Fmt.integer(minutes),
              label: 'Minutos',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryTile(
              icon: Icons.local_fire_department_outlined,
              value: Fmt.integer(kcal),
              label: 'kcal',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: scheme.onPrimaryContainer),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});

  final DateTime day;

  static String label(DateTime day, DateTime now) {
    final today = DateUtilsX.startOfDay(now);
    if (day == today) return 'Hoy';
    if (day == DateTime(today.year, today.month, today.day - 1)) return 'Ayer';
    final text = DateFormat("EEEE d 'de' MMMM", 'es').format(day);
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        label(day, DateTime.now()),
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    super.key,
    required this.activity,
    required this.onTap,
    required this.onDismissed,
  });

  final Activity activity;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = CategoryStyle.color(activity.category);
    final hasNotes = activity.notes.trim().isNotEmpty;
    return Dismissible(
      key: ValueKey('dismiss-${activity.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    foregroundColor: color,
                    child: Icon(CategoryStyle.icon(activity.category)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${activity.durationMinutes} min · '
                          '${activity.calories} kcal',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        if (hasNotes) ...[
                          const SizedBox(height: 4),
                          Text(
                            activity.notes.trim(),
                            style: theme.textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message:
                        'Sensación: ${FeelingStyle.label(activity.feeling)}',
                    child: Icon(
                      FeelingStyle.icon(activity.feeling),
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
