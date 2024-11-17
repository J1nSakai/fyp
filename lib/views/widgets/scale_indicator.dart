import 'package:flutter/material.dart';

class ScaleIndicator extends StatelessWidget {
  final double zoomLevel;

  const ScaleIndicator({super.key, required this.zoomLevel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scale text
          Text(
            '1ft = 24px',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 8),
          // Ruler
          SizedBox(
            height: 32,
            width: 120, // 5ft * 24px = 120px
            child: CustomPaint(
              painter: RulerPainter(
                primaryColor: theme.colorScheme.secondary,
                accentColor: theme.colorScheme.tertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Separate painter for the ruler
class RulerPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;

  RulerPainter({
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rulerPaint = Paint()
      ..color = accentColor // Using accent color for the main line
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final markerPaint = Paint()
      ..color = primaryColor // Using primary color for markers
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(
      color: primaryColor, // Using primary color for text
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    // Draw main line
    canvas.drawLine(
      Offset.zero,
      Offset(size.width, 0),
      rulerPaint,
    );

    // Draw markers and numbers
    for (int i = 0; i <= 5; i++) {
      final x = i * (size.width / 5);

      // Draw marker
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, 8),
        markerPaint,
      );

      // Draw number
      final textSpan = TextSpan(
        text: '${i}ft',
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, 12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant RulerPainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.accentColor != accentColor;
}
