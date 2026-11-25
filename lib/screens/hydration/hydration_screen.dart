import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/water_entry.dart';
import '../../providers/hydration_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_card.dart';
import 'hydration_chart.dart';
import 'water_form_sheet.dart';

/// Hidratación: progreso diario, registro rápido, gráfico semanal e historial de hoy.
class HydrationScreen extends StatelessWidget {
  /// Crea la pantalla.
  const HydrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HydrationProvider>();
    final goal = context.select<ProfileProvider, int>(
      (p) => p.profile.dailyWaterGoalMl,
    );
    final today = provider.todayEntries;
    final weekly = provider.dailyTotals(7);

    return Scaffold(
      appBar: AppBar(title: const Text('Hidratación')),
      body: provider.isLoading && provider.entries.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                _TodayCard(totalMl: provider.todayTotalMl, goalMl: goal),
                const SizedBox(height: 12),
                const _QuickAddRow(),
                const SectionHeader(title: 'Últimos 7 días'),
                _WeeklyCard(totals: weekly, goalMl: goal),
                const SectionHeader(title: 'Registros de hoy'),
                if (today.isEmpty)
                  const SizedBox(
                    height: 260,
                    child: EmptyState(
                      icon: Icons.water_drop_outlined,
                      title: 'Aún no has bebido hoy',
                      message:
                          'Usa los botones rápidos para añadir tu primer vaso.',
                    ),
                  )
                else
                  for (final e in today)
                    _WaterTile(key: ValueKey(e.id), entry: e),
              ],
            ),
    );
  }
}

String _motivation(double progress) {
  if (progress <= 0) return '¡Empieza el día con un vaso de agua!';
  if (progress < 0.5) return '¡Buen comienzo! Sigue hidratándote.';
  if (progress < 1) return '¡Ya casi llegas a tu meta, sigue así!';
  return '¡Meta cumplida! Tu cuerpo te lo agradece.';
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.totalMl, required this.goalMl});

  final int totalMl;
  final int goalMl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = goalMl <= 0 ? 0.0 : totalMl / goalMl;
    final reached = progress >= 1;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ProgressRing(
              progress: progress,
              size: 180,
              strokeWidth: 14,
              color: reached ? AppColors.steps : AppColors.water,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Fmt.liters(totalMl),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Meta: ${Fmt.liters(goalMl)}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _motivation(progress),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAddRow extends StatelessWidget {
  const _QuickAddRow();

  static IconData _iconFor(int ml) {
    if (ml <= 250) return Icons.local_drink_outlined;
    if (ml <= 400) return Icons.water_drop_outlined;
    return Icons.sports_bar_outlined;
  }

  Future<void> _add(BuildContext context, int ml) async {
    final provider = context.read<HydrationProvider>();
    await provider.add(WaterEntry(amountMl: ml, date: DateTime.now()));
    if (!context.mounted) return;
    if (provider.error != null) {
      AppSnack.error(context, provider.error!);
    } else {
      AppSnack.success(context, '+${Fmt.ml(ml)} registrados');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final ml in Defaults.waterQuickAmountsMl)
          FilledButton.tonalIcon(
            onPressed: () => _add(context, ml),
            icon: Icon(_iconFor(ml)),
            label: Text(Fmt.ml(ml)),
          ),
        OutlinedButton.icon(
          onPressed: () => WaterFormSheet.show(context),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Personalizado'),
        ),
      ],
    );
  }
}

class _WeeklyCard extends StatelessWidget {
  const _WeeklyCard({required this.totals, required this.goalMl});

  final Map<DateTime, int> totals;
  final int goalMl;

  @override
  Widget build(BuildContext context) {
    final average = totals.values.fold(0, (a, b) => a + b) ~/ totals.length;
    final daysMet = totals.values.where((v) => v >= goalMl).length;
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
            child: HydrationWeekChart(totals: totals, goalMl: goalMl),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.show_chart,
                label: 'Promedio semanal',
                value: Fmt.liters(average),
                color: AppColors.water,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.emoji_events_outlined,
                label: 'Meta cumplida',
                value: '$daysMet/${Fmt.plural(totals.length, 'día', 'días')}',
                color: AppColors.steps,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WaterTile extends StatelessWidget {
  const _WaterTile({super.key, required this.entry});

  final WaterEntry entry;

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await ConfirmDialog.show(
      context,
      'Eliminar registro',
      '¿Eliminar ${Fmt.ml(entry.amountMl)}?',
    );
    if (ok && context.mounted) await _delete(context);
  }

  Future<void> _delete(BuildContext context) async {
    final provider = context.read<HydrationProvider>();
    final id = entry.id;
    if (id == null) return;
    // El tile desaparece al borrar: se captura el messenger antes.
    final messenger = ScaffoldMessenger.of(context);
    await provider.delete(id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Registro eliminado'),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () => provider.add(entry),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final time = TimeOfDay.fromDateTime(entry.date).format(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey('dismiss-${entry.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: scheme.errorContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
        ),
        onDismissed: (_) => _delete(context),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            onTap: () => WaterFormSheet.show(context, entry: entry),
            leading: CircleAvatar(
              backgroundColor: AppColors.water.withValues(alpha: 0.15),
              child: const Icon(Icons.water_drop, color: AppColors.water),
            ),
            title: Text(
              Fmt.ml(entry.amountMl),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(time),
            trailing: PopupMenuButton<String>(
              tooltip: 'Más opciones',
              onSelected: (v) => v == 'edit'
                  ? WaterFormSheet.show(context, entry: entry)
                  : _confirmDelete(context),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
