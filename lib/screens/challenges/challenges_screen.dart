import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/challenge.dart';
import '../../providers/activity_provider.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/hydration_provider.dart';
import '../../providers/step_provider.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import 'challenge_form_screen.dart';

/// Pantalla de desafíos semanales.
class ChallengesScreen extends StatelessWidget {
  /// Crea la pantalla.
  const ChallengesScreen({super.key});

  Future<void> _openForm(
    BuildContext context, {
    Challenge? challenge,
    Challenge? template,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) =>
            ChallengeFormScreen(challenge: challenge, template: template),
      ),
    );
  }

  Future<void> _delete(BuildContext context, Challenge c) async {
    final provider = context.read<ChallengeProvider>();
    final ok = await ConfirmDialog.show(
      context,
      'Eliminar desafío',
      '¿Eliminar "${c.title}"? Esta acción no se puede deshacer.',
    );
    if (!ok || c.id == null) return;
    await provider.delete(c.id!);
    if (context.mounted) AppSnack.success(context, 'Desafío eliminado');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChallengeProvider>();
    final activities = context.watch<ActivityProvider>();
    final hydration = context.watch<HydrationProvider>();
    final steps = context.watch<StepProvider>();

    double progress(Challenge c) => provider.progressFor(
      c,
      activities: activities,
      hydration: hydration,
      steps: steps,
    );

    final current = provider.currentWeekChallenges;
    final past = provider.pastChallenges;

    Widget body;
    if (provider.isLoading && provider.challenges.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          const _WeekHeader(),
          _SuggestionsRow(onSelected: (t) => _openForm(context, template: t)),
          const SectionHeader(title: 'Esta semana'),
          if (current.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _NoCurrentChallenges(),
            )
          else
            for (final c in current)
              _ChallengeCard(
                challenge: c,
                value: progress(c),
                onTap: () => _openForm(context, challenge: c),
                onDelete: () => _delete(context, c),
              ),
          if (past.isNotEmpty)
            _PastSection(
              challenges: past,
              progressOf: progress,
              onTap: (c) => _openForm(context, challenge: c),
              onDelete: (c) => _delete(context, c),
            ),
        ],
      );
      if (provider.challenges.isEmpty) {
        body = Column(
          children: [
            const _WeekHeader(),
            _SuggestionsRow(onSelected: (t) => _openForm(context, template: t)),
            Expanded(
              child: EmptyState(
                icon: Icons.emoji_events_outlined,
                title: 'Aún no tienes desafíos',
                message: 'Crea un desafío semanal o elige una sugerencia para empezar.',
                actionLabel: 'Nuevo desafío',
                onAction: () => _openForm(context),
              ),
            ),
          ],
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Desafíos semanales')),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Nuevo desafío',
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo desafío'),
      ),
    );
  }
}

/// Cabecera con el rango de la semana actual y días restantes.
class _WeekHeader extends StatelessWidget {
  const _WeekHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();
    final start = DateUtilsX.startOfWeek(now);
    final end = DateTime(start.year, start.month, start.day + 6);
    final remaining = 7 - (now.weekday - 1);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.date_range, color: scheme.onPrimaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${Fmt.date(start)} - ${Fmt.date(end)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    remaining == 1
                        ? 'Último día de la semana'
                        : 'Quedan $remaining días',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila horizontal de plantillas sugeridas.
class _SuggestionsRow extends StatelessWidget {
  const _SuggestionsRow({required this.onSelected});

  final ValueChanged<Challenge> onSelected;

  static final _presets = <(String, ChallengeType, double)>[
    ('4 entrenamientos', ChallengeType.workouts, 4),
    ('15 L de agua', ChallengeType.water, 15),
    ('50.000 pasos', ChallengeType.steps, 50000),
    ('150 minutos activos', ChallengeType.minutes, 150),
    ('2.000 kcal', ChallengeType.calories, 2000),
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final week = DateUtilsX.startOfWeek(now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Sugerencias'),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _presets.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final (label, type, target) = _presets[i];
              return ActionChip(
                avatar: Icon(type.icon, size: 18),
                label: Text(label),
                tooltip: 'Usar como plantilla',
                onPressed: () => onSelected(
                  Challenge(
                    title: label,
                    description: '',
                    type: type,
                    target: target,
                    weekStart: week,
                    createdAt: now,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NoCurrentChallenges extends StatelessWidget {
  const _NoCurrentChallenges();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'No tienes desafíos para esta semana. Crea uno nuevo o usa una sugerencia.',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

String _formatValue(ChallengeType type, double v) {
  if (type == ChallengeType.water) {
    return v == v.roundToDouble() ? Fmt.integer(v) : v.toStringAsFixed(1);
  }
  return Fmt.integer(v);
}

/// Tarjeta de un desafío con su progreso.
class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.challenge,
    required this.value,
    required this.onTap,
    required this.onDelete,
  });

  final Challenge challenge;
  final double value;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final done = value >= challenge.target;
    final ratio = challenge.target <= 0
        ? 0.0
        : (value / challenge.target).clamp(0.0, 1.0);
    final accent = done ? scheme.tertiary : scheme.primary;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: done ? scheme.tertiaryContainer : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: accent.withValues(alpha: 0.15),
                    foregroundColor: accent,
                    child: Icon(
                      done ? Icons.emoji_events : challenge.type.icon,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      challenge.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Eliminar desafío',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                  ),
                ],
              ),
              if (challenge.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 12),
                  child: Text(
                    challenge.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  color: accent,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_formatValue(challenge.type, value)} / '
                        '${_formatValue(challenge.type, challenge.target)} '
                        '${challenge.type.unit}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    if (done) const _DoneBadge(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoneBadge extends StatelessWidget {
  const _DoneBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.tertiary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '¡Completado!',
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: scheme.onTertiary, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Sección colapsable con los desafíos de semanas anteriores.
class _PastSection extends StatelessWidget {
  const _PastSection({
    required this.challenges,
    required this.progressOf,
    required this.onTap,
    required this.onDelete,
  });

  final List<Challenge> challenges;
  final double Function(Challenge) progressOf;
  final ValueChanged<Challenge> onTap;
  final ValueChanged<Challenge> onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ExpansionTile(
        title: const Text('Semanas anteriores'),
        subtitle: Text('${challenges.length} desafíos'),
        children: [
          for (final c in challenges)
            Builder(
              builder: (_) {
                final v = progressOf(c);
                final done = v >= c.target;
                return ListTile(
                  leading: Icon(
                    done ? Icons.emoji_events : Icons.cancel_outlined,
                    color: done ? scheme.tertiary : scheme.outline,
                  ),
                  title: Text(
                    c.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${Fmt.date(c.weekStart)} · ${_formatValue(c.type, v)} / '
                    '${_formatValue(c.type, c.target)} ${c.type.unit}\n'
                    '${done ? 'Completado' : 'No completado'}',
                  ),
                  isThreeLine: true,
                  onTap: () => onTap(c),
                  trailing: IconButton(
                    tooltip: 'Eliminar desafío',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => onDelete(c),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
