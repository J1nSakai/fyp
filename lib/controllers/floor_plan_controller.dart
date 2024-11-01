import 'dart:ui';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:saysketch_v2/models/floor_base_model.dart';
import '../models/room_model.dart';

class FloorPlanController {
  FloorBase? _floorBase;
  final List<Room> _rooms = [];
  int _roomCounter = 0;

  Room? selectedRoom;
  String? selectedRoomName;

  static const double roomSpacing = 0.0; //  unit spacing between rooms

  void setDefaultBase() {
    const double defaultBaseWidth = 80;
    const double defaultBaseHeight = 50;
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
    const defaultRoomPosition = Offset(roomSpacing, roomSpacing);

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
      const defaultRoomPosition = Offset(roomSpacing, roomSpacing);
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
        lastRoom.position.dx + lastRoom.width + roomSpacing,
        lastRoom.position.dy);

    if (_roomFitsWithinBase(roomWidth, roomHeight, rightPosition) &&
        _roomDoesNotOverlapWithOtherRooms(
            roomWidth, roomHeight, rightPosition)) {
      return rightPosition;
    }

    // 2. Try position to the left
    Offset leftPosition = Offset(
        lastRoom.position.dx - roomWidth - roomSpacing, lastRoom.position.dy);

    if (_roomFitsWithinBase(roomWidth, roomHeight, leftPosition) &&
        _roomDoesNotOverlapWithOtherRooms(
            roomWidth, roomHeight, leftPosition)) {
      return leftPosition;
    }

    // 3. Try position below
    Offset bottomPosition = Offset(lastRoom.position.dx,
        lastRoom.position.dy + lastRoom.height + roomSpacing);

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
    double currentY = roomSpacing;

