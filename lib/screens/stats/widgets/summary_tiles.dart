import 'package:material_ui/material_ui.dart';

/// Datos de una tarjeta de resumen.
class SummaryItem {
  /// Crea un dato de resumen.
  const SummaryItem(this.icon, this.label, this.value, {this.color});

  /// Icono.
  final IconData icon;

  /// Etiqueta corta.
  final String label;

  /// Valor ya formateado.
  final String value;

  /// Color de acento (por defecto el primario).
  final Color? color;
}

/// Cuadrícula de dos columnas con resúmenes numéricos.
class SummaryTiles extends StatelessWidget {
  /// Crea la cuadrícula.
  const SummaryTiles({super.key, required this.items});

  /// Elementos a mostrar.
  final List<SummaryItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final it in items)
              SizedBox(
                width: w,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          it.icon,
                          color: it.color ?? theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  it.value,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                it.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
