import 'dart:ui';

class Stairs {
  double width;
  double length;
  Offset position;
  String direction; // "up" or "down"
  int numberOfSteps;
  String name;

  Stairs({
    required this.width,
    required this.length,
    required this.position,
    required this.direction,
    required this.numberOfSteps,
    required this.name,
  });

  @override
  String toString() =>
      "{width: $width, length: $length, position: $position, direction: $direction, numberOfSteps: $numberOfSteps, name: $name}";
}
