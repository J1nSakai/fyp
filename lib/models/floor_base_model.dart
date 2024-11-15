import 'dart:ui';

class FloorBase {
  double width, height;
  Offset position;

  FloorBase(this.width, this.height, this.position);

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
      'position': {
        'dx': position.dx,
        'dy': position.dy,
      },
    };
  }

  factory FloorBase.fromJson(Map<String, dynamic> json) {
    return FloorBase(
      json['width'],
      json['height'],
      Offset(
        json['position']['dx'],
        json['position']['dy'],
      ),
    );
  }

  // Optional: Create a copy of the floor base
  FloorBase copy() {
    return FloorBase(
      width,
      height,
      Offset(position.dx, position.dy),
    );
  }

  @override
  String toString() =>
      "{width: $width, height: $height, positionX: ${position.dx}, positionY: ${position.dy}}";
}
