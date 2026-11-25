import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/weight_entry.dart';
import '../../providers/profile_provider.dart';
import '../../providers/weight_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import 'weight_chart.dart';
import 'weight_form_screen.dart';
import 'weight_summary_card.dart';

/// Seguimiento de peso: resumen, gráfico e historial de registros.
class WeightScreen extends StatelessWidget {
  /// Crea la pantalla.
  const WeightScreen({super.key});

  static void _openForm(BuildContext context, [WeightEntry? entry]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => WeightFormScreen(entry: entry)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeightProvider>();
    final goal = context.select<ProfileProvider, double?>(
      (p) => p.profile.goalWeightKg,
    );
    final height = context.select<ProfileProvider, double>(
      (p) => p.profile.heightCm,
    );
    final entries = provider.entries;

    Widget body;
    if (provider.isLoading && entries.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (entries.isEmpty) {
      body = EmptyState(
        icon: Icons.monitor_weight_outlined,
        title: 'Sin registros de peso',
        message: 'Registra tu peso para ver su evolución y tu progreso.',
        actionLabel: 'Registrar peso',
        onAction: () => _openForm(context),
      );
    } else {
      body = _WeightList(
        provider: provider,
        goalKg: goal,
        heightCm: height,
        onEdit: (e) => _openForm(context, e),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Peso')),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Registrar peso'),
      ),
    );
  }
}

class _WeightList extends StatelessWidget {
  const _WeightList({
    required this.provider,
    required this.goalKg,
    required this.heightCm,
    required this.onEdit,
  });

  final WeightProvider provider;
  final double? goalKg;
  final double heightCm;
  final void Function(WeightEntry) onEdit;

  static const _headerCount = 3;

  @override
  Widget build(BuildContext context) {
    final entries = provider.entries;
    final recent = entries.take(30).toList().reversed.toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: entries.length + _headerCount,
      itemBuilder: (context, i) {
        switch (i) {
          case 0:
            return WeightSummaryCard(
              latest: provider.latest!,
              first: provider.first!,
              change: provider.changeSinceFirst,
              bmi: provider.bmi(heightCm),
              goalKg: goalKg,
            );
          case 1:
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 12),
                        child: Text(
                          'Evolución',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      WeightChart(entries: recent, goalKg: goalKg),
                    ],
                  ),
                ),
              ),
            );
          case 2:
            return const Padding(
              padding: EdgeInsets.only(top: 8),
              child: SectionHeader(title: 'Historial'),
            );
        }
        final idx = i - _headerCount;
        final entry = entries[idx];
        final previous = idx + 1 < entries.length ? entries[idx + 1] : null;
        return _WeightTile(
          key: ValueKey(entry.id),
          entry: entry,
          delta: previous == null ? null : entry.weightKg - previous.weightKg,
          onEdit: () => onEdit(entry),
        );
      },
    );
  }
}

class _WeightTile extends StatelessWidget {
  const _WeightTile({
    super.key,
    required this.entry,
    required this.delta,
    required this.onEdit,
  });

  final WeightEntry entry;
  final double? delta;
  final VoidCallback onEdit;

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await ConfirmDialog.show(
      context,
      'Eliminar registro',
      '¿Eliminar el registro del ${Fmt.date(entry.date)}?',
    );
    if (ok && context.mounted) await _delete(context);
  }

  Future<void> _delete(BuildContext context) async {
    final provider = context.read<WeightProvider>();
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
            onTap: onEdit,
            leading: CircleAvatar(
              backgroundColor: AppColors.weight.withValues(alpha: 0.15),
              child: const Icon(
                Icons.monitor_weight_outlined,
                color: AppColors.weight,
              ),
            ),
            title: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(
                  Fmt.kg(entry.weightKg),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (delta != null) _DeltaBadge(delta: delta!),
              ],
            ),
            subtitle: Text(
              entry.note.isEmpty
                  ? Fmt.date(entry.date)
                  : '${Fmt.date(entry.date)} · ${entry.note}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: PopupMenuButton<String>(
              tooltip: 'Más opciones',
              onSelected: (v) =>
                  v == 'edit' ? onEdit() : _confirmDelete(context),
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

class _DeltaBadge extends StatelessWidget {
  const _DeltaBadge({required this.delta});

  final double delta;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (delta.abs() < 0.05) {
      return Text('=', style: TextStyle(color: scheme.onSurfaceVariant));
    }
    final up = delta > 0;
    final color = up ? scheme.error : AppColors.steps;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          up ? Icons.arrow_upward : Icons.arrow_downward,
          size: 14,
          color: color,
        ),
        Text(
          Fmt.kg(delta.abs()),
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: color),
        ),
      ],
    );
  }
}
