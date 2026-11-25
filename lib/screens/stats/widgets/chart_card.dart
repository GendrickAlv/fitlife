import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../stats_metrics.dart';

/// Tarjeta con título que envuelve un gráfico.
class ChartCard extends StatelessWidget {
  /// Crea la tarjeta.
  const ChartCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.height = 200,
  });

  /// Título de la tarjeta.
  final String title;

  /// Texto secundario opcional.
  final String? subtitle;

  /// Gráfico a mostrar.
  final Widget child;

  /// Alto del área del gráfico.
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(height: height, child: child),
          ],
        ),
      ),
    );
  }
}

/// Mensaje cuando un gráfico no tiene datos en el periodo.
class ChartEmpty extends StatelessWidget {
  /// Crea el mensaje.
  const ChartEmpty({
    super.key,
    this.message = 'Sin datos en este periodo',
    this.icon = Icons.bar_chart,
  });

  /// Texto a mostrar.
  final String message;

  /// Icono decorativo.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: scheme.outline),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Etiqueta del eje X para el día [index] de [days].
String dayAxisLabel(List<DateTime> days, int index) => days.length <= 7
    ? Fmt.weekdayInitial(days[index])
    : Fmt.shortDay(days[index]);

/// Títulos del eje inferior sin solapamiento, con etiquetas de [days].
AxisTitles bottomDayTitles(BuildContext context, List<DateTime> days) {
  final style = Theme.of(context).textTheme.labelSmall
      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
  final step = labelInterval(days.length);
  return AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      reservedSize: 28,
      interval: 1,
      getTitlesWidget: (value, meta) {
        final i = value.round();
        if (value != i.toDouble() || i < 0 || i >= days.length) {
          return const SizedBox.shrink();
        }
        if (i % step != 0) return const SizedBox.shrink();
        return SideTitleWidget(
          meta: meta,
          fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
          child: Text(dayAxisLabel(days, i), style: style),
        );
      },
    ),
  );
}

/// Títulos del eje izquierdo con valores compactos.
AxisTitles leftValueTitles(
  BuildContext context, {
  double reservedSize = 36,
  String Function(double)? format,
}) {
  final style = Theme.of(context).textTheme.labelSmall
      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
  return AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      reservedSize: reservedSize,
      getTitlesWidget: (value, meta) {
        if (value == meta.max || value == meta.min && value != 0) {
          return const SizedBox.shrink();
        }
        return SideTitleWidget(
          meta: meta,
          child: Text(format?.call(value) ?? Fmt.integer(value), style: style),
        );
      },
    ),
  );
}

/// Datos de cuadrícula sutil compartidos por los gráficos.
FlGridData gridFor(BuildContext context) => FlGridData(
  drawVerticalLine: false,
  getDrawingHorizontalLine: (_) => FlLine(
    color: Theme.of(context).colorScheme.outlineVariant,
    strokeWidth: 1,
  ),
);

/// Estilo de texto de los tooltips.
TextStyle tooltipStyle(BuildContext context) => TextStyle(
  color: Theme.of(context).colorScheme.onInverseSurface,
  fontWeight: FontWeight.w600,
  fontSize: 12,
);
