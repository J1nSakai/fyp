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

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'length': length,
      'position': {
        'dx': position.dx,
        'dy': position.dy,
      },
      'direction': direction,
      'numberOfSteps': numberOfSteps,
      'name': name,
    };
  }

  factory Stairs.fromJson(Map<String, dynamic> json) {
    return Stairs(
      width: json['width'],
      length: json['length'],
      position: Offset(
        json['position']['dx'],
        json['position']['dy'],
      ),
      direction: json['direction'],
      numberOfSteps: json['numberOfSteps'],
      name: json['name'],
    );
  }

  // Optional: Create a copy of the stairs
  Stairs copy() {
    return Stairs(
      width: width,
      length: length,
      position: Offset(position.dx, position.dy),
      direction: direction,
      numberOfSteps: numberOfSteps,
      name: name,
    );
  }

  @override
  String toString() =>
      "{width: $width, length: $length, position: $position, direction: $direction, numberOfSteps: $numberOfSteps, name: $name}";
}
