import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/routine.dart';
import '../../providers/routine_provider.dart';
import '../../widgets/empty_state.dart';
import 'filter_chip_bar.dart';
import 'routine_detail_screen.dart';
import 'routine_form_screen.dart';

/// Lista de rutinas con búsqueda y filtros.
class RoutinesScreen extends StatefulWidget {
  /// Crea la pantalla.
  const RoutinesScreen({super.key});

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  String _query = '';
  String? _category;
  bool _onlyFavorites = false;

  void _openForm() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const RoutineFormScreen()));
  }

  void _openDetail(Routine r) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => RoutineDetailScreen(routine: r)),
    );
  }

  List<Routine> _filter(List<Routine> all) {
    final q = _query.trim().toLowerCase();
    return all.where((r) {
      if (_category != null && r.category != _category) return false;
      if (_onlyFavorites && !r.isFavorite) return false;
      if (q.isNotEmpty &&
          !r.name.toLowerCase().contains(q) &&
          !r.description.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoutineProvider>();
    final all = provider.routines;
    final filtered = _filter(all);
    return Scaffold(
      appBar: AppBar(title: const Text('Rutinas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Nueva rutina'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              hintText: 'Buscar rutinas',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              onChanged: (v) => setState(() => _query = v),
              trailing: [
                if (_query.isNotEmpty)
                  IconButton(
                    tooltip: 'Limpiar búsqueda',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _query = ''),
                  ),
              ],
            ),
          ),
          FilterChipBar(
            chips: [
              FilterChipSpec(
                label: 'Todas',
                selected: _category == null && !_onlyFavorites,
                onTap: () => setState(() {
                  _category = null;
                  _onlyFavorites = false;
                }),
              ),
              FilterChipSpec(
                label: 'Favoritas',
                icon: Icons.star_outline,
                selected: _onlyFavorites,
                onTap: () => setState(() => _onlyFavorites = !_onlyFavorites),
              ),
              for (final c in RoutineCategory.all)
                FilterChipSpec(
                  label: c,
                  selected: _category == c,
                  onTap: () =>
                      setState(() => _category = _category == c ? null : c),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: _body(provider, all, filtered)),
        ],
      ),
    );
  }

  Widget _body(
    RoutineProvider provider,
    List<Routine> all,
    List<Routine> filtered,
  ) {
    if (provider.isLoading && all.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (all.isEmpty) {
      return EmptyState(
        icon: Icons.fitness_center,
        title: 'Aún no tienes rutinas',
        message: 'Crea tu primera rutina para organizar tus entrenamientos.',
        actionLabel: 'Nueva rutina',
        onAction: _openForm,
      );
    }
    if (filtered.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'Sin resultados',
        message: 'Prueba con otra búsqueda o cambia los filtros.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final r = filtered[i];
        return _RoutineCard(
          routine: r,
          onTap: () => _openDetail(r),
          onToggleFavorite: r.id == null
              ? null
              : () => context.read<RoutineProvider>().toggleFavorite(r.id!),
        );
      },
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    required this.routine,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final Routine routine;
  final VoidCallback onTap;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = CategoryStyle.color(routine.category);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.15),
                foregroundColor: color,
                child: Icon(CategoryStyle.icon(routine.category)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${routine.category} · ${routine.difficulty}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _Meta(
                          icon: Icons.timer_outlined,
                          text: '${routine.durationMinutes} min',
                        ),
                        _Meta(
                          icon: Icons.local_fire_department_outlined,
                          text: '${routine.estimatedCalories} kcal',
                        ),
                        _Meta(
                          icon: Icons.list_alt,
                          text: Fmt.plural(
                            routine.exercises.length,
                            'ejercicio',
                            'ejercicios',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: routine.isFavorite
                    ? 'Quitar de favoritas'
                    : 'Marcar favorita',
                icon: Icon(routine.isFavorite ? Icons.star : Icons.star_border),
                color: routine.isFavorite
                    ? Theme.of(context).colorScheme.tertiary
                    : theme.colorScheme.onSurfaceVariant,
                onPressed: onToggleFavorite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(text, style: theme.textTheme.labelMedium?.copyWith(color: color)),
      ],
    );
  }
}
