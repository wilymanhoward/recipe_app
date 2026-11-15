import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';

/// The app's name: "Recipe" light, "Book" bold in the accent colour, with a
/// tapered brush stroke underneath, like a handwritten cookbook title.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 36});

  /// Font size of the name; the stroke under it scales with it.
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final base = theme.textTheme.headlineMedium?.copyWith(
      fontFamily: AppTheme.wordmarkFont,
      fontFamilyFallback: AppTheme.wordmarkFontFallback,
      fontSize: size,
      fontStyle: FontStyle.italic,
      letterSpacing: -0.5,
      height: 1.05,
      color: colors.onSurface,
    );

    // The stroke is as wide as the text: IntrinsicWidth takes its width from
    // the title, since the painter itself has none.
    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Recipe ',
                  style: TextStyle(fontWeight: FontWeight.w400),
                ),
                TextSpan(
                  text: 'Book',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
            style: base,
          ),
          SizedBox(height: size / 18),
          SizedBox(
            width: double.infinity,
            height: size / 3,
            child: CustomPaint(painter: _BrushStroke(colors.primary)),
          ),
        ],
      ),
    );
  }
}

/// A stroke that is thickest in the middle and thin at both ends.
class _BrushStroke extends CustomPainter {
  const _BrushStroke(this.color);

  final Color color;

  // Drawn on a 230 x 14 grid, then stretched to the available width.
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 230;
    final sy = size.height / 14;
    Offset p(double x, double y) => Offset(x * sx, y * sy);
    final path = Path()
      ..moveTo(p(2, 8).dx, p(2, 8).dy)
      ..cubicTo(
        p(50, 2).dx,
        p(50, 2).dy,
        p(120, 3).dx,
        p(120, 3).dy,
        p(182, 5).dx,
        p(182, 5).dy,
      )
      ..cubicTo(
        p(205, 6).dx,
        p(205, 6).dy,
        p(222, 6).dx,
        p(222, 6).dy,
        p(228, 5).dx,
        p(228, 5).dy,
      )
      ..cubicTo(
        p(200, 8).dx,
        p(200, 8).dy,
        p(120, 10).dx,
        p(120, 10).dy,
        p(60, 11).dx,
        p(60, 11).dy,
      )
      ..cubicTo(
        p(30, 12).dx,
        p(30, 12).dy,
        p(10, 11).dx,
        p(10, 11).dy,
        p(2, 8).dx,
        p(2, 8).dy,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BrushStroke old) => old.color != color;
}
