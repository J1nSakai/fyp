import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:saysketch_v2/models/door.dart';
import 'package:saysketch_v2/models/floor_base_model.dart';
import 'package:saysketch_v2/models/stairs.dart';
import 'package:saysketch_v2/services/message_service.dart';
import '../models/room_model.dart';
import '../models/window.dart';

class FloorPlanController extends ChangeNotifier {
  FloorPlanController() {
    // Don't save state immediately in constructor
    // _saveState(); // Remove this line
  }

  FloorBase? _floorBase;
  final List<Room> _rooms = [];
  int _roomCounter = 0;
  final List<Stairs> _stairs = [];
  int _stairsCounter = 0;

  Stairs? selectedStairs;
  Room? selectedRoom;
  String? selectedRoomName;
  Door? selectedDoor;

  late Color originalColor;

  static const double roomSpacing = 0.0; //  unit spacing between rooms

  double _zoomLevel = 1.0;
  static const double _zoomIncrement = 0.2;
  static const double _minZoom = 0.25;
  static const double _maxZoom = 6.0;

  Window? selectedWindow;

  // Add these properties for state management
  final List<Map<String, dynamic>> _undoStack = [];
  final List<Map<String, dynamic>> _redoStack = [];
  static const int maxUndoSteps =
      20; // Limit stack size to prevent memory issues

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
    // Save the current state before making changes
    if (_floorBase != null) {
      // _saveState()();
    }

