import 'package:flutter/material.dart';
import 'package:saysketch_v2/models/door.dart';
import 'package:saysketch_v2/models/window.dart';

class Room {
  double width;
  double height;
  Offset position;
  final List<Door> doors;
  final List<Window> windows;
  String name;
  Paint roomPaint;
  bool hasHiddenWalls = false;

  Room(
    this.width,
    this.height,
    this.position,
    this.name, {
    List<Door>? doors,
    List<Window>? windows,
  })  : doors = doors ?? [],
        windows = windows ?? [],
        roomPaint = Paint()
          ..color = Colors.black
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;

  @override
  String toString() {
    return "{width: $width, height: $height, position: ${position.dx}x${position.dy}, name: $name}";
  }
}
