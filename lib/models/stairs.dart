import 'dart:ui';

class Stairs {
  double width;
  double length;
  Offset position;
  String direction; // "up" or "down"
  int numberOfSteps;
  String name;
  bool isHighlighted = false;
  double heightDifference; // Added for step calculations
  double treadDepth; // Added for step calculations

  static const double minWidth = 2.5; // Absolute minimum width
  static const double minLength = 4.0; // Absolute minimum length
  static const double riserHeight = 0.5; // Standard step height
  static const double minTreadDepth = 0.75; // Minimum depth per step
  static const double standardFloorHeight =
      8.0; // Standard floor-to-floor height

  Stairs({
    required this.width,
    required this.length,
    required this.position,
    required this.direction,
    required this.numberOfSteps,
    required this.name,
    this.heightDifference = standardFloorHeight,
    this.isHighlighted = false,
  }) : treadDepth = length / numberOfSteps {
    updateStepCalculations();
  }

  void updateStepCalculations() {
    // Update number of steps based on new dimensions
    numberOfSteps = (heightDifference / riserHeight).ceil();
    treadDepth = length / numberOfSteps;
  }

  void clearHighlight() {
    isHighlighted = false;
  }

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
      'heightDifference': heightDifference,
      'treadDepth': treadDepth,
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
      heightDifference: json['heightDifference'] ?? standardFloorHeight,
    );
  }

  Stairs copy() {
    return Stairs(
      width: width,
      length: length,
      position: Offset(position.dx, position.dy),
      direction: direction,
      numberOfSteps: numberOfSteps,
      name: name,
      heightDifference: heightDifference,
      isHighlighted: isHighlighted,
    );
  }

  @override
  String toString() =>
      "{width: $width, length: $length, position: $position, direction: $direction, "
      "numberOfSteps: $numberOfSteps, name: $name, heightDifference: $heightDifference, "
      "treadDepth: $treadDepth}";

  // Helper method to validate dimensions and calculate if a resize would work
  bool canResize(double newWidth, double newLength) {
    if (newWidth < minWidth || newLength < minLength) {
      return false;
    }

    // Calculate steps and tread depth with new length
    int requiredSteps = (heightDifference / riserHeight).ceil();
    double newTreadDepth = newLength / requiredSteps;

    return newTreadDepth >= minTreadDepth;
  }
}
