import 'dart:ui';

import 'package:saysketch_v2/models/door.dart';
import 'package:saysketch_v2/models/window.dart';

class Room {
  final double width;
  final double height;
  Offset position;
  final List<Door> doors;
  final List<Window> windows;
  String name;

  Room(
    this.width,
    this.height,
    this.position,
    this.name, {
    List<Door>? doors,
    List<Window>? windows,
  })  : doors = doors ?? [],
        windows = windows ?? [];

  @override
  String toString() {
    // TODO: implement toString
    return "{width: $width, height: $height, position: ${position.dx}x${position.dy}, name: $name}";
  }
}
