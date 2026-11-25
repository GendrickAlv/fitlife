import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../data/models/routine.dart';
import '../../providers/routine_provider.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/confirm_dialog.dart';
import '../history/activity_form_screen.dart';
import 'routine_form_screen.dart';

/// Detalle de una [Routine] con sus ejercicios y acciones.
class RoutineDetailScreen extends StatelessWidget {
  /// Crea el detalle. [routine] es el valor inicial; se refresca desde el provider.
  const RoutineDetailScreen({super.key, required this.routine});

  final Routine routine;

  @override
  Widget build(BuildContext context) {
    final current = context.select<RoutineProvider, Routine?>(
      (p) => routine.id == null ? null : p.byId(routine.id!),
    );
    final r = current ?? routine;
    final color = CategoryStyle.color(r.category);
    return Scaffold(
      appBar: AppBar(
        title: Text(r.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: r.isFavorite ? 'Quitar de favoritas' : 'Marcar favorita',
            icon: Icon(r.isFavorite ? Icons.star : Icons.star_border),
            color: r.isFavorite ? Theme.of(context).colorScheme.tertiary : null,
            onPressed: r.id == null
                ? null
                : () => context.read<RoutineProvider>().toggleFavorite(r.id!),
          ),
          IconButton(
            tooltip: 'Editar rutina',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RoutineFormScreen(routine: r),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Eliminar rutina',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, r),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ActivityFormScreen(fromRoutine: r),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Registrar entrenamiento'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Header(routine: r, color: color),
          const SizedBox(height: 16),
          _StatsRow(routine: r, color: color),
          if (r.description.trim().isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Descripción', style: _title(context)),
            const SizedBox(height: 6),
            Text(r.description, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 20),
          Text('Ejercicios (${r.exercises.length})', style: _title(context)),
          const SizedBox(height: 8),
          for (var i = 0; i < r.exercises.length; i++)
            _ExerciseTile(index: i + 1, exercise: r.exercises[i], color: color),
        ],
      ),
    );
  }

  TextStyle? _title(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w600);

  Future<void> _delete(BuildContext context, Routine r) async {
    final id = r.id;
    if (id == null) return;
    final ok = await ConfirmDialog.show(
      context,
      'Eliminar rutina',
      '¿Seguro que quieres eliminar "${r.name}"? Esta acción no se puede deshacer.',
    );
    if (!ok || !context.mounted) return;
    final provider = context.read<RoutineProvider>();
    await provider.delete(id);
    if (!context.mounted) return;
    if (provider.error != null) {
      AppSnack.error(context, provider.error!);
      return;
    }
    AppSnack.success(context, 'Rutina eliminada');
    Navigator.of(context).pop();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.routine, required this.color});

  final Routine routine;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color,
            foregroundColor: Colors.white,
            child: Icon(CategoryStyle.icon(routine.category), size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routine.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  routine.category,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.routine, required this.color});

  final Routine routine;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            icon: Icons.timer_outlined,
            label: 'Duración',
            value: '${routine.durationMinutes} min',
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatBox(
            icon: Icons.local_fire_department_outlined,
            label: 'Calorías',
            value: '${routine.estimatedCalories} kcal',
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatBox(
            icon: Icons.speed,
            label: 'Dificultad',
            value: routine.difficulty,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({
    required this.index,
    required this.exercise,
    required this.color,
  });

  final int index;
  final Exercise exercise;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.15),
            foregroundColor: color,
            child: Text('$index'),
          ),
          title: Text(exercise.name),
          subtitle: Text(exerciseSummary(exercise)),
        ),
      ),
    );
  }
}
