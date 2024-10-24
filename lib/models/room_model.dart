import 'dart:ui';

class Room {
  double width, height;
  Offset position;

  Room(this.width, this.height, this.position);

  @override
  String toString() =>
      "{width: $width, height: $height, positionX: ${position.dx}, positionY: ${position.dy}}";
}

// Room Position Model and Updated Controllers

// Create a new file: lib/models/room_position.dart
class RoomPosition {
  final int referenceRoomIndex;
  final String position; // "above", "below", "left", "right"

  RoomPosition(this.referenceRoomIndex, this.position);

  @override
  String toString() {
    return 'RoomPosition{referenceRoomIndex: $referenceRoomIndex, position: $position}';
  }
}
