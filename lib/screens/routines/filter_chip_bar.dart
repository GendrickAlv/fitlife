import 'package:material_ui/material_ui.dart';

/// Descripción de un chip de [FilterChipBar].
class FilterChipSpec {
  /// Crea la descripción de un chip.
  const FilterChipSpec({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
}

/// Fila horizontal desplazable de [FilterChip].
class FilterChipBar extends StatelessWidget {
  /// Crea la barra de chips.
  const FilterChipBar({super.key, required this.chips});

  final List<FilterChipSpec> chips;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = chips[i];
          return Center(
            child: FilterChip(
              label: Text(c.label),
              avatar: c.icon == null ? null : Icon(c.icon, size: 18),
              selected: c.selected,
              onSelected: (_) => c.onTap(),
            ),
          );
        },
      ),
    );
  }
}