    while (currentY + roomHeight <= _floorBase!.height) {
      // Try placing rooms from left to right in each row
      double currentX = roomSpacing;

      while (currentX + roomWidth <= _floorBase!.width) {
        Offset testPosition = Offset(currentX, currentY);

        if (_roomDoesNotOverlapWithOtherRooms(
            roomWidth, roomHeight, testPosition)) {
          return testPosition;
        }

        currentX += roomWidth + roomSpacing;
      }

      currentY += roomHeight + roomSpacing;
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
        _roomCounter++;
        _rooms.add(Room(width, height, position, "room $_roomCounter"));
      } else {
        Fluttertoast.showToast(msg: "Room overlaps with existing rooms.");
      }
    } else {
      Fluttertoast.showToast(msg: "Room must be completely inside the base.");
    }
  }

  // In FloorPlanController class, add these new methods:

  void addRoomRelativeTo(
      double width, double height, int referenceRoomIndex, String position) {
    if (_floorBase == null) {
      Fluttertoast.showToast(msg: "Please create a base first");
      return;
    }

    if (referenceRoomIndex < 0 || referenceRoomIndex >= _rooms.length) {
      Fluttertoast.showToast(msg: "Invalid room reference number");
      return;
    }

    Room referenceRoom = _rooms[referenceRoomIndex];
    Offset? newPosition;

    switch (position) {
      case "below":
        newPosition = Offset(referenceRoom.position.dx,
            referenceRoom.position.dy + referenceRoom.height + roomSpacing);
        break;
      case "above":
        newPosition = Offset(referenceRoom.position.dx,
            referenceRoom.position.dy - height - roomSpacing);
        break;
      case "right":
        newPosition = Offset(
            referenceRoom.position.dx + referenceRoom.width + roomSpacing,
            referenceRoom.position.dy);
        break;
      case "left":
        newPosition = Offset(referenceRoom.position.dx - width - roomSpacing,
            referenceRoom.position.dy);
        break;
      default:
        Fluttertoast.showToast(msg: "Invalid position specified");
        return;
    }

    if (_roomFitsWithinBase(width, height, newPosition) &&
        _roomDoesNotOverlapWithOtherRooms(width, height, newPosition)) {
      addRoom(width, height, newPosition);
    } else {
      Fluttertoast.showToast(
          msg:
              "Cannot place room at specified position. Check for overlaps or base boundaries.");
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
      bool overlaps = !(position.dx + roomWidth + roomSpacing <=
              existingRoom.position.dx ||
          position.dx >=
              existingRoom.position.dx + existingRoom.width + roomSpacing ||
          position.dy + roomHeight + roomSpacing <= existingRoom.position.dy ||
          position.dy >=
              existingRoom.position.dy + existingRoom.height + roomSpacing);

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
    _roomCounter = 0;
    _rooms.clear();
  }

  void removeBase() {
    removeAllRooms();
    _floorBase = null;
  }

  void removeLastAddedRoom() {
    if (_rooms.isNotEmpty) {
      _rooms.removeLast();
      _roomCounter--;
    }
  }

  Room? selectRoom(String name) {
    for (Room room in _rooms) {
      if (room.name == name) {
        selectedRoom = room;
        selectedRoomName = room.name;
        return room;
      }
    }
    deselectRoom();
    return null;
  }

  void deselectRoom() {
    selectedRoom = null;
    selectedRoomName = null;
  }

  void renameRoom(String name) {
    selectedRoom!.name = name;
  }

  void removeSelectedRoom() {
    _rooms.remove(selectedRoom);
    deselectRoom();
  }

  void moveRoom(double newX, double newY) {
    if (selectedRoom == null) {
      Fluttertoast.showToast(msg: "Please select a room first");
      return;
    }

    if (_floorBase == null) {
      Fluttertoast.showToast(msg: "No base exists");
      return;
    }

    Offset newPosition = Offset(newX, newY);

    // Check if the new position would keep the room within base bounds
    if (_roomFitsWithinBase(
        selectedRoom!.width, selectedRoom!.height, newPosition)) {
      // Create a temporary list without the selected room to check overlap
      List<Room> otherRooms =
          _rooms.where((room) => room != selectedRoom).toList();

      bool wouldOverlap = false;
      for (final existingRoom in otherRooms) {
        if (_checkOverlap(
            newPosition,
            selectedRoom!.width,
            selectedRoom!.height,
            existingRoom.position,
            existingRoom.width,
            existingRoom.height)) {
          wouldOverlap = true;
          break;
        }
      }

      if (!wouldOverlap) {
        selectedRoom!.position = newPosition;
        Fluttertoast.showToast(msg: "Room moved successfully");
      } else {
        Fluttertoast.showToast(
            msg: "Cannot move room - would overlap with other rooms");
      }
    } else {
      Fluttertoast.showToast(msg: "Cannot move room outside base boundaries");
    }
  }

  bool _checkOverlap(
    Offset pos1,
    double width1,
    double height1,
    Offset pos2,
    double width2,
    double height2,
  ) {
    return !(pos1.dx + width1 + roomSpacing <= pos2.dx ||
        pos1.dx >= pos2.dx + width2 + roomSpacing ||
        pos1.dy + height1 + roomSpacing <= pos2.dy ||
        pos1.dy >= pos2.dy + height2 + roomSpacing);
  }

  void moveRoomToPosition(String position) {
    if (selectedRoom == null || _floorBase == null) {
      Fluttertoast.showToast(
          msg: "Please select a room and ensure base exists");
      return;
    }

    double newX, newY;

    switch (position.toLowerCase()) {
      case "center":
        newX = (_floorBase!.width - selectedRoom!.width) / 2;
        newY = (_floorBase!.height - selectedRoom!.height) / 2;
        break;
      case "topleft":
        newX = roomSpacing;
        newY = roomSpacing;
        break;
      case "topright":
        newX = _floorBase!.width - selectedRoom!.width - roomSpacing;
        newY = roomSpacing;
        break;
      case "bottomleft":
        newX = roomSpacing;
        newY = _floorBase!.height - selectedRoom!.height - roomSpacing;
        break;
      case "bottomright":
        newX = _floorBase!.width - selectedRoom!.width - roomSpacing;
        newY = _floorBase!.height - selectedRoom!.height - roomSpacing;
        break;
      default:
        Fluttertoast.showToast(msg: "Invalid position specified");
        return;
    }

    moveRoom(newX, newY);
  }

  void moveRoomRelative(double distance, String direction) {
    if (selectedRoom == null) {
      Fluttertoast.showToast(msg: "Please select a room first");
      return;
    }

    double newX = selectedRoom!.position.dx;
    double newY = selectedRoom!.position.dy;

    switch (direction.toLowerCase()) {
      case "right":
      case "east":
        newX += distance;
        break;
      case "left":
      case "west":
        newX -= distance;
        break;
      case "up":
      case "north":
        newY -= distance;
        break;
      case "down":
      case "south":
        newY += distance;
        break;
      default:
        Fluttertoast.showToast(msg: "Invalid direction specified");
        return;
    }

    moveRoom(newX, newY);
  }

  void moveRoomRelativeToOther(int referenceRoomIndex, String direction) {
    if (selectedRoom == null) {
      Fluttertoast.showToast(msg: "Please select a room first");
      return;
    }

    if (referenceRoomIndex < 0 || referenceRoomIndex >= _rooms.length) {
      Fluttertoast.showToast(msg: "Invalid room reference");
      return;
    }

    Room referenceRoom = _rooms[referenceRoomIndex];
    double newX = selectedRoom!.position.dx;
    double newY = selectedRoom!.position.dy;

    switch (direction.toLowerCase()) {
      case "right":
      case "east":
        newX = referenceRoom.position.dx + referenceRoom.width + roomSpacing;
        newY = referenceRoom.position.dy;
        break;
      case "left":
      case "west":
        newX = referenceRoom.position.dx - selectedRoom!.width - roomSpacing;
        newY = referenceRoom.position.dy;
        break;
      case "above":
      case "north":
        newX = referenceRoom.position.dx;
        newY = referenceRoom.position.dy - selectedRoom!.height - roomSpacing;
        break;
      case "below":
      case "south":
        newX = referenceRoom.position.dx;
        newY = referenceRoom.position.dy + referenceRoom.height + roomSpacing;
        break;
      default:
        Fluttertoast.showToast(msg: "Invalid direction specified");
        return;
    }

    moveRoom(newX, newY);
  }

  double convertToMetricUnits(double value, String unit) {
    switch (unit.toLowerCase()) {
      case "feet":
      case "foot":
      case "ft":
        return value; // Convert feet to meters
      case "inches":
      case "inch":
      case "in":
        return value * 0.0833; // Convert inches to meters
      case "meters":
      case "meter":
      case "m":
        return value * 3.28024;
      case "centimeters":
      case "centimeter":
      case "cm":
        return value * 0.0328; // Convert centimeters to meters
      default:
        return value; // Default to assuming feet
    }
  }
}
