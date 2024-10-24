import 'dart:ui';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:saysketch_v2/models/floor_base_model.dart';
import '../models/room_model.dart';

class FloorPlanController {
  FloorBase? _floorBase;
  final List<Room> _rooms = [];

  static const double SCALE_FACTOR = 10.0;
  static const double ROOM_SPACING = 0.0; // 1 unit spacing between rooms

  void setDefaultBase() {
    const double defaultBaseWidth = 30.5;
    const double defaultBaseHeight = 60;
    const Offset defaultBasePosition = Offset(0, 0);

    _floorBase =
        FloorBase(defaultBaseWidth, defaultBaseHeight, defaultBasePosition);
  }

  void addDefaultRoom() {
    if (_floorBase == null) {
      Fluttertoast.showToast(msg: "Please create a base first");
      return;
    }

    const double defaultRoomWidth = 10;
    const double defaultRoomHeight = 10;

    // For the first room, position it in the top-left corner with some margin
    const defaultRoomPosition = Offset(ROOM_SPACING, ROOM_SPACING);

    addRoom(defaultRoomWidth, defaultRoomHeight, defaultRoomPosition);
  }

  void addNextRoomWithDimensions(
      {required double width, required double height}) {
    if (_floorBase == null) {
      Fluttertoast.showToast(msg: "Please create a base first");
      return;
    }

    if (_rooms.isEmpty) {
      // For the first room, position it in the top-left corner with some margin
      const defaultRoomPosition = Offset(ROOM_SPACING, ROOM_SPACING);
      addRoom(width, height, defaultRoomPosition);
      return;
    }

    // Try to find a suitable position for the new room
    Offset? nextPosition = _findNextRoomPosition(width, height);

    if (nextPosition != null) {
      addRoom(width, height, nextPosition);
    } else {
      Fluttertoast.showToast(msg: "No suitable position found for new room");
    }
  }

  // Update existing addNextRoom to use default dimensions
  void addNextRoom() {
    const double defaultRoomWidth = 10;
    const double defaultRoomHeight = 10;
    addNextRoomWithDimensions(
        width: defaultRoomWidth, height: defaultRoomHeight);
  }

  Offset? _findNextRoomPosition(double roomWidth, double roomHeight) {
    if (_rooms.isEmpty || _floorBase == null) return null;

    Room lastRoom = _rooms.last;

    // 1. Try position to the right
    Offset rightPosition = Offset(
        lastRoom.position.dx + lastRoom.width + ROOM_SPACING,
        lastRoom.position.dy);

    if (_roomFitsWithinBase(roomWidth, roomHeight, rightPosition) &&
        _roomDoesNotOverlapWithOtherRooms(
            roomWidth, roomHeight, rightPosition)) {
      return rightPosition;
    }

    // 2. Try position to the left
    Offset leftPosition = Offset(
        lastRoom.position.dx - roomWidth - ROOM_SPACING, lastRoom.position.dy);

    if (_roomFitsWithinBase(roomWidth, roomHeight, leftPosition) &&
        _roomDoesNotOverlapWithOtherRooms(
            roomWidth, roomHeight, leftPosition)) {
      return leftPosition;
    }

    // 3. Try position below
    Offset bottomPosition = Offset(lastRoom.position.dx,
        lastRoom.position.dy + lastRoom.height + ROOM_SPACING);

    if (_roomFitsWithinBase(roomWidth, roomHeight, bottomPosition) &&
        _roomDoesNotOverlapWithOtherRooms(
            roomWidth, roomHeight, bottomPosition)) {
      return bottomPosition;
    }

    // If no direct positions work, try to find the next available row
    return _findAlternativePosition(roomWidth, roomHeight);
  }

  Offset? _findAlternativePosition(double roomWidth, double roomHeight) {
    if (_floorBase == null) return null;

    // Start from the top of the base with some margin
    double currentY = ROOM_SPACING;

    while (currentY + roomHeight <= _floorBase!.height) {
      // Try placing rooms from left to right in each row
      double currentX = ROOM_SPACING;

      while (currentX + roomWidth <= _floorBase!.width) {
        Offset testPosition = Offset(currentX, currentY);

        if (_roomDoesNotOverlapWithOtherRooms(
            roomWidth, roomHeight, testPosition)) {
          return testPosition;
        }

        currentX += roomWidth + ROOM_SPACING;
      }

      currentY += roomHeight + ROOM_SPACING;
    }

    return null;
  }

  void setBase(double width, double height, Offset position) {
    _floorBase = FloorBase(width, height, position);
  }

  void addRoom(double width, double height, Offset position) {
    if (_floorBase == null) {
      Fluttertoast.showToast(msg: "Base is not set yet.");
      return;
    }

    if (_roomFitsWithinBase(width, height, position)) {
      if (_roomDoesNotOverlapWithOtherRooms(width, height, position)) {
        _rooms.add(Room(width, height, position));
      } else {
        Fluttertoast.showToast(msg: "Room overlaps with existing rooms.");
      }
    } else {
      Fluttertoast.showToast(msg: "Room must be completely inside the base.");
    }
  }

  bool _roomFitsWithinBase(
      double roomWidth, double roomHeight, Offset position) {
    if (_floorBase == null) return false;

    return position.dx >= 0 &&
        position.dx + roomWidth <= _floorBase!.width &&
        position.dy >= 0 &&
        position.dy + roomHeight <= _floorBase!.height;
  }

  bool _roomDoesNotOverlapWithOtherRooms(
      double roomWidth, double roomHeight, Offset position) {
    for (final existingRoom in _rooms) {
      // Add a small buffer around rooms
      bool overlaps = !(position.dx + roomWidth + ROOM_SPACING <=
              existingRoom.position.dx ||
          position.dx >=
              existingRoom.position.dx + existingRoom.width + ROOM_SPACING ||
          position.dy + roomHeight + ROOM_SPACING <= existingRoom.position.dy ||
          position.dy >=
              existingRoom.position.dy + existingRoom.height + ROOM_SPACING);

      if (overlaps) return false;
    }
    return true;
  }

  List<Room> getRooms() {
    return _rooms;
  }

  FloorBase? getBase() {
    return _floorBase;
  }

  void removeAllRooms() {
    _rooms.clear();
  }

  void removeBase() {
    removeAllRooms();
    _floorBase = null;
  }

  void removeLastAddedRoom() {
    if (_rooms.isNotEmpty) {
      _rooms.removeLast();
    }
  }
}
