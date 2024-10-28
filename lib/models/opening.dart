import 'dart:ui';

class Opening {
  final Offset position; // Position relative to room
  final double width;
  final double length;
  final double angle; // in radians, 0 means horizontal, PI/2 means vertical

  Opening({
    required this.position,
    required this.width,
    required this.length,
    required this.angle,
  });
}
