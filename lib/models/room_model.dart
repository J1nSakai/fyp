import 'package:flutter/material.dart';
import 'package:saysketch_v2/models/door.dart';
import 'package:saysketch_v2/models/window.dart';

class Room {
  double width;
  double height;
  Offset position;
  String name;
  Paint roomPaint;
  bool hasHiddenWalls = false;
  final List<Door> doors = [];
  int _doorCounter = 0;

  Room(
    this.width,
    this.height,
    this.position,
    this.name, {
    List<Door>? doors,
    List<Window>? windows,
  }) : roomPaint = Paint()
          ..color = Colors.black
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;

  String getNextDoorId() {
    _doorCounter++;
    return "$name:$_doorCounter";
  }

  bool canAddDoor(String wall, double offset, double width) {
    double wallLength =
        (wall == "north" || wall == "south") ? this.width : height;
    if (offset + width > wallLength) return false;

    if (offset < Door.minDistanceFromCorner ||
        offset > wallLength - width - Door.minDistanceFromCorner) return false;

    for (Door door in doors.where((d) => d.wall == wall)) {
      if ((offset >= door.offsetFromWallStart - Door.minDistanceBetweenDoors) &&
          (offset <=
              door.offsetFromWallStart +
                  door.width +
                  Door.minDistanceBetweenDoors)) {
        return false;
      }
    }

    return true;
  }

  @override
  String toString() {
    return "{width: $width, height: $height, position: ${position.dx}x${position.dy}, name: $name}";
  }
}
