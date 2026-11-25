import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/activity.dart';
import '../../data/models/challenge.dart';
import '../../data/models/water_entry.dart';
import '../../providers/activity_provider.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/hydration_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/step_provider.dart';
import '../../providers/weight_provider.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_card.dart';
import '../challenges/challenges_screen.dart';
import '../history/activity_form_screen.dart';
import '../sensors/step_counter_screen.dart';
import '../settings/settings_screen.dart';
import '../weight/weight_screen.dart';
import 'dashboard_metrics.dart';

void _open(BuildContext context, Widget screen) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
}

/// Pantalla de inicio: resumen del día, desafíos y accesos rápidos.
class DashboardScreen extends StatelessWidget {
  /// Crea la pantalla.
  const DashboardScreen({super.key});

  Future<void> _refresh(BuildContext context) async {
    await Future.wait([
      context.read<ActivityProvider>().load(),
      context.read<WeightProvider>().load(),
      context.read<HydrationProvider>().load(),
      context.read<StepProvider>().load(),
      context.read<ChallengeProvider>().load(),
      context.read<ProfileProvider>().load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final name = context.select<ProfileProvider, String>((p) => p.profile.name);
    final now = DateTime.now();
    final date = DateFormat("EEEE d 'de' MMMM", 'es').format(now);
    final dateLabel = date.isEmpty
        ? date
        : '${date[0].toUpperCase()}${date.substring(1)}';
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _refresh(context),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              title: Text('${greetingForHour(now.hour)}, $name'),
              actions: [
                IconButton(
                  tooltip: 'Ajustes',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => _open(context, const SettingsScreen()),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.list(
                children: [
                  Text(
                    dateLabel,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _HeroCard(),
                  const SizedBox(height: 12),
                  const _StatsGrid(),
                  const SectionHeader(title: 'Accesos rápidos'),
                  const _QuickActions(),
                  const SectionHeader(title: 'Desafíos de la semana'),
                  const _ChallengesSection(),
                  const SectionHeader(title: 'Actividad reciente'),
                  const _RecentActivities(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final water = context.watch<HydrationProvider>().todayTotalMl;
    final steps = context.watch<StepProvider>().todaySteps;
    final weekStart = DateUtilsX.startOfWeek(DateTime.now());
    final workouts = context
        .watch<ActivityProvider>()
        .activitiesInWeek(weekStart)
        .length;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: _RingItem(
                label: 'Agua',
                value: Fmt.liters(water),
                progress: water / profile.dailyWaterGoalMl,
                color: AppColors.water,
                icon: Icons.water_drop,
              ),
            ),
            Expanded(
              child: _RingItem(
                label: 'Pasos',
                value: Fmt.integer(steps),
                progress: steps / profile.dailyStepGoal,
                color: AppColors.steps,
                icon: Icons.directions_walk,
              ),
            ),
            Expanded(
              child: _RingItem(
                label: 'Semana',
                value: '$workouts/${profile.weeklyWorkoutGoal}',
                progress: workouts / profile.weeklyWorkoutGoal,
                color: scheme.primary,
                icon: Icons.fitness_center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingItem extends StatelessWidget {
  const _RingItem({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final double progress;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onContainer = theme.colorScheme.onPrimaryContainer;
    final pct = (progress.isNaN || progress.isInfinite ? 0 : progress) * 100;
    return Semantics(
      label: '$label: $value, ${pct.round()}%',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProgressRing(
            progress: progress,
            color: color,
            size: 84,
            strokeWidth: 9,
            center: Icon(icon, color: color),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: onContainer,
              ),
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: onContainer.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    final weight = context.watch<WeightProvider>();
    final activities = context.watch<ActivityProvider>();
    final today = activities.todayActivities;
    final minutes = today.fold<int>(0, (s, a) => s + a.durationMinutes);
    final kcal = today.fold<int>(0, (s, a) => s + a.calories);
    final streak = activeDayStreak(activities.activities);
    final change = weight.changeSinceFirst;
    final changeText = change == null
        ? 'Sin cambios aún'
        : '${change > 0
                  ? '+'
                  : change < 0
                  ? '−'
                  : ''}'
              '${Fmt.kg(change.abs())} desde el inicio';
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.monitor_weight_outlined,
                label: 'Último peso',
                value: weight.latest == null
                    ? '—'
                    : Fmt.kg(weight.latest!.weightKg),
                subtitle: changeText,
                color: AppColors.weight,
                onTap: () => _open(context, const WeightScreen()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.local_fire_department,
                label: 'Racha',
                value: streak == 1 ? '1 día' : '$streak días',
                subtitle: streak == 0
                    ? '¡Entrena hoy!'
                    : 'Días activos seguidos',
                color: AppColors.calories,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.timer_outlined,
                label: 'Minutos hoy',
                value: '$minutes min',
                color: AppColors.minutes,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.bolt,
                label: 'Calorías hoy',
                value: '${Fmt.integer(kcal)} kcal',
                color: AppColors.calories,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  Future<void> _addWater(BuildContext context) async {
    final hydration = context.read<HydrationProvider>();
    await hydration.add(WaterEntry(amountMl: 250, date: DateTime.now()));
    if (!context.mounted) return;
    if (hydration.error != null) {
      AppSnack.error(context, hydration.error!);
    } else {
      AppSnack.success(context, '+250 ml de agua registrados');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          avatar: const Icon(Icons.water_drop_outlined, size: 18),
          label: const Text('Agua +250 ml'),
          onPressed: () => _addWater(context),
        ),
        ActionChip(
          avatar: const Icon(Icons.add_circle_outline, size: 18),
          label: const Text('Registrar actividad'),
          onPressed: () => _open(context, const ActivityFormScreen()),
        ),
        ActionChip(
          avatar: const Icon(Icons.monitor_weight_outlined, size: 18),
          label: const Text('Registrar peso'),
          onPressed: () => _open(context, const WeightScreen()),
        ),
        ActionChip(
          avatar: const Icon(Icons.directions_walk, size: 18),
          label: const Text('Contar pasos'),
          onPressed: () => _open(context, const StepCounterScreen()),
        ),
      ],
    );
  }
}

class _ChallengesSection extends StatelessWidget {
  const _ChallengesSection();

  @override
  Widget build(BuildContext context) {
    final challenges = context
        .watch<ChallengeProvider>()
        .currentWeekChallenges
        .take(2)
        .toList();
    if (challenges.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: EmptyState(
            icon: Icons.emoji_events_outlined,
            title: 'Sin desafíos esta semana',
            message: 'Ponte una meta semanal y mantén la motivación.',
            actionLabel: 'Crear desafío',
            onAction: () => _open(context, const ChallengesScreen()),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final c in challenges)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ChallengeTile(challenge: c),
          ),
      ],
    );
  }
}

class _ChallengeTile extends StatelessWidget {
  const _ChallengeTile({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = context.watch<ChallengeProvider>().progressFor(
      challenge,
      activities: context.watch<ActivityProvider>(),
      hydration: context.watch<HydrationProvider>(),
      steps: context.watch<StepProvider>(),
    );
    final ratio = challenge.target <= 0
        ? 0.0
        : (current / challenge.target).clamp(0.0, 1.0);
    final unit = challenge.type.unit;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context, const ChallengesScreen()),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(challenge.type.icon, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      challenge.title,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (ratio >= 1)
                    Icon(Icons.check_circle, color: theme.colorScheme.primary),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: ratio, minHeight: 8),
              ),
              const SizedBox(height: 6),
              Text(
                '${Fmt.integer(current)} / ${Fmt.integer(challenge.target)} $unit',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivities extends StatelessWidget {
  const _RecentActivities();

  @override
  Widget build(BuildContext context) {
    final recent = context
        .watch<ActivityProvider>()
        .activities
        .take(3)
        .toList();
    if (recent.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: EmptyState(
            icon: Icons.history,
            title: 'Aún no hay actividad',
            message: 'Registra tu primer entrenamiento.',
            actionLabel: 'Registrar actividad',
            onAction: () => _open(context, const ActivityFormScreen()),
          ),
        ),
      );
    }
    return Card(
      child: Column(
        children: [for (final a in recent) _ActivityRow(activity: a)],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final color = CategoryStyle.color(activity.category);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(CategoryStyle.icon(activity.category), color: color),
      ),
      title: Text(activity.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${Fmt.date(activity.date)} · ${activity.durationMinutes} min · '
        '${activity.calories} kcal',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
