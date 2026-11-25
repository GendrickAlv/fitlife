import 'package:material_ui/material_ui.dart';

/// Anillo de progreso circular con contenido central.
class ProgressRing extends StatelessWidget {
  /// Crea un anillo de progreso ([progress] entre 0 y 1).
  const ProgressRing({
    super.key,
    required this.progress,
    required this.center,
    this.color,
    this.size = 96,
    this.strokeWidth = 10,
  });

  final double progress;
  final Widget center;
  final Color? color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = progress.isNaN ? 0.0 : progress.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.round,
              color: color ?? scheme.primary,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          center,
        ],
      ),
    );
  }
}
