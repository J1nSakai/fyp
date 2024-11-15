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
  final List<Window> windows = [];
  int _windowCounter = 0;

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
        (wall == "north" || wall == "south" || wall == "up" || wall == "down")
            ? this.width
            : height;
    if (offset < Door.minDistanceFromCorner ||
        offset + width > wallLength - Door.minDistanceFromCorner) {
      return false;
    }

    for (Door existingDoor in doors) {
      if (existingDoor.wall == wall) {
        if (_doElementsOverlap(offset, width, existingDoor.offsetFromWallStart,
            existingDoor.width, Door.minDistanceBetweenDoors)) {
          return false;
        }
      }
    }

    for (Window existingWindow in windows) {
      if (existingWindow.wall == wall) {
        if (_doElementsOverlap(
            offset,
            width,
            existingWindow.offsetFromWallStart,
            existingWindow.width,
            Door.minDistanceFromWindows)) {
          return false;
        }
      }
    }

    return true;
  }

  String getNextWindowId() {
    _windowCounter++;
    return "$name:w:$_windowCounter";
  }

  bool canAddWindow(String wall, double offset, double width) {
    double wallLength =
        (wall == "north" || wall == "south" || wall == "up" || wall == "down")
            ? this.width
            : height;

    if (offset < Window.minDistanceFromCorner ||
        offset + width > wallLength - Window.minDistanceFromCorner) {
      return false;
    }

    for (Window existingWindow in windows) {
      if (existingWindow.wall == wall) {
        if (_doElementsOverlap(
            offset,
            width,
            existingWindow.offsetFromWallStart,
            existingWindow.width,
            Window.minDistanceBetweenWindows)) {
          return false;
        }
      }
    }

    for (Door existingDoor in doors) {
      if (existingDoor.wall == wall) {
        if (_doElementsOverlap(offset, width, existingDoor.offsetFromWallStart,
            existingDoor.width, Window.minDistanceFromDoors)) {
          return false;
        }
      }
    }

    return true;
  }

  @override
  String toString() {
    return "{width: $width, height: $height, position: ${position.dx}x${position.dy}, name: $name}";
  }

  bool _doElementsOverlap(double offset1, double width1, double offset2,
      double width2, double minDistance) {
    return (offset1 - minDistance <= offset2 + width2) &&
        (offset1 + width1 + minDistance >= offset2);
  }

  void clearHighlight() {
    roomPaint.color = Colors.black;
  }

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
      'position': {'dx': position.dx, 'dy': position.dy},
      'name': name,
      'hasHiddenWalls': hasHiddenWalls,
      'doors': doors.map((door) => door.toJson()).toList(),
      'windows': windows.map((window) => window.toJson()).toList(),
    };
  }

  factory Room.fromJson(Map<String, dynamic> json) {
    final room = Room(
      json['width'],
      json['height'],
      Offset(json['position']['dx'], json['position']['dy']),
      json['name'],
    );

    room.hasHiddenWalls = json['hasHiddenWalls'];

    // Restore doors
    for (var doorJson in json['doors']) {
      room.doors.add(Door.fromJson(doorJson));
    }

    // Restore windows
    for (var windowJson in json['windows']) {
      room.windows.add(Window.fromJson(windowJson));
    }

    return room;
  }
}