    _floorBase = FloorBase(30.0, 20.0, const Offset(0, 0));
    // _saveState()(); // Save the new state
    notifyListeners();
  }

  void setBase(double width, double height, Offset position) {
    // Save the current state before making changes
    if (_floorBase != null) {
      // _saveState()();
    }

    _floorBase = FloorBase(width, height, position);
    // _saveState()(); // Make sure this is called
    notifyListeners();
    print("Base set: $_floorBase"); // Debug print
  }

  void removeBase() {
    _floorBase = null;
    // _saveState()();
    notifyListeners();
  }

  // Add helper method for restoring stairs
  void restoreStairs(Stairs stairs) {
    _stairs.add(stairs);
    // _saveState()();
    notifyListeners();
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
        // _saveState()();
        notifyListeners();
      } else {
        Fluttertoast.showToast(msg: "Room overlaps with existing rooms.");
      }
    } else {
      Fluttertoast.showToast(msg: "Room must be completely inside the base.");
    }
  }

  // void addDefaultRoom() {
  //   if (_floorBase == null) {
  //     Fluttertoast.showToast(msg: "Please create a base first");
  //     return;
  //   }

  //   const double defaultRoomWidth = 20;
  //   const double defaultRoomHeight = 15;

  //   // For the first room, position it in the top-left corner with some margin
  //   const defaultRoomPosition = Offset(roomSpacing, roomSpacing);

  //   addRoom(defaultRoomWidth, defaultRoomHeight, defaultRoomPosition);
  // }

  void addNextRoom() {
    const double defaultRoomWidth = 5;
    const double defaultRoomHeight = 5;
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
    // _saveState()();
    notifyListeners();
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

  // All room removal methods:
  void removeAllRooms() {
    _roomCounter = 0;
    _rooms.clear();
    // _saveState()();
    notifyListeners();
  }

  void removeLastAddedRoom() {
    if (_rooms.isNotEmpty) {
      _rooms.removeLast();
      _roomCounter--;
      // _saveState()();
      notifyListeners();
    }
  }

  void removeSelectedRoom() {
    _rooms.remove(selectedRoom);
    deselectRoom();
    // _saveState()();
    notifyListeners();
  }

  // All stairs removal methods:
  void removeSelectedStairs() {
    if (selectedStairs != null) {
      _stairs.remove(selectedStairs);
      deselectStairs();
      // _saveState()();
      notifyListeners();
    }
  }

  void removeAllStairs() {
    _stairs.clear();
    _stairsCounter = 0;
    deselectStairs();
    // _saveState()();
    notifyListeners();
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
      selectedRoom!.clearHighlight();
    }
    selectedRoom = null;
    selectedRoomName = null;
    deselectDoor();
    notifyListeners();
  }

  // Room renaming method:
  void renameRoom(String name) {
    selectedRoom!.name = name;
    // _saveState()();
    notifyListeners();
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
        // _saveState()();
        notifyListeners();
      } else {
        Fluttertoast.showToast(
            msg: "Cannot move room - would overlap with other rooms");
      }
    } else {
      Fluttertoast.showToast(msg: "Cannot move room outside base boundaries");
    }
  }

  void moveRoomToPosition(
      String position, List<String> tokens, BuildContext context) {
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
      case "top":
        if (tokens.contains("left")) {
          newX = roomSpacing;
          newY = roomSpacing;
        } else if (tokens.contains("right")) {
          newX = _floorBase!.width - selectedRoom!.width - roomSpacing;
          newY = roomSpacing;
        }
        break;
      // case "topright":
      //   break;
      case "bottom":
        if (tokens.contains("left")) {
          newX = roomSpacing;
          newY = _floorBase!.height - selectedRoom!.height - roomSpacing;
        } else if (tokens.contains("right")) {
          newX = _floorBase!.width - selectedRoom!.width - roomSpacing;
          newY = _floorBase!.height - selectedRoom!.height - roomSpacing;
        }
        break;
      // case "bottomright":
      //   break;
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
      // _saveState()();
      notifyListeners();
    } else {
      Fluttertoast.showToast(
          msg: "Cannot resize room - would overlap with other rooms");
    }
  }

  // Room walls hiding method:
  void hideWalls() {
    if (selectedRoom != null) {
      selectedRoom!.hasHiddenWalls = true;
      selectedRoom!.roomPaint = Paint()
        ..color = Colors.grey.withOpacity(0.3)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      // _saveState()();
      notifyListeners();
      Fluttertoast.showToast(msg: "Walls hidden for ${selectedRoom!.name}");
    } else {
      Fluttertoast.showToast(msg: "Please select a room first");
    }
  }

  // Room walls showing method:
  void showWalls() {
    if (selectedRoom != null) {
      selectedRoom!.hasHiddenWalls = false;
      selectedRoom!.roomPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      // _saveState()();
      notifyListeners();
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
    notifyListeners();
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
        // _saveState()();
        notifyListeners();
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

  void moveStairsToPosition(
      String position, List<String> tokens, BuildContext context) {
    if (selectedStairs == null || _floorBase == null) {
      MessageService.showMessage(
          context, "Please select a stairs and ensure base exists",
          type: MessageType.error);
      return;
    }

    double newX = selectedStairs!.position.dx;
    double newY = selectedStairs!.position.dy;

    switch (position.toLowerCase()) {
      case "center":
        newX = (_floorBase!.width - selectedStairs!.width) / 2;
        newY = (_floorBase!.height - selectedStairs!.length) / 2;
        break;
      case "top":
        if (tokens.contains("left")) {
          newX = roomSpacing;
          newY = roomSpacing;
        } else if (tokens.contains("right")) {
          newX = _floorBase!.width - selectedStairs!.width - roomSpacing;
          newY = roomSpacing;
        }
        break;
      case "bottom":
        if (tokens.contains("left")) {
          newX = roomSpacing;
          newY = _floorBase!.height - selectedStairs!.length - roomSpacing;
        } else if (tokens.contains("right")) {
          newX = _floorBase!.width - selectedStairs!.width - roomSpacing;
          newY = _floorBase!.height - selectedStairs!.length - roomSpacing;
        }
        break;
      default:
        MessageService.showMessage(context, "Invalid position specified",
            type: MessageType.error);
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
    // _saveState()();
    notifyListeners();

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
        return value; // The default unit is feet
      case "inches":
      case "inch":
      case "in":
        return value * 0.0833; // Convert inches to feet
      case "meters":
      case "meter":
      case "m":
        return value * 3.28024;
      case "centimeters":
      case "centimeter":
      case "cm":
        return value * 0.0328; // Convert centimeters to feet
      default:
        return value; // Default to assuming feet
    }
  }

  // Door management methods
  void addDoor(String roomName, String wall, double offset,
      {double width = Door.defaultWidth, bool connectToAdjacent = false}) {
    Room? room = _findRoomByName(roomName);
    if (room != selectedRoom) {
      Fluttertoast.showToast(
          msg: "Please select the room first before adding doors");
      return;
    }

    // Validate wall name
    if (!["north", "south", "east", "west", "up", "down", "left", "right"]
        .contains(wall.toLowerCase())) {
      Fluttertoast.showToast(msg: "Invalid wall specified.");
      return;
    }

    // Calculate door width based on room dimensions
    double wallLength =
        (wall == "north" || wall == "south" || wall == "up" || wall == "down")
            ? room!.width
            : room!.height;

    // Set door width to 1/3 of wall length, but not more than 4 feet
    double calculatedWidth = (wallLength / 3).clamp(2.0, 4.0);

    // Adjust offset if it would place the door too close to edges
    double maxOffset =
        wallLength - calculatedWidth - Door.minDistanceFromCorner;
    double minOffset = Door.minDistanceFromCorner;
    double adjustedOffset = offset.clamp(minOffset, maxOffset);

    // Create the door with adjusted dimensions
    Door newDoor = Door(
      id: room.getNextDoorId(),
      width: calculatedWidth, // Use calculated width instead of parameter
      offsetFromWallStart: adjustedOffset,
      wall: wall.toLowerCase(),
    );

    // Validate door placement with new dimensions
    if (!room.canAddDoor(wall, adjustedOffset, calculatedWidth)) {
      Fluttertoast.showToast(
          msg:
              "Invalid door position. Door must be at least ${Door.minDistanceFromCorner}ft from corners and ${Door.minDistanceBetweenDoors}ft from other doors.");
      return;
    }

    // Handle connecting door
    if (connectToAdjacent) {
      Door? connectedDoor = _createConnectingDoor(room, newDoor);
      if (connectedDoor != null) {
        newDoor.connectedDoor = connectedDoor;
        connectedDoor.connectedDoor = newDoor;
      }
    }

    room.doors.add(newDoor);
    // _saveState()();
    notifyListeners();

    Fluttertoast.showToast(msg: "Door added successfully to ${room.name}");
  }

  Door? _createConnectingDoor(Room sourceRoom, Door sourceDoor) {
    Room? adjacentRoom = _findAdjacentRoom(sourceRoom, sourceDoor.wall);
    if (adjacentRoom == null) {
      Fluttertoast.showToast(msg: "No adjacent room found for connecting door");
      return null;
    }

    // Calculate opposite wall and offset for connecting door
    String oppositeWall = _getOppositeWall(sourceDoor.wall);
    double adjacentOffset =
        _calculateAdjacentDoorOffset(sourceRoom, adjacentRoom, sourceDoor);

    // Validate door placement in adjacent room
    if (!adjacentRoom.canAddDoor(
        oppositeWall, adjacentOffset, sourceDoor.width)) {
      Fluttertoast.showToast(
          msg: "Cannot place connecting door in adjacent room");
      return null;
    }

    // Create connecting door
    Door connectingDoor = Door(
      id: adjacentRoom.getNextDoorId(),
      width: sourceDoor.width,
      offsetFromWallStart: adjacentOffset,
      wall: oppositeWall,
      swingInward: !sourceDoor.swingInward, // Opposite swing
      openLeft: !sourceDoor.openLeft, // Opposite opening direction
    );

    adjacentRoom.doors.add(connectingDoor);
    return connectingDoor;
  }

  Room? _findAdjacentRoom(Room sourceRoom, String wall) {
    // Calculate the edge coordinates of the source room wall
    double sourceStart, sourceEnd, crossAxis;
    bool isHorizontal =
        (wall == "north" || wall == "south" || wall == "up" || wall == "down");

    if (isHorizontal) {
      sourceStart = sourceRoom.position.dx;
      sourceEnd = sourceRoom.position.dx + sourceRoom.width;
      crossAxis = wall == "north" || wall == "up"
          ? sourceRoom.position.dy
          : sourceRoom.position.dy + sourceRoom.height;
    } else {
      sourceStart = sourceRoom.position.dy;
      sourceEnd = sourceRoom.position.dy + sourceRoom.height;
      crossAxis = wall == "west" || wall == "left"
          ? sourceRoom.position.dx
          : sourceRoom.position.dx + sourceRoom.width;
    }

    // Find room that shares this wall
    for (Room room in _rooms) {
      if (room == sourceRoom) continue;

      // Calculate potential adjacent room's corresponding wall coordinates
      double adjacentStart, adjacentEnd, adjacentCrossAxis;

      if (isHorizontal) {
        adjacentStart = room.position.dx;
        adjacentEnd = room.position.dx + room.width;
        adjacentCrossAxis = wall == "north" || wall == "up"
            ? room.position.dy + room.height
            : room.position.dy;
      } else {
        adjacentStart = room.position.dy;
        adjacentEnd = room.position.dy + room.height;
        adjacentCrossAxis = wall == "west" || wall == "left"
            ? room.position.dx + room.width
            : room.position.dx;
      }

      // Check if walls are adjacent and overlapping
      if (crossAxis == adjacentCrossAxis &&
          _doRangesOverlap(
              sourceStart, sourceEnd, adjacentStart, adjacentEnd)) {
        return room;
      }
    }
    return null;
  }

  bool _doRangesOverlap(
      double start1, double end1, double start2, double end2) {
    // Allow for small floating-point differences
    const double epsilon = 0.001;
    return (start1 <= end2 + epsilon) && (end1 >= start2 - epsilon);
  }

  String _getOppositeWall(String wall) {
    switch (wall.toLowerCase()) {
      case "north":
      case "up":
        return "south";
      case "south":
      case "down":
        return "north";
      case "east":
      case "right":
        return "west";
      case "west":
      case "left":
        return "east";
      default:
        return wall;
    }
  }

  double _calculateAdjacentDoorOffset(
      Room sourceRoom, Room adjacentRoom, Door sourceDoor) {
    bool isHorizontal = (sourceDoor.wall == "north" ||
        sourceDoor.wall == "south" ||
        sourceDoor.wall == "up" ||
        sourceDoor.wall == "down");

    if (isHorizontal) {
      double diff = adjacentRoom.position.dx - sourceRoom.position.dx;
      return sourceDoor.offsetFromWallStart - diff;
    } else {
      double diff = adjacentRoom.position.dy - sourceRoom.position.dy;
      return sourceDoor.offsetFromWallStart - diff;
    }
  }

  // Door modification methods
  void moveDoor(double newOffset) {
    if (selectedDoor == null) {
      Fluttertoast.showToast(msg: "No door selected");
      return;
    }

    // Find the room that contains the selected door
    Room? doorRoom = _findRoomByDoor(selectedDoor!);
    if (doorRoom == null) {
      Fluttertoast.showToast(msg: "Could not find room for selected door");
      return;
    }

    // Calculate wall length based on door's wall
    double wallLength = (selectedDoor!.wall == "north" ||
            selectedDoor!.wall == "south" ||
            selectedDoor!.wall == "up" ||
            selectedDoor!.wall == "down")
        ? doorRoom.width
        : doorRoom.height;

    // Adjust door width for small rooms
    double calculatedWidth = (wallLength / 3).clamp(1.5, 4.0);

    // Adjust minimum corner distance for small rooms
    double minCornerDistance =
        (wallLength < 6) ? 0.5 : Door.minDistanceFromCorner;

    // Calculate valid range for door placement
    double maxOffset = wallLength - calculatedWidth - minCornerDistance;
    double minOffset = minCornerDistance;

    if (newOffset >= minOffset && newOffset <= maxOffset) {
      selectedDoor!.offsetFromWallStart = newOffset;

      // Update connected door if exists
      if (selectedDoor!.connectedDoor != null) {
        Room? connectedRoom = _findRoomByDoor(selectedDoor!.connectedDoor!);
        if (connectedRoom != null) {
          double newConnectedOffset = _calculateAdjacentDoorOffset(
              doorRoom, connectedRoom, selectedDoor!);
          selectedDoor!.connectedDoor!.offsetFromWallStart = newConnectedOffset;
        }
      }

      // _saveState()();
      notifyListeners();
      Fluttertoast.showToast(msg: "Door moved");
    } else {
      Fluttertoast.showToast(
          msg:
              "Invalid door position. Door must be at least ${minCornerDistance}ft from corners.");
    }
  }

  // Helper method to find room by door
  Room? _findRoomByDoor(Door door) {
    return _rooms.firstWhere((room) => room.doors.contains(door),
        orElse: () => throw Exception("Room not found for door"));
  }

  Room? _findRoomByName(String name) {
    try {
      return _rooms
          .firstWhere((room) => room.name.toLowerCase() == name.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  void removeAllDoors(String roomName) {
    Room? room = _findRoomByName(roomName);
    if (room != selectedRoom) {
      Fluttertoast.showToast(
          msg: "Please select the room first before removing doors");
      return;
    }

    // Remove all connecting doors first
    for (Door door in List.from(room!.doors)) {
      if (door.connectedDoor != null) {
        Room? connectedRoom = _findRoomByDoor(door.connectedDoor!);
        if (connectedRoom != null) {
          connectedRoom.doors.remove(door.connectedDoor);
        }
      }
    }

    room.doors.clear();
    // _saveState()();
    notifyListeners();

    Fluttertoast.showToast(msg: "All doors removed from ${room.name}");
  }

  void removeDoor(String roomName, String doorId) {
    if (selectedDoor?.id != doorId) {
      Fluttertoast.showToast(msg: "Please select the door first");
      return;
    }
    Room? room = _findRoomByName(roomName);
    if (room == null) return;

    try {
      Door door = room.doors.firstWhere((d) => d.id == doorId);

      // Remove connected door first if it exists
      if (door.connectedDoor != null) {
        Room? connectedRoom = _findRoomByDoor(door.connectedDoor!);
        if (connectedRoom != null) {
          connectedRoom.doors.remove(door.connectedDoor);
        }
      }

      room.doors.remove(door);
      // _saveState()();
      notifyListeners();

      Fluttertoast.showToast(msg: "Door removed from ${room.name}");
    } catch (e) {
      Fluttertoast.showToast(msg: "Door not found");
    }
    deselectDoor();
  }

  void changeDoorSwing(String roomName, String doorId, bool swingInward) {
    if (selectedDoor?.id != doorId) {
      Fluttertoast.showToast(msg: "Please select the door first");
      return;
    }
    Room? room = _findRoomByName(roomName);
    if (room != selectedRoom) {
      Fluttertoast.showToast(
          msg: "Please select the room first before modifying doors");
      return;
    }

    try {
      Door door = room!.doors.firstWhere((d) => d.id == doorId);
      door.swingInward = swingInward;

      // Update connected door if it exists
      if (door.connectedDoor != null) {
        door.connectedDoor!.swingInward =
            !swingInward; // Opposite swing for connected door
      }

      // _saveState()();
      notifyListeners();

      Fluttertoast.showToast(msg: "Door swing direction updated");
    } catch (e) {
      Fluttertoast.showToast(msg: "Door not found");
    }
  }

  // Helper method to change door opening direction (left/right)
  void changeDoorOpeningDirection(
      String roomName, String doorId, bool openLeft) {
    if (selectedDoor?.id != doorId) {
      Fluttertoast.showToast(msg: "Please select the door first");
      return;
    }
    Room? room = _findRoomByName(roomName);
    if (room != selectedRoom) {
      Fluttertoast.showToast(
          msg: "Please select the room first before modifying doors");
      return;
    }

    try {
      Door door = room!.doors.firstWhere((d) => d.id == doorId);
      door.openLeft = openLeft;

      // Update connected door if it exists
      if (door.connectedDoor != null) {
        door.connectedDoor!.openLeft =
            !openLeft; // Opposite opening direction for connected door
      }

      // _saveState();
      notifyListeners();

      Fluttertoast.showToast(msg: "Door opening direction updated");
    } catch (e) {
      Fluttertoast.showToast(msg: "Door not found");
    }
  }

  // Add a method to highlight selected room's doors
  void highlightSelectedRoomDoors(bool highlight) {
    if (selectedRoom != null) {
      for (Door door in selectedRoom!.doors) {
        door.isHighlighted = highlight;
      }
      // _saveState();
      notifyListeners();
    }
  }

  // Add door selection methods
  void selectDoor(String roomName, String doorId) {
    Room? room = _findRoomByName(roomName);
    if (room == null) {
      Fluttertoast.showToast(msg: "Room not found");
      return;
    }

    try {
      Door door = room.doors.firstWhere((d) => d.id == doorId);
      // Clear highlight of previously selected room
      if (selectedRoom != null) {
        selectedRoom!.clearHighlight();
        selectedRoom = null;
        selectedRoomName = null;
      }
      selectedStairs = null;
      selectedWindow = null;
      selectedDoor = door; // Set the selected door
      notifyListeners();
    } catch (e) {
      Fluttertoast.showToast(msg: "Door not found");
    }
  }

  void deselectDoor() {
    if (selectedDoor != null) {
      selectedDoor = null;
      notifyListeners();
    }
  }

  // Add window management methods
  void addWindow(String roomName, String wall, double offset,
      {double width = Window.defaultWidth, bool connectToAdjacent = false}) {
    Room? room = _findRoomByName(roomName);
    if (room != selectedRoom) {
      Fluttertoast.showToast(
          msg: "Please select the room first before adding windows");
      return;
    }

    // Validate wall name
    if (!["north", "south", "east", "west", "up", "down", "left", "right"]
        .contains(wall.toLowerCase())) {
      Fluttertoast.showToast(msg: "Invalid wall specified.");
      return;
    }

    // Calculate window width based on room dimensions
    double wallLength =
        (wall == "north" || wall == "south" || wall == "up" || wall == "down")
            ? room!.width
            : room!.height;

    // Set window width to 1/3 of wall length, but not more than 4 feet
    double calculatedWidth = (wallLength / 3).clamp(2.0, 4.0);

    // Adjust offset if it would place the window too close to edges
    double maxOffset =
        wallLength - calculatedWidth - Window.minDistanceFromCorner;
    double minOffset = Window.minDistanceFromCorner;
    double adjustedOffset = offset.clamp(minOffset, maxOffset);

    // Create the window with adjusted dimensions
    Window newWindow = Window(
      id: room.getNextWindowId(),
      width: calculatedWidth,
      offsetFromWallStart: adjustedOffset,
      wall: wall.toLowerCase(),
    );

    // Validate window placement
    if (!room.canAddWindow(wall, adjustedOffset, calculatedWidth)) {
      Fluttertoast.showToast(
          msg:
              "Invalid window position. Check distance from corners, doors, and other windows.");
      return;
    }

    // Handle connecting window
    if (connectToAdjacent) {
      Window? connectedWindow = _createConnectingWindow(room, newWindow);
      if (connectedWindow != null) {
        newWindow.connectedWindow = connectedWindow;
        connectedWindow.connectedWindow = newWindow;
      }
    }

    room.windows.add(newWindow);
    // _saveState();
    notifyListeners();
    Fluttertoast.showToast(msg: "Window added successfully to ${room.name}");
  }

  Window? _createConnectingWindow(Room sourceRoom, Window sourceWindow) {
    Room? adjacentRoom =
        _findAdjacentRoomBasedOnWall(sourceRoom, sourceWindow.wall);
    if (adjacentRoom == null) {
      Fluttertoast.showToast(
          msg: "No adjacent room found for connecting window");
      return null;
    }

    String oppositeWall = _getOppositeWall(sourceWindow.wall);
    double adjacentOffset =
        _calculateAdjacentOffset(sourceRoom, adjacentRoom, sourceWindow);

    if (!adjacentRoom.canAddWindow(
        oppositeWall, adjacentOffset, sourceWindow.width)) {
      Fluttertoast.showToast(
          msg: "Cannot place connecting window in adjacent room");
      return null;
    }

    Window connectingWindow = Window(
      id: adjacentRoom.getNextWindowId(),
      width: sourceWindow.width,
      offsetFromWallStart: adjacentOffset,
      wall: oppositeWall,
    );

    adjacentRoom.windows.add(connectingWindow);
    return connectingWindow;
  }

  void selectWindow(String roomName, String windowId) {
    Room? room = _findRoomByName(roomName);
    if (room == null) {
      Fluttertoast.showToast(msg: "Room not found");
      return;
    }

    try {
      Window window = room.windows.firstWhere((w) => w.id == windowId);
      // Clear highlight of previously selected room
      if (selectedRoom != null) {
        selectedRoom!.clearHighlight();
        selectedRoom = null;
        selectedRoomName = null;
      }
      selectedStairs = null;
      selectedDoor = null;
      selectedWindow = window; // Set the selected window
      notifyListeners();
    } catch (e) {
      Fluttertoast.showToast(msg: "Window not found");
    }
  }

  void deselectWindow() {
    selectedWindow = null;
    notifyListeners();
  }

  void removeWindow(String roomName, String windowId) {
    if (selectedWindow?.id != windowId) {
      Fluttertoast.showToast(msg: "Please select the window first");
      return;
    }

    Room? room = _findRoomByName(roomName);
    if (room != selectedRoom) {
      Fluttertoast.showToast(
          msg: "Please select the room first before removing windows");
      return;
    }

    try {
      Window window = room!.windows.firstWhere((w) => w.id == windowId);

      // Remove connected window first if it exists
      if (window.connectedWindow != null) {
        Room? connectedRoom = _findRoomByWindow(window.connectedWindow!);
        if (connectedRoom != null) {
          connectedRoom.windows.remove(window.connectedWindow!);
        }
      }

      // Remove the selected window
      room.windows.remove(window);
      deselectWindow();
      // _saveState();
      notifyListeners();
      Fluttertoast.showToast(msg: "Window removed from ${room.name}");
    } catch (e) {
      Fluttertoast.showToast(msg: "Window not found");
    }
  }

  void moveWindow(double newOffset) {
    if (selectedWindow == null) {
      Fluttertoast.showToast(msg: "No window selected");
      return;
    }

    // Find the room that contains the selected window
    Room? windowRoom = _findRoomByWindow(selectedWindow!);
    if (windowRoom == null) {
      Fluttertoast.showToast(msg: "Could not find room for selected window");
      return;
    }

    // Calculate wall length based on window's wall
    double wallLength = (selectedWindow!.wall == "north" ||
            selectedWindow!.wall == "south" ||
            selectedWindow!.wall == "up" ||
            selectedWindow!.wall == "down")
        ? windowRoom.width
        : windowRoom.height;

    // Adjust window width for small rooms
    double calculatedWidth = (wallLength / 3).clamp(1.5, 4.0);

    // Adjust minimum corner distance for small rooms
    double minCornerDistance =
        (wallLength < 6) ? 0.5 : Window.minDistanceFromCorner;

    // Calculate valid range for window placement
    double maxOffset = wallLength - calculatedWidth - minCornerDistance;
    double minOffset = minCornerDistance;

    if (newOffset >= minOffset && newOffset <= maxOffset) {
      selectedWindow!.offsetFromWallStart = newOffset;

      // Update connected window if exists
      if (selectedWindow!.connectedWindow != null) {
        Room? connectedRoom =
            _findRoomByWindow(selectedWindow!.connectedWindow!);
        if (connectedRoom != null) {
          double newConnectedOffset = _calculateAdjacentOffset(
              windowRoom, connectedRoom, selectedWindow!);
          selectedWindow!.connectedWindow!.offsetFromWallStart =
              newConnectedOffset;
        }
      }

      // _saveState();
      notifyListeners();
      Fluttertoast.showToast(msg: "Window moved");
    } else {
      Fluttertoast.showToast(
          msg:
              "Invalid window position. Window must be at least ${minCornerDistance}ft from corners.");
    }
  }

  // Helper method to find room by window (if not already defined)
  Room? _findRoomByWindow(Window window) {
    return _rooms.firstWhere((room) => room.windows.contains(window),
        orElse: () => throw Exception("Room not found for window"));
  }

  double _calculateAdjacentOffset(
      Room sourceRoom, Room adjacentRoom, Window sourceWindow) {
    // Get the dimensions of both rooms
    double sourceWallLength = (sourceWindow.wall == "north" ||
            sourceWindow.wall == "south" ||
            sourceWindow.wall == "up" ||
            sourceWindow.wall == "down")
        ? sourceRoom.width
        : sourceRoom.height;

    double adjacentWallLength = (sourceWindow.wall == "north" ||
            sourceWindow.wall == "south" ||
            sourceWindow.wall == "up" ||
            sourceWindow.wall == "down")
        ? adjacentRoom.width
        : adjacentRoom.height;

    // Calculate the relative position as a percentage of the wall length
    double relativePosition =
        sourceWindow.offsetFromWallStart / sourceWallLength;

    // Apply the same relative position to the adjacent wall
    return relativePosition * adjacentWallLength;
  }

  // This is a helper method to find adjacent room based on wall
  Room? _findAdjacentRoomBasedOnWall(Room sourceRoom, String wall) {
    double tolerance = 0.1; // Small tolerance for floating-point comparisons

    for (Room room in _rooms) {
      if (room == sourceRoom) continue;

      switch (wall.toLowerCase()) {
        case "north":
        case "up":
          if ((sourceRoom.position.dy - tolerance) <=
                  (room.position.dy + room.height) &&
              (sourceRoom.position.dy + tolerance) >=
                  (room.position.dy + room.height) &&
              _wallsOverlap(sourceRoom.position.dx, sourceRoom.width,
                  room.position.dx, room.width)) {
            return room;
          }
          break;

        case "south":
        case "down":
          if ((sourceRoom.position.dy + sourceRoom.height - tolerance) <=
                  room.position.dy &&
              (sourceRoom.position.dy + sourceRoom.height + tolerance) >=
                  room.position.dy &&
              _wallsOverlap(sourceRoom.position.dx, sourceRoom.width,
                  room.position.dx, room.width)) {
            return room;
          }
          break;

        case "east":
        case "right":
          if ((sourceRoom.position.dx + sourceRoom.width - tolerance) <=
                  room.position.dx &&
              (sourceRoom.position.dx + sourceRoom.width + tolerance) >=
                  room.position.dx &&
              _wallsOverlap(sourceRoom.position.dy, sourceRoom.height,
                  room.position.dy, room.height)) {
            return room;
          }
          break;

        case "west":
        case "left":
          if ((sourceRoom.position.dx - tolerance) <=
                  (room.position.dx + room.width) &&
              (sourceRoom.position.dx + tolerance) >=
                  (room.position.dx + room.width) &&
              _wallsOverlap(sourceRoom.position.dy, sourceRoom.height,
                  room.position.dy, room.height)) {
            return room;
          }
          break;
      }
    }
    return null;
  }

  // Helper method to check if walls overlap
  bool _wallsOverlap(double pos1, double length1, double pos2, double length2) {
    double tolerance = 0.1;
    return (pos1 + tolerance < pos2 + length2) &&
        (pos1 + length1 - tolerance > pos2);
  }

  // Add a method to deselect all entities
  void deselectAll() {
    if (selectedRoom != null) {
      selectedRoom!.clearHighlight();
    }
    selectedRoom = null;
    selectedRoomName = null;
    selectedDoor = null;
    selectedWindow = null;
    selectedStairs = null;
    notifyListeners();
  }

  void removeSelectedDoor() {
    if (selectedDoor == null) {
      Fluttertoast.showToast(msg: "No door selected");
      return;
    }

    // Find the room that contains the selected door
    Room? doorRoom = _findRoomByDoor(selectedDoor!);
    if (doorRoom == null) {
      Fluttertoast.showToast(msg: "Could not find room for selected door");
      return;
    }

    // Remove connected door first if it exists
    if (selectedDoor!.connectedDoor != null) {
      Room? connectedRoom = _findRoomByDoor(selectedDoor!.connectedDoor!);
      if (connectedRoom != null) {
        connectedRoom.doors.remove(selectedDoor!.connectedDoor!);
      }
    }

    // Remove the selected door
    doorRoom.doors.remove(selectedDoor!);
    selectedDoor = null;
    notifyListeners();
    Fluttertoast.showToast(msg: "Door removed");
  }

  void removeSelectedWindow() {
    if (selectedWindow == null) {
      Fluttertoast.showToast(msg: "No window selected");
      return;
    }

    // Find the room that contains the selected window
    Room? windowRoom = _findRoomByWindow(selectedWindow!);
    if (windowRoom == null) {
      Fluttertoast.showToast(msg: "Could not find room for selected window");
      return;
    }

    // Remove connected window first if it exists
    if (selectedWindow!.connectedWindow != null) {
      Room? connectedRoom = _findRoomByWindow(selectedWindow!.connectedWindow!);
      if (connectedRoom != null) {
        connectedRoom.windows.remove(selectedWindow!.connectedWindow!);
      }
    }

    // Remove the selected window
    windowRoom.windows.remove(selectedWindow!);
    selectedWindow = null;
    notifyListeners();
    Fluttertoast.showToast(msg: "Window removed");
  }

  // void undo() {
  //   if (_undoStack.isEmpty) {
  //     Fluttertoast.showToast(msg: "Nothing to undo");
  //     return;
  //   }

  //   // Save current state to redo stack
  //   final currentState = {
  //     'rooms': _rooms.map((room) => room.toJson()).toList(),
  //     'base': _floorBase?.toJson(),
  //     'stairs': _stairs.map((stairs) => stairs.toJson()).toList(),
  //     'roomCounter': _roomCounter,
  //     'stairsCounter': _stairsCounter,
  //   };
  //   _redoStack.add(currentState);

  //   // Pop and restore previous state
  //   final previousState = _undoStack.removeLast();
  //   _restoreState(previousState);

  //   Fluttertoast.showToast(msg: "Undo successful");
  // }

  // void redo() {
  //   if (_redoStack.isEmpty) {
  //     Fluttertoast.showToast(msg: "Nothing to redo");
  //     return;
  //   }

  //   // Save current state to undo stack
  //   final currentState = {
  //     'rooms': _rooms.map((room) => room.toJson()).toList(),
  //     'base': _floorBase?.toJson(),
  //     'stairs': _stairs.map((stairs) => stairs.toJson()).toList(),
  //     'roomCounter': _roomCounter,
  //     'stairsCounter': _stairsCounter,
  //   };
  //   _undoStack.add(currentState);

  //   // Pop and restore next state
  //   final nextState = _redoStack.removeLast();
  //   _restoreState(nextState);

  //   Fluttertoast.showToast(msg: "Redo successful");
  // }

  // // Helper method to save current state
  // void _saveState() {
  //   // Clear redo stack when a new action is performed
  //   _redoStack.clear();

  //   final currentState = {
  //     'rooms': _rooms.map((room) => room.toJson()).toList(),
  //     'base': _floorBase?.toJson(),
  //     'stairs': _stairs.map((stairs) => stairs.toJson()).toList(),
  //     'roomCounter': _roomCounter,
  //     'stairsCounter': _stairsCounter,
  //   };

  //   _undoStack.add(currentState);

  //   // Limit undo stack size
  //   if (_undoStack.length > maxUndoSteps) {
  //     _undoStack.removeAt(0);
  //   }
  // }

  // // Helper method to restore state
  // void _restoreState(Map<String, dynamic> state) {
  //   // Clear existing state
  //   _rooms.clear();
  //   _stairs.clear();
  //   _floorBase = null;

  //   // Restore base
  //   if (state['base'] != null) {
  //     _floorBase = FloorBase.fromJson(state['base']);
  //   }

  //   // First pass: Create all rooms and their elements
  //   final Map<String, Door> allDoors = {};
  //   final Map<String, Window> allWindows = {};

  //   if (state['rooms'] != null) {
  //     for (var roomJson in state['rooms']) {
  //       final room = Room.fromJson(roomJson);
  //       // Store all doors and windows for connection restoration
  //       for (var door in room.doors) {
  //         allDoors[door.id] = door;
  //       }
  //       for (var window in room.windows) {
  //         allWindows[window.id] = window;
  //       }
  //       _rooms.add(room);
  //     }
  //   }

  //   // Second pass: Restore connections
  //   for (var room in _rooms) {
  //     for (var door in room.doors) {
  //       door.restoreConnectedDoor(allDoors);
  //     }
  //     for (var window in room.windows) {
  //       window.restoreConnectedWindow(allWindows);
  //     }
  //   }

  //   // Restore stairs
  //   if (state['stairs'] != null) {
  //     for (var stairsJson in state['stairs']) {
  //       _stairs.add(Stairs.fromJson(stairsJson));
  //     }
  //   }

  //   // Restore counters
  //   _roomCounter = state['roomCounter'] ?? 0;
  //   _stairsCounter = state['stairsCounter'] ?? 0;

  //   notifyListeners();
  // }

  // void restoreRoom(Room room, List<Door> doors, List<Window> windows) {
  //   // Create a deep copy of the room to avoid reference issues
  //   Room restoredRoom = Room(
  //     room.width,
  //     room.height,
  //     room.position,
  //     room.name,
  //   );

  //   // Restore doors and windows
  //   restoredRoom.doors.addAll(doors);
  //   restoredRoom.windows.addAll(windows);

  //   // Restore other properties
  //   restoredRoom.hasHiddenWalls = room.hasHiddenWalls;
  //   restoredRoom.roomPaint = Paint()
  //     ..color = room.roomPaint.color
  //     ..strokeWidth = room.roomPaint.strokeWidth
  //     ..style = room.roomPaint.style;

  //   _rooms.add(restoredRoom);
  //   notifyListeners();
  // }

  // // Add this method to help with debugging
  // void printState() {
  //   print("Current State:");
  //   print("Base: $_floorBase");
  //   print("Rooms: ${_rooms.length}");
  //   print("Stairs: ${_stairs.length}");
  //   print("Undo Stack Size: ${_undoStack.length}");
  //   print("Redo Stack Size: ${_redoStack.length}");
  // }

  Map<String, dynamic> toJson() {
    return {
      'rooms': _rooms.map((room) => room.toJson()).toList(),
      'base': _floorBase?.toJson(),
      'stairs': _stairs.map((stairs) => stairs.toJson()).toList(),
      'roomCounter': _roomCounter,
      'stairsCounter': _stairsCounter,
    };
  }

  factory FloorPlanController.fromJson(Map<String, dynamic> json) {
    final controller = FloorPlanController();

    // Clear existing state
    controller._rooms.clear();
    controller._stairs.clear();
    controller._floorBase = null;

    // Restore base
    if (json['base'] != null) {
      controller._floorBase = FloorBase.fromJson(json['base']);
    }

    // First pass: Create all rooms and their elements
    final Map<String, Door> allDoors = {};
    final Map<String, Window> allWindows = {};

    if (json['rooms'] != null) {
      for (var roomJson in json['rooms']) {
        final room = Room.fromJson(roomJson);
        // Store all doors and windows for connection restoration
        for (var door in room.doors) {
          allDoors[door.id] = door;
        }
        for (var window in room.windows) {
          allWindows[window.id] = window;
        }
        controller._rooms.add(room);
      }
    }

    // Second pass: Restore connections
    for (var room in controller._rooms) {
      for (var door in room.doors) {
        if (door.connectedDoor?.id != null) {
          door.restoreConnectedDoor(allDoors);
        }
      }
      for (var window in room.windows) {
        if (window.connectedWindow?.id != null) {
          window.restoreConnectedWindow(allWindows);
        }
      }
    }

    // Restore stairs
    if (json['stairs'] != null) {
      for (var stairsJson in json['stairs']) {
        controller._stairs.add(Stairs.fromJson(stairsJson));
      }
    }

    // Restore counters
    controller._roomCounter = json['roomCounter'] ?? 0;
    controller._stairsCounter = json['stairsCounter'] ?? 0;

    return controller;
  }
}
