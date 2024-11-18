import 'package:flutter/material.dart';
import 'package:saysketch_v2/models/door.dart';
import 'package:saysketch_v2/models/window.dart';
import 'package:saysketch_v2/models/space.dart';

class CutOut {
  final String name;
  double width;
  double height;
  Offset position;
  List<Door> doors = [];
  List<Window> windows = [];
  List<Space> spaces = [];
  int _doorCounter = 0;
  int _windowCounter = 0;
  int _spaceCounter = 0;
  Paint cutOutPaint = Paint()
    ..color = Colors.black.withOpacity(0.6)
    ..strokeWidth = 3
    ..style = PaintingStyle.stroke;

  CutOut(this.width, this.height, this.position, this.name);

  String getNextDoorId() {
    _doorCounter++;
    return "$name:d:$_doorCounter";
  }

  String getNextWindowId() {
    _windowCounter++;
    return "$name:w:$_windowCounter";
  }

  String getNextSpaceId() {
    _spaceCounter++;
    return "$name:s:$_spaceCounter";
  }

  bool canAddDoor(String wall, double offset, double width) {
    // Just check overlap with existing elements
    for (Door existingDoor in doors) {
      if (existingDoor.wall == wall) {
        if (_doElementsOverlap(offset, width, existingDoor.offsetFromWallStart,
            existingDoor.width, Door.minDistanceBetweenDoors)) {
          return false;
        }
      }
    }

    // Check overlap with windows
    for (Window window in windows) {
      if (window.wall == wall) {
        if (_doElementsOverlap(offset, width, window.offsetFromWallStart,
            window.width, Door.minDistanceFromWindows)) {
          return false;
        }
      }
    }

    // Check overlap with spaces
    for (Space space in spaces) {
      if (space.wall == wall) {
        if (_doElementsOverlap(offset, width, space.offsetFromWallStart,
            space.width, Space.minDistanceFromDoors)) {
          return false;
        }
      }
    }

    return true;
  }

  bool canAddWindow(String wall, double offset, double width) {
    // Check overlap with existing windows
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

    // Check overlap with doors
    for (Door door in doors) {
      if (door.wall == wall) {
        if (_doElementsOverlap(offset, width, door.offsetFromWallStart,
            door.width, Window.minDistanceFromDoors)) {
          return false;
        }
      }
    }

    // Check overlap with spaces
    for (Space space in spaces) {
      if (space.wall == wall) {
        if (_doElementsOverlap(offset, width, space.offsetFromWallStart,
            space.width, Space.minDistanceFromWindows)) {
          return false;
        }
      }
    }

    return true;
  }

  bool canAddSpace(String wall, double offset, double width) {
    // Check overlap with existing spaces
    for (Space existingSpace in spaces) {
      if (existingSpace.wall == wall) {
        if (_doElementsOverlap(offset, width, existingSpace.offsetFromWallStart,
            existingSpace.width, Space.minDistanceBetweenSpaces)) {
          return false;
        }
      }
    }

    // Check overlap with doors
    for (Door door in doors) {
      if (door.wall == wall) {
        if (_doElementsOverlap(offset, width, door.offsetFromWallStart,
            door.width, Space.minDistanceFromDoors)) {
          return false;
        }
      }
    }

    // Check overlap with windows
    for (Window window in windows) {
      if (window.wall == wall) {
        if (_doElementsOverlap(offset, width, window.offsetFromWallStart,
            window.width, Space.minDistanceFromWindows)) {
          return false;
        }
      }
    }

    return true;
  }

  bool _doElementsOverlap(double offset1, double width1, double offset2,
      double width2, double minDistance) {
    return (offset1 - minDistance < offset2 + width2) &&
        (offset1 + width1 + minDistance > offset2);
  }

  void clearHighlight() {
    cutOutPaint.color = Colors.black.withOpacity(0.6);
  }

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
      'position': {'dx': position.dx, 'dy': position.dy},
      'name': name,
      'doors': doors.map((door) => door.toJson()).toList(),
      'windows': windows.map((window) => window.toJson()).toList(),
      'spaces': spaces.map((space) => space.toJson()).toList(),
    };
  }

  factory CutOut.fromJson(Map<String, dynamic> json) {
    final cutOut = CutOut(
      json['width'],
      json['height'],
      Offset(json['position']['dx'], json['position']['dy']),
      json['name'],
    );

    // Restore doors
    for (var doorJson in json['doors']) {
      cutOut.doors.add(Door.fromJson(doorJson));
    }

    // Restore windows
    for (var windowJson in json['windows']) {
      cutOut.windows.add(Window.fromJson(windowJson));
    }

    // Restore spaces
    for (var spaceJson in json['spaces']) {
      cutOut.spaces.add(Space.fromJson(spaceJson));
    }

    return cutOut;
  }

  @override
  String toString() {
    return "{width: $width, height: $height, position: ${position.dx}x${position.dy}, name: $name}";
  }
}
