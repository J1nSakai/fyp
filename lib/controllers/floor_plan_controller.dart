import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:saysketch_v2/models/floor_base_model.dart';
import 'package:saysketch_v2/models/stairs.dart';
import 'package:saysketch_v2/services/message_service.dart';
import '../models/room_model.dart';

class FloorPlanController extends ChangeNotifier {
  FloorBase? _floorBase;
  final List<Room> _rooms = [];
  int _roomCounter = 0;
  final List<Stairs> _stairs = [];
  int _stairsCounter = 0;

  Stairs? selectedStairs;
  Room? selectedRoom;
  String? selectedRoomName;

  late Color originalColor;

  static const double roomSpacing = 0.0; //  unit spacing between rooms

  double _zoomLevel = 1.0;
  static const double _zoomIncrement = 0.2;
  static const double _minZoom = 0.5;
  static const double _maxZoom = 4.0;

  // All getters:
  double get zoomLevel => _zoomLevel;

  List<Room> getRooms() {
    return _rooms;
  }

  FloorBase? getBase() {
    return _floorBase;
  }

  List<Stairs> getStairs() {
    return _stairs;
  }

  // All base building methods:
  void setDefaultBase() {
    const double defaultBaseWidth = 30.0;
    const double defaultBaseHeight = 20.0;
    const Offset defaultBasePosition = Offset(0, 0);

    _floorBase =
        FloorBase(defaultBaseWidth, defaultBaseHeight, defaultBasePosition);
  }

  void setBase(double width, double height, Offset position) {
    _floorBase = FloorBase(width, height, position);
  }

  // All room building methods:
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

  void addDefaultRoom() {
    if (_floorBase == null) {
      Fluttertoast.showToast(msg: "Please create a base first");
      return;
    }

    const double defaultRoomWidth = 20;
    const double defaultRoomHeight = 15;

    // For the first room, position it in the top-left corner with some margin
    const defaultRoomPosition = Offset(roomSpacing, roomSpacing);

    addRoom(defaultRoomWidth, defaultRoomHeight, defaultRoomPosition);
  }

  void addNextRoom() {
    const double defaultRoomWidth = 10;
    const double defaultRoomHeight = 10;
    addNextRoomWithDimensions(
        width: defaultRoomWidth, height: defaultRoomHeight);
  }

