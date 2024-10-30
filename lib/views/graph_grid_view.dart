import 'package:flutter/material.dart';

class GraphPaperBackground extends StatelessWidget {
  final double gridSpacing;
  final Color majorLineColor;
  final Color minorLineColor;
  final double majorLineThickness;
  final double minorLineThickness;
  final int minorLinesPerMajor;
  final double scale; // pixels per foot
  final double leftScaleWidth;
  final double topScaleHeight;

  const GraphPaperBackground({
    super.key,
    this.gridSpacing = 20.0,
    this.majorLineColor = const Color(0xFF9E9E9E),
    this.minorLineColor = const Color(0xFFE0E0E0),
    this.majorLineThickness = 1.0,
    this.minorLineThickness = 0.5,
    this.minorLinesPerMajor = 5,
    this.scale = 50.0, // 50 pixels = 1 foot by default
    this.leftScaleWidth = 40.0,
    this.topScaleHeight = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main graph paper
        Padding(
          padding: EdgeInsets.only(left: leftScaleWidth, top: topScaleHeight),
          child: CustomPaint(
            painter: GraphPaperPainter(
              gridSpacing: gridSpacing,
              majorLineColor: majorLineColor,
              minorLineColor: minorLineColor,
              majorLineThickness: majorLineThickness,
              minorLineThickness: minorLineThickness,
              minorLinesPerMajor: minorLinesPerMajor,
            ),
            child: Container(),
          ),
        ),
        // Left scale
        Positioned(
          left: 0,
          top: topScaleHeight,
          bottom: 0,
          child: CustomPaint(
            painter: ScalePainter(
              scale: scale,
              isHorizontal: false,
              majorLineColor: majorLineColor,
              scaleWidth: leftScaleWidth,
            ),
            size: Size(leftScaleWidth, double.infinity),
          ),
        ),
        // Top scale
        Positioned(
          left: leftScaleWidth,
          top: 0,
          right: 0,
          child: CustomPaint(
            painter: ScalePainter(
              scale: scale,
              isHorizontal: true,
              majorLineColor: majorLineColor,
              scaleWidth: topScaleHeight,
            ),
            size: Size(double.infinity, topScaleHeight),
          ),
        ),
      ],
    );
  }
}

class GraphPaperPainter extends CustomPainter {
  final double gridSpacing;
  final Color majorLineColor;
  final Color minorLineColor;
  final double majorLineThickness;
  final double minorLineThickness;
  final int minorLinesPerMajor;

  GraphPaperPainter({
    required this.gridSpacing,
    required this.majorLineColor,
    required this.minorLineColor,
    required this.majorLineThickness,
    required this.minorLineThickness,
    required this.minorLinesPerMajor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final minorSpacing = gridSpacing / minorLinesPerMajor;

    // Paint for minor lines
    final minorPaint = Paint()
      ..color = minorLineColor
      ..strokeWidth = minorLineThickness;

    // Paint for major lines
    final majorPaint = Paint()
      ..color = majorLineColor
      ..strokeWidth = majorLineThickness;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += minorSpacing) {
      final bool isMajor = (x / gridSpacing) % 1 == 0;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        isMajor ? majorPaint : minorPaint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += minorSpacing) {
      final bool isMajor = (y / gridSpacing) % 1 == 0;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        isMajor ? majorPaint : minorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(GraphPaperPainter oldDelegate) =>
      oldDelegate.gridSpacing != gridSpacing ||
      oldDelegate.majorLineColor != majorLineColor ||
      oldDelegate.minorLineColor != minorLineColor ||
      oldDelegate.majorLineThickness != majorLineThickness ||
      oldDelegate.minorLineThickness != minorLineThickness ||
      oldDelegate.minorLinesPerMajor != minorLinesPerMajor;
}

class ScalePainter extends CustomPainter {
  final double scale;
  final bool isHorizontal;
  final Color majorLineColor;
  final double scaleWidth;

  ScalePainter({
    required this.scale,
    required this.isHorizontal,
    required this.majorLineColor,
    required this.scaleWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = majorLineColor
      ..strokeWidth = 1.0;

    final textPaint = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    if (isHorizontal) {
      // Draw horizontal scale
      for (double x = 0; x < size.width; x += scale) {
        final feet = (x / scale).floor();
        canvas.drawLine(
          Offset(x, scaleWidth),
          Offset(x, scaleWidth - 10),
          paint,
        );

        textPaint.text = TextSpan(
          text: '$feet\'',
          style: TextStyle(
            color: majorLineColor,
            fontSize: 12,
          ),
        );
        textPaint.layout();
        textPaint.paint(
          canvas,
          Offset(x - textPaint.width / 2, scaleWidth - 25),
        );
      }
    } else {
      // Draw vertical scale
      for (double y = 0; y < size.height; y += scale) {
        final feet = (y / scale).floor();
        canvas.drawLine(
          Offset(scaleWidth, y),
          Offset(scaleWidth - 10, y),
          paint,
        );

        textPaint.text = TextSpan(
          text: '$feet\'',
          style: TextStyle(
            color: majorLineColor,
            fontSize: 12,
          ),
        );
        textPaint.layout();
        textPaint.paint(
          canvas,
          Offset(scaleWidth - textPaint.width - 15, y - textPaint.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(ScalePainter oldDelegate) =>
      oldDelegate.scale != scale ||
      oldDelegate.isHorizontal != isHorizontal ||
      oldDelegate.majorLineColor != majorLineColor;
}
