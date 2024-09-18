import 'dart:ui';

class FloorBase {
  double width, height;
  Offset position;

  FloorBase(this.width, this.height, this.position);

  @override
  String toString() =>
      "{width: $width, height: $height, positionX: ${position.dx}, positionY: ${position.dy}}";
}
