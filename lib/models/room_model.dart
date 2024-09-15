import 'dart:ui';

class Room {
  double width, height;
  Offset position;

  Room(this.width, this.height, this.position);

  @override
  String toString() =>
      "{width: $width, height: $height, positionX: ${position.dx}, positionY: ${position.dy}}";
}
