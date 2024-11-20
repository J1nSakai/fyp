import 'package:flutter/material.dart';
import 'package:saysketch_v2/models/door.dart';
import 'package:saysketch_v2/models/window.dart';
import 'package:saysketch_v2/models/space.dart';

class Room {
  double width;
  double height;
  Offset position;
  String name;
  Paint roomPaint;
  bool hasHiddenWalls = false;
  List<Door> doors = [];
  List<Window> windows = [];
  List<Space> spaces = [];
  int _doorCounter = 0;
  int _windowCounter = 0;
  int _spaceCounter = 0;

  Room(
    this.width,
    this.height,
    this.position,
    this.name, {
    List<Door>? doors,
    List<Window>? windows,
    List<Space>? spaces,
  }) : roomPaint = Paint()
          ..color = Colors.black
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;

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

  bool canAddSpace(String wall, double offset, double width) {
    double wallLength =
        (wall == "north" || wall == "south") ? this.width : height;

    if (offset < Space.minDistanceFromCorner ||
        offset + width > wallLength - Space.minDistanceFromCorner) {
      return false;
    }

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

    for (Space existingSpace in spaces) {
      if (existingSpace.wall == wall) {
        if (_doElementsOverlap(offset, width, existingSpace.offsetFromWallStart,
            existingSpace.width, Space.minDistanceFromDoors)) {
          return false;
        }
      }
    }

    return true;
  }

  bool canResizeDoor(String wall, double offset, double width,
      {Door? excludeDoor}) {
    double wallLength =
        (wall == "north" || wall == "south" || wall == "up" || wall == "down")
            ? this.width
            : height;
    if (offset < Door.minDistanceFromCorner ||
        offset + width > wallLength - Door.minDistanceFromCorner) {
      return false;
    }

    for (Door existingDoor in doors) {
      // Skip checking against the door we're resizing
      if (excludeDoor != null && existingDoor.id == excludeDoor.id) {
        continue;
      }

      if (existingDoor.wall == wall) {
        if (_doElementsOverlap(offset, width, existingDoor.offsetFromWallStart,
            existingDoor.width, Door.minDistanceBetweenDoors)) {
          return false;
        }
      }
    }

    // Rest of the checks remain the same
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

    for (Space existingSpace in spaces) {
      if (existingSpace.wall == wall) {
        if (_doElementsOverlap(offset, width, existingSpace.offsetFromWallStart,
            existingSpace.width, Space.minDistanceFromDoors)) {
          return false;
        }
      }
    }

    return true;
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

    for (Space existingSpace in spaces) {
      if (existingSpace.wall == wall) {
        if (_doElementsOverlap(offset, width, existingSpace.offsetFromWallStart,
            existingSpace.width, Space.minDistanceFromWindows)) {
          return false;
        }
      }
    }

    return true;
  }

  bool canResizeWindow(String wall, double offset, double width,
      {Window? excludeWindow}) {
    double wallLength =
        (wall == "north" || wall == "south" || wall == "up" || wall == "down")
            ? this.width
            : height;
    if (offset < Window.minDistanceFromCorner ||
        offset + width > wallLength - Window.minDistanceFromCorner) {
      return false;
    }

    for (Window existingWindow in windows) {
      // Skip checking against the window we're resizing
      if (excludeWindow != null && existingWindow.id == excludeWindow.id) {
        continue;
      }

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

    for (Space existingSpace in spaces) {
      if (existingSpace.wall == wall) {
        if (_doElementsOverlap(offset, width, existingSpace.offsetFromWallStart,
            existingSpace.width, Space.minDistanceFromWindows)) {
          return false;
        }
      }
    }

    return true;
  }

  bool canResizeSpace(String wall, double offset, double width,
      {Space? excludeSpace}) {
    double wallLength =
        (wall == "north" || wall == "south" || wall == "up" || wall == "down")
            ? this.width
            : height;
    if (offset < Space.minDistanceFromCorner ||
        offset + width > wallLength - Space.minDistanceFromCorner) {
      return false;
    }

    for (Space existingSpace in spaces) {
      // Skip checking against the space we're resizing
      if (excludeSpace != null && existingSpace.id == excludeSpace.id) {
        continue;
      }

      if (existingSpace.wall == wall) {
        if (_doElementsOverlap(offset, width, existingSpace.offsetFromWallStart,
            existingSpace.width, Space.minDistanceBetweenSpaces)) {
          return false;
        }
      }
    }

    for (Door existingDoor in doors) {
      if (existingDoor.wall == wall) {
        if (_doElementsOverlap(offset, width, existingDoor.offsetFromWallStart,
            existingDoor.width, Space.minDistanceFromDoors)) {
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
            Space.minDistanceFromWindows)) {
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
      'spaces': spaces.map((space) => space.toJson()).toList(),
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

    // Restore spaces
    if (json['spaces'] != null) {
      for (var spaceJson in json['spaces']) {
        room.spaces.add(Space.fromJson(spaceJson));
      }
    }

    return room;
  }
}