  void addNextRoomWithDimensions(
      {required double width, required double height}) {
    if (_floorBase == null) {
      Fluttertoast.showToast(msg: "Please create a base first");
      return;
    }

    if (_rooms.isEmpty && _stairs.isEmpty) {
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

  // All room positioning helper methods:
  Offset? _findNextRoomPosition(double roomWidth, double roomHeight) {
    if (_floorBase == null) return null;

    // If this is the first element (no rooms and no stairs), start from top-left
    if (_rooms.isEmpty && _stairs.isEmpty) {
      Offset initialPosition = const Offset(roomSpacing, roomSpacing);
      if (_roomFitsWithinBase(roomWidth, roomHeight, initialPosition) &&
          _roomDoesNotOverlapWithOtherRooms(
              roomWidth, roomHeight, initialPosition)) {
        print("done1");
        return initialPosition;
      }
    }

    // Get the last placed element's position and dimensions
    Offset? lastPosition;
    double lastWidth = 0;
    double lastHeight = 0;

    if (_rooms.isNotEmpty) {
      Room lastRoom = _rooms.last;
      lastPosition = lastRoom.position;
      lastWidth = lastRoom.width;
      lastHeight = lastRoom.height;
    } else if (_stairs.isNotEmpty) {
      Stairs lastStairs = _stairs.last;
      lastPosition = lastStairs.position;
      lastWidth = lastStairs.width;
      lastHeight = lastStairs.length;
    }

    if (lastPosition != null) {
      // Try positions in all four directions from the last element
      List<Offset> candidatePositions = [
        // Right
        Offset(lastPosition.dx + lastWidth + roomSpacing, lastPosition.dy),
        // Left
        Offset(lastPosition.dx - roomWidth - roomSpacing, lastPosition.dy),
        // Below
        Offset(lastPosition.dx, lastPosition.dy + lastHeight + roomSpacing),
        // Above
        Offset(lastPosition.dx, lastPosition.dy - roomHeight - roomSpacing),
      ];

      // Try each candidate position
      for (Offset position in candidatePositions) {
        if (_roomFitsWithinBase(roomWidth, roomHeight, position) &&
            _roomDoesNotOverlapWithOtherRooms(
                roomWidth, roomHeight, position)) {
          print("done 2");
          return position;
        }
      }
    }

    // If no direct positions work, try a grid-based search
    return _findAlternativePositionForRoom(roomWidth, roomHeight);
  }

  Offset? _findAlternativePositionForRoom(double roomWidth, double roomHeight) {
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
    // Check overlap with existing rooms
    for (final room in _rooms) {
      if (_checkOverlap(position, roomWidth, roomHeight, room.position,
          room.width, room.height)) {
        return false;
      }
    }

    // Add check for overlap with stairs
    for (final stairs in _stairs) {
      if (_checkOverlap(position, roomWidth, roomHeight, stairs.position,
          stairs.width, stairs.length)) {
        return false;
      }
    }

    return true;
  }

  // Offset? _findPositionInGrid(double roomWidth, double roomHeight) {
  //   if (_floorBase == null) return null;

  //   double gridSpacing = roomSpacing;

  //   // Start from top-left corner
  //   for (double y = roomSpacing;
  //       y + roomHeight <= _floorBase!.height;
  //       y += gridSpacing) {
  //     for (double x = roomSpacing;
  //         x + roomWidth <= _floorBase!.width;
  //         x += gridSpacing) {
  //       Offset candidatePosition = Offset(x, y);

  //       if (_roomFitsWithinBase(roomWidth, roomHeight, candidatePosition) &&
  //           _roomDoesNotOverlapWithOtherRooms(
  //               roomWidth, roomHeight, candidatePosition)) {
  //         print("done 3");
  //         return candidatePosition;
  //       }
  //     }
  //   }
  //   print("done 4");
  //   return null;
  // }

  // All stairs building methods:
  void addStairs(double width, double length, Offset position, String direction,
      int numberOfSteps) {
    if (_floorBase == null) {
      Fluttertoast.showToast(msg: "Base is not set yet.");
      return;
    }

    _stairsCounter++;
    _stairs.add(Stairs(
        width: width,
        length: length,
        position: position,
        direction: direction,
        numberOfSteps: numberOfSteps,
        name: "stairs $_stairsCounter"));
    Fluttertoast.showToast(msg: "Stairs added successfully");
  }

  void addNextStairs({
    required double width,
    required double length,
    required String direction,
    required int numberOfSteps,
  }) {
    if (_floorBase == null) {
      Fluttertoast.showToast(msg: "Please create a base first");
      return;
    }

    // Find next available position for stairs
    Offset? nextPosition = _findNextStairsPosition(width, length);

    if (nextPosition != null) {
      addStairs(width, length, nextPosition, direction, numberOfSteps);
    } else {
      Fluttertoast.showToast(msg: "No suitable position found for new stairs");
    }
  }

  // All base removal methods:
  void removeBase() {
    removeAllRooms();
    removeAllStairs();
    _floorBase = null;
  }

  // All room removal methods:
  void removeAllRooms() {
    _roomCounter = 0;
    _rooms.clear();
  }

  void removeLastAddedRoom() {
    if (_rooms.isNotEmpty) {
      _rooms.removeLast();
      _roomCounter--;
    }
  }

  void removeSelectedRoom() {
    _rooms.remove(selectedRoom);
    deselectRoom();
  }

  // All stairs removal methods:
  void removeSelectedStairs() {
    if (selectedStairs != null) {
      _stairs.remove(selectedStairs);
      deselectStairs();
    }
  }

  void removeAllStairs() {
    _stairs.clear();
    _stairsCounter = 0;
    deselectStairs();
  }

  // All room selection methods:
  Room? selectRoom(String name) {
    for (Room room in _rooms) {
      if (room.name == name) {
        deselectRoom();
        selectedRoom = room;
        selectedRoomName = room.name;
        originalColor = room.hasHiddenWalls ? Colors.transparent : Colors.black;
        room.roomPaint.color = Colors.red;
        deselectStairs();
        return room;
      }
    }

    deselectRoom();
    return null;
  }

  void deselectRoom() {
    if (selectedRoom != null) {
      selectedRoom!.roomPaint.color =
          selectedRoom!.hasHiddenWalls ? Colors.transparent : Colors.black;
    }
    selectedRoom = null;
    selectedRoomName = null;
  }

  // Room renaming method:
  void renameRoom(String name) {
    selectedRoom!.name = name;
  }

  // All room movement methods:
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

  void moveRoomToPosition(String position, BuildContext context) {
    if (selectedRoom == null || _floorBase == null) {
      Fluttertoast.showToast(
          msg: "Please select a room and ensure base exists");
      return;
    }

    double newX = selectedRoom!.position.dx;
    double newY = selectedRoom!.position.dy;

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
      case "right":
        // Find the rightmost point of all rooms except the selected one
        double rightmostPoint = 0;
        for (Room room in _rooms) {
          if (room != selectedRoom) {
            double roomRightEdge = room.position.dx + room.width;
            if (roomRightEdge > rightmostPoint) {
              rightmostPoint = roomRightEdge;
            }
          }
        }
        newX = rightmostPoint;
        break;
      case "left":
        // Find the leftmost point of all rooms except the selected one
        double leftmostPoint = double.infinity;
        for (Room room in _rooms) {
          if (room != selectedRoom) {
            if (room.position.dx < leftmostPoint) {
              leftmostPoint = room.position.dx;
            }
          }
        }
        newX = leftmostPoint - selectedRoom!.width;
        break;
      case "up":
        // Find the topmost point of all rooms except the selected one
        double topmostPoint = double.infinity;
        for (Room room in _rooms) {
          if (room != selectedRoom) {
            if (room.position.dy < topmostPoint) {
              topmostPoint = room.position.dy;
            }
          }
        }
        newY = topmostPoint - selectedRoom!.height;
        break;
      case "down":
        // Find the bottommost point of all rooms except the selected one
        double bottommostPoint = 0;
        for (Room room in _rooms) {
          if (room != selectedRoom) {
            double roomBottomEdge = room.position.dy + room.height;
            if (roomBottomEdge > bottommostPoint) {
              bottommostPoint = roomBottomEdge;
            }
          }
        }
        newY = bottommostPoint;
        break;
      default:
        MessageService.showMessage(context, "Invalid position specified",
            type: MessageType.error);
        return;
    }

    moveRoom(newX, newY);
    MessageService.showMessage(
        context, "Moved ${selectedRoom!.name} to $position",
        type: MessageType.success);
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

  void moveRoomRelativeToStairs(int referenceStairsIndex, String direction) {
    if (selectedRoom == null) {
      Fluttertoast.showToast(msg: "Please select a room first");
      return;
    }

    if (referenceStairsIndex < 0 || referenceStairsIndex >= _stairs.length) {
      Fluttertoast.showToast(msg: "Invalid stairs reference");
      return;
    }

    Stairs referenceStairs = _stairs[referenceStairsIndex];
    double newX = selectedRoom!.position.dx;
    double newY = selectedRoom!.position.dy;

    switch (direction.toLowerCase()) {
      case "right":
      case "east":
        newX =
            referenceStairs.position.dx + referenceStairs.width + roomSpacing;
        newY = referenceStairs.position.dy;
        break;
      case "left":
      case "west":
        newX = referenceStairs.position.dx - selectedRoom!.width - roomSpacing;
        newY = referenceStairs.position.dy;
        break;
      case "above":
      case "north":
        newX = referenceStairs.position.dx;
        newY = referenceStairs.position.dy - selectedRoom!.height - roomSpacing;
        break;
      case "below":
      case "south":
        newX = referenceStairs.position.dx;
        newY =
            referenceStairs.position.dy + referenceStairs.length + roomSpacing;
        break;
      default:
        Fluttertoast.showToast(msg: "Invalid direction specified");
        return;
    }

    moveRoom(newX, newY);
  }

  // Room resizing method:
  void resizeRoom(double newWidth, double newHeight) {
    if (selectedRoom == null) {
      Fluttertoast.showToast(msg: "Please select a room first");
      return;
    }

    if (_floorBase == null) {
      Fluttertoast.showToast(msg: "No base exists");
      return;
    }

    // Check if new dimensions are valid
    if (newWidth <= 0 || newHeight <= 0) {
      Fluttertoast.showToast(
          msg: "Invalid dimensions. Must be greater than 0.");
      return;
    }

    // Store current position
    Offset currentPosition = selectedRoom!.position;

    // Check if the room would still fit within the base with new dimensions
    if (!_roomFitsWithinBase(newWidth, newHeight, currentPosition)) {
      Fluttertoast.showToast(
          msg: "New size would place room outside base boundaries");
      return;
    }

    // Create a temporary list without the selected room to check overlap
    List<Room> otherRooms =
        _rooms.where((room) => room != selectedRoom).toList();

    // Check for overlaps with other rooms
    bool wouldOverlap = false;
    for (final existingRoom in otherRooms) {
      if (_checkOverlap(currentPosition, newWidth, newHeight,
          existingRoom.position, existingRoom.width, existingRoom.height)) {
        wouldOverlap = true;
        break;
      }
    }

    if (!wouldOverlap) {
      selectedRoom!.width = newWidth;
      selectedRoom!.height = newHeight;
      Fluttertoast.showToast(msg: "Room resized successfully");
    } else {
      Fluttertoast.showToast(
          msg: "Cannot resize room - would overlap with other rooms");
    }
  }

  // Room walls hiding method:
  void hideWalls() {
    if (selectedRoom != null) {
      selectedRoom!.hasHiddenWalls = true;
      selectedRoom!.roomPaint.color = Colors.grey.withOpacity(0.3);
      Fluttertoast.showToast(msg: "Walls hidden for ${selectedRoom!.name}");
    } else {
      Fluttertoast.showToast(msg: "Please select a room first");
    }
  }

  // Room walls showing method:
  void showWalls() {
    if (selectedRoom != null) {
      selectedRoom!.hasHiddenWalls = false;
      selectedRoom!.roomPaint.color = Colors.black;
      Fluttertoast.showToast(msg: "Walls shown for ${selectedRoom!.name}");
    } else {
      Fluttertoast.showToast(msg: "Please select a room first");
    }
  }

  // All stairs selection methods:
  Stairs? selectStairs(String name) {
    for (Stairs stairs in _stairs) {
      if (stairs.name == name) {
        selectedStairs = stairs;
        deselectRoom();
        return stairs;
      }
    }
    deselectStairs();
    return null;
  }

  void deselectStairs() {
    selectedStairs = null;
  }

  // All stairs movement methods:
  void moveStairs(double newX, double newY) {
    if (selectedStairs == null) {
      Fluttertoast.showToast(msg: "Please select stairs first");
      return;
    }

    Offset newPosition = Offset(newX, newY);

    if (_stairsFitsWithinBase(
        selectedStairs!.width, selectedStairs!.length, newPosition)) {
      if (_stairsDoNotOverlap(
          selectedStairs!.width, selectedStairs!.length, newPosition)) {
        selectedStairs!.position = newPosition;
        Fluttertoast.showToast(msg: "Stairs moved successfully");
      } else {
        Fluttertoast.showToast(
            msg:
                "Cannot move stairs - would overlap with rooms or other stairs");
      }
    } else {
      Fluttertoast.showToast(msg: "Cannot move stairs outside base boundaries");
    }
  }

  void moveStairsToPosition(String position) {
    if (selectedStairs == null || _floorBase == null) {
      Fluttertoast.showToast(
          msg: "Please select a stairs and ensure base exists");
      return;
    }

    double newX, newY;

    switch (position.toLowerCase()) {
      case "center":
        newX = (_floorBase!.width - selectedStairs!.width) / 2;
        newY = (_floorBase!.height - selectedStairs!.length) / 2;
        break;
      case "topleft":
        newX = roomSpacing;
        newY = roomSpacing;
        break;
      case "topright":
        newX = _floorBase!.width - selectedStairs!.width - roomSpacing;
        newY = roomSpacing;
        break;
      case "bottomleft":
        newX = roomSpacing;
        newY = _floorBase!.height - selectedStairs!.length - roomSpacing;
        break;
      case "bottomright":
        newX = _floorBase!.width - selectedStairs!.width - roomSpacing;
        newY = _floorBase!.height - selectedStairs!.length - roomSpacing;
        break;
      default:
        Fluttertoast.showToast(msg: "Invalid position specified");
        return;
    }

    moveStairs(newX, newY);
  }

  void moveStairsRelative(double distance, String direction) {
    if (selectedStairs == null) {
      Fluttertoast.showToast(msg: "Please select a room first");
      return;
    }

    double newX = selectedStairs!.position.dx;
    double newY = selectedStairs!.position.dy;

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

    moveStairs(newX, newY);
  }

  void moveStairsRelativeToOther(int referenceStairsIndex, String direction) {
    if (selectedStairs == null) {
      Fluttertoast.showToast(msg: "Please select a stairs first");
      return;
    }

    if (referenceStairsIndex < 0 || referenceStairsIndex >= _stairs.length) {
      Fluttertoast.showToast(msg: "Invalid room reference");
      return;
    }

    Stairs referenceStairs = _stairs[referenceStairsIndex];
    double newX = selectedStairs!.position.dx;
    double newY = selectedStairs!.position.dy;

    switch (direction.toLowerCase()) {
      case "right":
      case "east":
        newX =
            referenceStairs.position.dx + referenceStairs.width + roomSpacing;
        newY = referenceStairs.position.dy;
        break;
      case "left":
      case "west":
        newX =
            referenceStairs.position.dx - selectedStairs!.width - roomSpacing;
        newY = referenceStairs.position.dy;
        break;
      case "above":
      case "north":
        newX = referenceStairs.position.dx;
        newY =
            referenceStairs.position.dy - selectedStairs!.length - roomSpacing;
        break;
      case "below":
      case "south":
        newX = referenceStairs.position.dx;
        newY =
            referenceStairs.position.dy + referenceStairs.length + roomSpacing;
        break;
      default:
        Fluttertoast.showToast(msg: "Invalid direction specified");
        return;
    }

    moveStairs(newX, newY);
  }

  void moveStairsRelativeToRoom(int referenceRoomIndex, String direction) {
    if (selectedStairs == null) {
      Fluttertoast.showToast(msg: "Please select stairs first");
      return;
    }

    if (referenceRoomIndex < 0 || referenceRoomIndex >= _rooms.length) {
      Fluttertoast.showToast(msg: "Invalid room reference");
      return;
    }

    Room referenceRoom = _rooms[referenceRoomIndex];
    double newX = selectedStairs!.position.dx;
    double newY = selectedStairs!.position.dy;

    switch (direction.toLowerCase()) {
      case "right":
      case "east":
        newX = referenceRoom.position.dx + referenceRoom.width + roomSpacing;
        newY = referenceRoom.position.dy;
        break;
      case "left":
      case "west":
        newX = referenceRoom.position.dx - selectedStairs!.width - roomSpacing;
        newY = referenceRoom.position.dy;
        break;
      case "above":
      case "north":
        newX = referenceRoom.position.dx;
        newY = referenceRoom.position.dy - selectedStairs!.length - roomSpacing;
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

    moveStairs(newX, newY);
  }

  // Stairs resizing method:
  void resizeStairs(double newWidth, double newLength) {
    if (selectedStairs == null) {
      Fluttertoast.showToast(msg: "Please select stairs first");
      return;
    }

    if (_floorBase == null) {
      Fluttertoast.showToast(msg: "No base exists");
      return;
    }

    // Check if new dimensions are valid
    if (newWidth <= 0 || newLength <= 0) {
      Fluttertoast.showToast(
          msg: "Invalid dimensions. Must be greater than 0.");
      return;
    }

    // Store current position
    Offset currentPosition = selectedStairs!.position;

    // Check if the room would still fit within the base with new dimensions
    if (!_stairsFitsWithinBase(newWidth, newLength, currentPosition)) {
      Fluttertoast.showToast(
          msg: "New size would place stairs outside base boundaries");
      return;
    }

    // Create a temporary list without the selected room to check overlap
    List<Stairs> otherStairs =
        _stairs.where((stairs) => stairs != selectedStairs).toList();

    // Check for overlaps with other rooms
    bool wouldOverlap = false;
    for (final existingStairs in otherStairs) {
      if (_checkOverlap(
          currentPosition,
          newWidth,
          newLength,
          existingStairs.position,
          existingStairs.width,
          existingStairs.length)) {
        wouldOverlap = true;
        break;
      }
    }

    if (!wouldOverlap) {
      selectedStairs!.width = newWidth;
      selectedStairs!.length = newLength;
      Fluttertoast.showToast(msg: "Stairs resized successfully");
    } else {
      Fluttertoast.showToast(
          msg:
              "Cannot resize Stairs - would overlap with other rooms or stairs");
    }
  }

  bool _checkOverlap(Offset pos1, double width1, double height1, Offset pos2,
      double width2, double height2) {
    return !(pos1.dx + width1 + roomSpacing <= pos2.dx ||
        pos1.dx >= pos2.dx + width2 + roomSpacing ||
        pos1.dy + height1 + roomSpacing <= pos2.dy ||
        pos1.dy >= pos2.dy + height2 + roomSpacing);
  }

  // Stairs rotation method:
  void rotateStairs() {
    if (selectedStairs == null) return;

    String stairsName = selectedStairs!.name;

    // Find the stairs by name
    final stairsIndex =
        _stairs.indexWhere((stairs) => stairs.name == stairsName);

    if (stairsIndex == -1) {
      Fluttertoast.showToast(msg: "Stairs not found");
      return;
    }

    Stairs currentStairs = _stairs[stairsIndex];

    // For 90-degree clockwise rotation, we simply swap width and length
    double newWidth = currentStairs.length;
    double newLength = currentStairs.width;

    // Check if the stairs with new dimensions would fit and not overlap
    if (!_canRotateStairs(currentStairs, newWidth, newLength)) {
      Fluttertoast.showToast(msg: "Cannot rotate stairs - not enough space");
      return;
    }

    const List<String> directions = ["up", "right", "down", "left"];
    int newDirectionIndex = directions.indexOf(currentStairs.direction) + 1;
    if (newDirectionIndex >= directions.length) {
      newDirectionIndex = 0;
    }

    // Create new stairs with rotated dimensions but same up/down direction
    Stairs rotatedStairs = Stairs(
      width: newWidth,
      length: newLength,
      position: currentStairs.position,
      direction: directions[newDirectionIndex],
      numberOfSteps: currentStairs.numberOfSteps,
      name: currentStairs.name,
    );

    // Replace old stairs with rotated one
    _stairs[stairsIndex] = rotatedStairs;
    selectStairs(rotatedStairs.name);

    Fluttertoast.showToast(msg: "Stairs rotated successfully");
  }

  // All stairs position helper methods:
  bool _stairsFitsWithinBase(double width, double length, Offset position) {
    if (_floorBase == null) return false;

    return position.dx >= 0 &&
        position.dx + width <= _floorBase!.width &&
        position.dy >= 0 &&
        position.dy + length <= _floorBase!.height;
  }

  bool _stairsDoNotOverlap(double width, double length, Offset position) {
    // Check overlap with rooms
    for (final room in _rooms) {
      if (_checkOverlap(
        position,
        width,
        length,
        room.position,
        room.width,
        room.height,
      )) {
        return false;
      }
    }

    // Check overlap with other stairs
    for (final stairs in _stairs) {
      if (_checkOverlap(
        position,
        width,
        length,
        stairs.position,
        stairs.width,
        stairs.length,
      )) {
        return false;
      }
    }

    return true;
  }

  Offset? _findNextStairsPosition(double stairsWidth, double stairsLength) {
    if (_floorBase == null) return null;

    // If this is the first element (no rooms and no stairs), start from top-left
    if (_rooms.isEmpty && _stairs.isEmpty) {
      Offset initialPosition = const Offset(roomSpacing, roomSpacing);
      if (_stairsFitsWithinBase(stairsWidth, stairsLength, initialPosition) &&
          _stairsDoNotOverlap(stairsWidth, stairsLength, initialPosition)) {
        return initialPosition;
      }
    }

    // Get the last placed element's position and dimensions
    Offset? lastPosition;
    double lastWidth = 0;
    double lastHeight = 0;

    // Check last placed element (either room or stairs)
    if (_rooms.isNotEmpty) {
      Room lastRoom = _rooms.last;
      lastPosition = lastRoom.position;
      lastWidth = lastRoom.width;
      lastHeight = lastRoom.height;
    }
    if (_stairs.isNotEmpty) {
      Stairs lastStairs = _stairs.last;
      lastPosition = lastStairs.position;
      lastWidth = lastStairs.width;
      lastHeight = lastStairs.length;
    }

    if (lastPosition != null) {
      // Try positions in all four directions from the last element
      List<Offset> candidatePositions = [
        // Right
        Offset(lastPosition.dx + lastWidth + roomSpacing, lastPosition.dy),
        // Left
        Offset(lastPosition.dx - stairsWidth - roomSpacing, lastPosition.dy),
        // Below
        Offset(lastPosition.dx, lastPosition.dy + lastHeight + roomSpacing),
        // Above
        Offset(lastPosition.dx, lastPosition.dy - stairsLength - roomSpacing),
      ];

      // Try each candidate position
      for (Offset position in candidatePositions) {
        if (_stairsFitsWithinBase(stairsWidth, stairsLength, position) &&
            _stairsDoNotOverlap(stairsWidth, stairsLength, position)) {
          return position;
        }
      }
    }

    // If no direct positions work, try a grid-based search
    return _findAlternativePositionForStairs(stairsWidth, stairsLength);
  }

  Offset? _findAlternativePositionForStairs(
      double stairsWidth, double stairsLength) {
    if (_floorBase == null) return null;

    // Start from the top of the base with some margin
    double currentY = roomSpacing;

    while (currentY + stairsLength <= _floorBase!.height) {
      // Try placing rooms from left to right in each row
      double currentX = roomSpacing;

      while (currentX + stairsWidth <= _floorBase!.width) {
        Offset testPosition = Offset(currentX, currentY);

        if (_stairsDoNotOverlap(stairsWidth, stairsLength, testPosition)) {
          return testPosition;
        }

        currentX += stairsWidth + roomSpacing;
      }

      currentY += stairsLength + roomSpacing;
    }

    return null;
  }

  bool _canRotateStairs(Stairs stairs, double newWidth, double newLength) {
    // Check if new dimensions would fit within base
    if (!_stairsFitsWithinBase(newWidth, newLength, stairs.position)) {
      return false;
    }

    // Create a temporary list excluding the current stairs
    final otherStairs = _stairs.where((s) => s.name != stairs.name).toList();

    // Check overlap with other stairs
    for (final other in otherStairs) {
      if (_checkOverlap(
        stairs.position,
        newWidth,
        newLength,
        other.position,
        other.width,
        other.length,
      )) {
        return false;
      }
    }

    // Check overlap with rooms
    for (final room in _rooms) {
      if (_checkOverlap(
        stairs.position,
        newWidth,
        newLength,
        room.position,
        room.width,
        room.height,
      )) {
        return false;
      }
    }

    return true;
  }

  // All zoom methods:
  void zoomIn() {
    if (_zoomLevel < _maxZoom) {
      _zoomLevel += _zoomIncrement;
      if (_zoomLevel > _maxZoom) _zoomLevel = _maxZoom;
      notifyListeners();
    }
  }

  void zoomOut() {
    if (_zoomLevel > _minZoom) {
      _zoomLevel -= _zoomIncrement;
      if (_zoomLevel < _minZoom) _zoomLevel = _minZoom;
      notifyListeners();
    }
  }

  void setZoom(double level) {
    _zoomLevel = level.clamp(_minZoom, _maxZoom);
    notifyListeners();
  }

  // Metric conversion methods:
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
