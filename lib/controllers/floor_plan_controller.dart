import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:saysketch_v2/models/door.dart';
import 'package:saysketch_v2/models/floor_base_model.dart';
import 'package:saysketch_v2/models/stairs.dart';
import 'package:saysketch_v2/services/message_service.dart';
import '../models/room_model.dart';
import '../models/window.dart';
import '../models/cut_out.dart';
import '../models/space.dart';

class FloorPlanController extends ChangeNotifier {
  FloorPlanController() {
    // Don't save state immediately in constructor
    // _saveState(); // Remove this line
  }

  FloorBase? _floorBase;
  final List<Room> _rooms = [];
  int _roomCounter = 0;
  List<Stairs> _stairs = [];
  int _stairsCounter = 0;
  final List<CutOut> _cutOuts = [];
  int _cutOutCounter = 0; // Counter for cutouts

  Stairs? selectedStairs;
  Room? selectedRoom;
  String? selectedRoomName;
  Door? selectedDoor;
  CutOut? selectedCutOut;
  String? selectedCutOutName;
  Space? selectedSpace;

  late Color originalColor;

  static const double roomSpacing = 0.0; //  unit spacing between rooms

  double _zoomLevel = 1.0;
  static const double _zoomIncrement = 0.2;
  static const double _minZoom = 0.1;
  static const double _maxZoom = 10.0;

  Window? selectedWindow;

  // Add these properties for state management
  // final List<Map<String, dynamic>> _undoStack = [];
  // // final List<Map<String, dynamic>> _redoStack = [];
  // static const int maxUndoSteps =
  //     20; // Limit stack size to prevent memory issues

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

  List<CutOut> getCutOuts() => _cutOuts;

  // All base building methods:
  void setDefaultBase() {
    // Save the current state before making changes
    if (_floorBase != null) {
      // _saveState();
    }

    _floorBase = FloorBase(30.0, 20.0, const Offset(0, 0));
    // _saveState(); // Save the new state
    notifyListeners();
  }

  void setBase(double width, double height, Offset position) {
    // Save the current state before making changes
    if (_floorBase != null) {
      // _saveState();
    }

    _floorBase = FloorBase(width, height, position);
    // _saveState(); // Make sure this is called
    notifyListeners();
    print("Base set: $_floorBase"); // Debug print
  }

  void removeBase() {
    _floorBase = null;
    // _saveState();
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
      if (_roomDoesNotOverlapWithExistingElements(width, height, position)) {
        _roomCounter++;
        _rooms.add(Room(width, height, position, "room $_roomCounter"));
        notifyListeners();
      } else {
        Fluttertoast.showToast(msg: "Room overlaps with existing elements.");
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

    if (_rooms.isEmpty && _stairs.isEmpty && _cutOuts.isEmpty) {
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
        _roomDoesNotOverlapWithExistingElements(width, height, newPosition)) {
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

    // If this is the first element, start from top-left
    if (_rooms.isEmpty && _stairs.isEmpty && _cutOuts.isEmpty) {
      Offset initialPosition = const Offset(roomSpacing, roomSpacing);
      if (_roomFitsWithinBase(roomWidth, roomHeight, initialPosition) &&
          _roomDoesNotOverlapWithExistingElements(
              roomWidth, roomHeight, initialPosition)) {
        return initialPosition;
      }
    }

    // Get the last placed element's position and dimensions
    Offset? lastPosition;
    double lastWidth = 0;
    double lastHeight = 0;

    // Find the most recently added element among rooms, stairs, and cutouts
    if (_rooms.isNotEmpty || _stairs.isNotEmpty || _cutOuts.isNotEmpty) {
      // Get timestamps or indices for comparison
      int lastRoomIndex = _rooms.isEmpty ? -1 : _roomCounter;
      int lastStairsIndex = _stairs.isEmpty ? -1 : _stairsCounter;
      int lastCutOutIndex = _cutOuts.isEmpty ? -1 : _cutOutCounter;

      // Find the most recent element
      if (lastRoomIndex >= lastStairsIndex &&
          lastRoomIndex >= lastCutOutIndex) {
        // Last element was a room
        Room lastRoom = _rooms.last;
        lastPosition = lastRoom.position;
        lastWidth = lastRoom.width;
        lastHeight = lastRoom.height;
      } else if (lastStairsIndex >= lastCutOutIndex) {
        // Last element was stairs
        Stairs lastStairs = _stairs.last;
        lastPosition = lastStairs.position;
        lastWidth = lastStairs.width;
        lastHeight = lastStairs.length;
      } else {
        // Last element was a cutout
        CutOut lastCutOut = _cutOuts.last;
        lastPosition = lastCutOut.position;
        lastWidth = lastCutOut.width;
        lastHeight = lastCutOut.height;
      }
    }

    if (lastPosition != null) {
      // Try positions in all four directions from the last element
      List<Offset> candidatePositions = [
        // Right
        Offset(lastPosition.dx + lastWidth + roomSpacing, lastPosition.dy),
        // Below
        Offset(lastPosition.dx, lastPosition.dy + lastHeight + roomSpacing),
        // Left
        Offset(lastPosition.dx - roomWidth - roomSpacing, lastPosition.dy),
        // Above
        Offset(lastPosition.dx, lastPosition.dy - roomHeight - roomSpacing),
      ];

      // Try each candidate position
      for (Offset position in candidatePositions) {
        if (_roomFitsWithinBase(roomWidth, roomHeight, position) &&
            _roomDoesNotOverlapWithExistingElements(
                roomWidth, roomHeight, position)) {
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

        if (_roomDoesNotOverlapWithExistingElements(
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

  bool _roomDoesNotOverlapWithExistingElements(
      double width, double height, Offset position) {
    // Check overlap with existing rooms
    for (Room existingRoom in _rooms) {
      if (_checkOverlap(
        position,
        width,
        height,
        existingRoom.position,
        existingRoom.width,
        existingRoom.height,
      )) {
        return false;
      }
    }

    // Check overlap with cutouts
    for (CutOut cutOut in _cutOuts) {
      if (_checkOverlap(
        position,
        width,
        height,
        cutOut.position,
        cutOut.width,
        cutOut.height,
      )) {
        return false;
      }
    }

    // Check overlap with stairs
    for (Stairs stair in _stairs) {
      if (_checkOverlap(
        position,
        width,
        height,
        stair.position,
        stair.width,
        stair.length,
      )) {
        return false;
      }
    }

    return true;
  }

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
    // _saveState();
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

    // Find next available position using the common method
    Offset? nextPosition = _findNextAvailablePosition(width, length);

    if (nextPosition != null) {
      _stairsCounter++;
      _stairs.add(Stairs(
        width: width,
        length: length,
        position: nextPosition,
        direction: direction,
        numberOfSteps: numberOfSteps,
        name: "stairs $_stairsCounter",
      ));
      notifyListeners();
      Fluttertoast.showToast(msg: "Stairs added successfully");
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
      // _saveState();
      notifyListeners();
    }
  }

  void removeSelectedRoom() {
    _rooms.remove(selectedRoom);
    deselectRoom();
    // _saveState();
    notifyListeners();
  }

  void removeSelectedCutOut() {
    _cutOuts.remove(selectedCutOut);
    deselectCutOut();
    // _saveState();
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
        deselectDoor();
        deselectWindow();
        deselectSpace();
        deselectCutOut();
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
    deselectWindow();
    deselectSpace();
    notifyListeners();
  }

  // Room renaming method:
  void renameRoom(String oldName, String newName) {
    final roomIndex = _rooms.indexWhere((room) => room.name == oldName);
    if (roomIndex == -1) {
      Fluttertoast.showToast(msg: "Room not found");
      return;
    }

    Room room = _rooms[roomIndex];

    // Update room name
    room.name = newName;

    // Update door IDs
    for (var door in room.doors) {
      door.updateRoomName(oldName, newName);
    }

    // Update window IDs
    for (var window in room.windows) {
      window.updateRoomName(oldName, newName);
    }

    // Update space IDs
    for (var space in room.spaces) {
      space.updateRoomName(oldName, newName);
    }

    // Update selected room name if it was the renamed room
    if (selectedRoomName == oldName) {
      selectedRoomName = newName;
    }

    notifyListeners();
  }

  // All room movement methods:
  void moveRoom(double newX, double newY) {
    if (selectedRoom == null) {
      Fluttertoast.showToast(msg: "Please select a room first");
      return;
    }

    Offset newPosition = Offset(newX, newY);

    // Check if the new position would keep the room within base bounds
    if (_elementFitsWithinBase(
        selectedRoom!.width, selectedRoom!.height, newPosition)) {
      // Check for overlaps with all elements (excluding the selected room)
      if (!_hasOverlapWithExistingElements(
          selectedRoom!.width, selectedRoom!.height, newPosition,
          excludeElement: selectedRoom)) {
        selectedRoom!.position = newPosition;
        notifyListeners();
      } else {
        Fluttertoast.showToast(
            msg: "Cannot move room - would overlap with other elements");
      }
    } else {
      Fluttertoast.showToast(msg: "Room must be completely inside the base");
    }
  }

  void moveCutout(double newX, double newY) {
    if (selectedCutOut == null) {
      Fluttertoast.showToast(msg: "Please select a cutout first");
      return;
    }

    Offset newPosition = Offset(newX, newY);

    // Check if the new position would keep the room within base bounds
    if (_elementFitsWithinBase(
        selectedCutOut!.width, selectedCutOut!.height, newPosition)) {
      // Check for overlaps with all elements (excluding the selected room)
      if (!_hasOverlapWithExistingElements(
          selectedCutOut!.width, selectedCutOut!.height, newPosition,
          excludeElement: selectedCutOut)) {
        selectedCutOut!.position = newPosition;
        notifyListeners();
      } else {
        Fluttertoast.showToast(
            msg: "Cannot move cutout - would overlap with other elements");
      }
    } else {
      Fluttertoast.showToast(msg: "Cutout must be completely inside the base");
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

  void moveCutoutToPosition(
      String position, List<String> tokens, BuildContext context) {
    if (selectedCutOut == null || _floorBase == null) {
      Fluttertoast.showToast(
          msg: "Please select a cutout and ensure base exists");
      return;
    }

    double newX = selectedCutOut!.position.dx;
    double newY = selectedCutOut!.position.dy;

    switch (position.toLowerCase()) {
      case "center":
        newX = (_floorBase!.width - selectedCutOut!.width) / 2;
        newY = (_floorBase!.height - selectedCutOut!.height) / 2;
        break;
      case "top":
        if (tokens.contains("left")) {
          newX = roomSpacing;
          newY = roomSpacing;
        } else if (tokens.contains("right")) {
          newX = _floorBase!.width - selectedCutOut!.width - roomSpacing;
          newY = roomSpacing;
        }
        break;
      // case "topright":
      //   break;
      case "bottom":
        if (tokens.contains("left")) {
          newX = roomSpacing;
          newY = _floorBase!.height - selectedCutOut!.height - roomSpacing;
        } else if (tokens.contains("right")) {
          newX = _floorBase!.width - selectedCutOut!.width - roomSpacing;
          newY = _floorBase!.height - selectedCutOut!.height - roomSpacing;
        }
        break;
      // case "bottomright":
      //   break;
      case "right":
        // Find the rightmost point of all cutouts except the selected one
        double rightmostPoint = 0;
        for (CutOut cutout in _cutOuts) {
          if (cutout != selectedCutOut) {
            double cutoutRightEdge = cutout.position.dx + cutout.width;
            if (cutoutRightEdge > rightmostPoint) {
              rightmostPoint = cutoutRightEdge;
            }
          }
        }
        newX = rightmostPoint;
        break;
      case "left":
        // Find the leftmost point of all cutouts except the selected one
        double leftmostPoint = double.infinity;
        for (CutOut cutout in _cutOuts) {
          if (cutout != selectedCutOut) {
            if (cutout.position.dx < leftmostPoint) {
              leftmostPoint = cutout.position.dx;
            }
          }
        }
        newX = leftmostPoint - selectedCutOut!.width;
        break;
      case "up":
        // Find the topmost point of all cutouts except the selected one
        double topmostPoint = double.infinity;
        for (CutOut cutout in _cutOuts) {
          if (cutout != selectedCutOut) {
            if (cutout.position.dy < topmostPoint) {
              topmostPoint = cutout.position.dy;
            }
          }
        }
        newY = topmostPoint - selectedCutOut!.height;
        break;
      case "down":
        // Find the bottommost point of all cutouts except the selected one
        double bottommostPoint = 0;
        for (CutOut cutout in _cutOuts) {
          if (cutout != selectedCutOut) {
            double cutoutBottomEdge = cutout.position.dy + cutout.height;
            if (cutoutBottomEdge > bottommostPoint) {
              bottommostPoint = cutoutBottomEdge;
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

    moveCutout(newX, newY);
    MessageService.showMessage(
        context, "Moved ${selectedCutOut!.name} to $position",
        type: MessageType.success);
  }

  void moveRoomRelative(double distance, String direction) {
    if (selectedRoom == null) {
      Fluttertoast.showToast(msg: "Please select a room first");
      return;
    }

    Offset currentPosition = selectedRoom!.position;
    Offset newPosition;

    switch (direction.toLowerCase()) {
      case "right":
      case "east":
        newPosition = Offset(currentPosition.dx + distance, currentPosition.dy);
        break;
      case "left":
      case "west":
        newPosition = Offset(currentPosition.dx - distance, currentPosition.dy);
        break;
      case "up":
      case "north":
        newPosition = Offset(currentPosition.dx, currentPosition.dy - distance);
        break;
      case "down":
      case "south":
        newPosition = Offset(currentPosition.dx, currentPosition.dy + distance);
        break;
      default:
        Fluttertoast.showToast(msg: "Invalid direction");
        return;
    }

    // Check if the new position is valid
    if (_elementFitsWithinBase(
        selectedRoom!.width, selectedRoom!.height, newPosition)) {
      if (!_hasOverlapWithExistingElements(
          selectedRoom!.width, selectedRoom!.height, newPosition,
          excludeElement: selectedRoom)) {
        selectedRoom!.position = newPosition;
        notifyListeners();
      } else {
        Fluttertoast.showToast(
            msg: "Cannot move room - would overlap with other elements");
      }
    } else {
      Fluttertoast.showToast(msg: "Room must be completely inside the base");
    }
  }

  void moveCutoutRelative(double distance, String direction) {
    print("moveCutoutRelative");
    if (selectedCutOut == null) {
      Fluttertoast.showToast(msg: "Please select a cutout first");
      return;
    }

    Offset currentPosition = selectedCutOut!.position;
    Offset newPosition;

    switch (direction.toLowerCase()) {
      case "right":
      case "east":
        newPosition = Offset(currentPosition.dx + distance, currentPosition.dy);
        break;
      case "left":
      case "west":
        newPosition = Offset(currentPosition.dx - distance, currentPosition.dy);
        break;
      case "up":
      case "north":
        newPosition = Offset(currentPosition.dx, currentPosition.dy - distance);
        break;
      case "down":
      case "south":
        newPosition = Offset(currentPosition.dx, currentPosition.dy + distance);
        break;
      default:
        Fluttertoast.showToast(msg: "Invalid direction");
        return;
    }
    moveCutout(newPosition.dx, newPosition.dy);
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

  void moveRoomRelativeToCutout(int referenceCutoutIndex, String direction) {
    if (selectedRoom == null) {
      Fluttertoast.showToast(msg: "Please select a room first");
      return;
    }

    if (referenceCutoutIndex < 0 || referenceCutoutIndex >= _cutOuts.length) {
      Fluttertoast.showToast(msg: "Invalid cutout reference");
      return;
    }

    CutOut referenceCutout = _cutOuts[referenceCutoutIndex];
    double newX = selectedRoom!.position.dx;
    double newY = selectedRoom!.position.dy;

    switch (direction.toLowerCase()) {
      case "right":
      case "east":
        newX =
            referenceCutout.position.dx + referenceCutout.width + roomSpacing;
        newY = referenceCutout.position.dy;
        break;
      case "left":
      case "west":
        newX = referenceCutout.position.dx - selectedRoom!.width - roomSpacing;
        newY = referenceCutout.position.dy;
        break;
      case "above":
      case "north":
        newX = referenceCutout.position.dx;
        newY = referenceCutout.position.dy - selectedRoom!.height - roomSpacing;
        break;
      case "below":
      case "south":
        newX = referenceCutout.position.dx;
        newY =
            referenceCutout.position.dy + referenceCutout.height + roomSpacing;
        break;
      default:
        Fluttertoast.showToast(msg: "Invalid direction specified");
        return;
    }

    moveRoom(newX, newY);
  }

  void moveCutoutRelativeToRoom(int referenceRoomIndex, String direction) {
    if (selectedCutOut == null) {
      Fluttertoast.showToast(msg: "Please select a cutout first");
      return;
    }

    if (referenceRoomIndex < 0 || referenceRoomIndex >= _rooms.length) {
      Fluttertoast.showToast(msg: "Invalid room reference");
      return;
    }

    Room referenceRoom = _rooms[referenceRoomIndex];
    double newX = selectedCutOut!.position.dx;
    double newY = selectedCutOut!.position.dy;

    switch (direction.toLowerCase()) {
      case "right":
      case "east":
        newX = referenceRoom.position.dx + referenceRoom.width + roomSpacing;
        newY = referenceRoom.position.dy;
        break;
      case "left":
      case "west":
        newX = referenceRoom.position.dx - selectedCutOut!.width - roomSpacing;
        newY = referenceRoom.position.dy;
        break;
      case "above":
      case "north":
        newX = referenceRoom.position.dx;
        newY = referenceRoom.position.dy - selectedCutOut!.height - roomSpacing;
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

    moveCutout(newX, newY);
  }

  void moveCutoutRelativeToOther(int referenceCutoutIndex, String direction) {
    if (selectedCutOut == null) {
      Fluttertoast.showToast(msg: "Please select a cutout first");
      return;
    }

    if (referenceCutoutIndex < 0 || referenceCutoutIndex >= _cutOuts.length) {
      Fluttertoast.showToast(msg: "Invalid cutout reference");
      return;
    }

    CutOut referenceCutout = _cutOuts[referenceCutoutIndex];
    double newX = selectedCutOut!.position.dx;
    double newY = selectedCutOut!.position.dy;

    switch (direction.toLowerCase()) {
      case "right":
      case "east":
        newX =
            referenceCutout.position.dx + referenceCutout.width + roomSpacing;
        newY = referenceCutout.position.dy;
        break;
      case "left":
      case "west":
        newX =
            referenceCutout.position.dx - selectedCutOut!.width - roomSpacing;
        newY = referenceCutout.position.dy;
        break;
      case "above":
      case "north":
        newX = referenceCutout.position.dx;
        newY =
            referenceCutout.position.dy - selectedCutOut!.height - roomSpacing;
        break;
      case "below":
      case "south":
        newX = referenceCutout.position.dx;
        newY =
            referenceCutout.position.dy + referenceCutout.height + roomSpacing;
        break;
      default:
        Fluttertoast.showToast(msg: "Invalid direction specified");
        return;
    }

    moveCutout(newX, newY);
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

  void moveCutoutRelativeToStairs(int referenceStairsIndex, String direction) {
    if (selectedCutOut == null) {
      Fluttertoast.showToast(msg: "Please select a cutout first");
      return;
    }

    if (referenceStairsIndex < 0 || referenceStairsIndex >= _stairs.length) {
      Fluttertoast.showToast(msg: "Invalid stairs reference");
      return;
    }

    Stairs referenceStairs = _stairs[referenceStairsIndex];
    double newX = selectedCutOut!.position.dx;
    double newY = selectedCutOut!.position.dy;

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
            referenceStairs.position.dx - selectedCutOut!.width - roomSpacing;
        newY = referenceStairs.position.dy;
        break;
      case "above":
      case "north":
        newX = referenceStairs.position.dx;
        newY =
            referenceStairs.position.dy - selectedCutOut!.height - roomSpacing;
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

    moveCutout(newX, newY);
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
        msg: "Invalid dimensions. Must be greater than 0.",
      );
      return;
    }

    // Store current position
    Offset currentPosition = selectedRoom!.position;

    // Check if the room would still fit within the base with new dimensions
    if (!_roomFitsWithinBase(newWidth, newHeight, currentPosition)) {
      Fluttertoast.showToast(
        msg: "New size would place room outside base boundaries",
      );
      return;
    }

    // Check for overlaps with other rooms
    bool wouldOverlap = false;

    // Check other rooms
    for (final existingRoom in _rooms) {
      if (existingRoom != selectedRoom &&
          _checkOverlap(currentPosition, newWidth, newHeight,
              existingRoom.position, existingRoom.width, existingRoom.height)) {
        wouldOverlap = true;
        break;
      }
    }

    // Check cutouts
    if (!wouldOverlap) {
      for (final cutOut in _cutOuts) {
        if (_checkOverlap(currentPosition, newWidth, newHeight, cutOut.position,
            cutOut.width, cutOut.height)) {
          wouldOverlap = true;
          break;
        }
      }
    }

    // Check stairs
    if (!wouldOverlap) {
      for (final stair in _stairs) {
        if (_checkOverlap(currentPosition, newWidth, newHeight, stair.position,
            stair.width, stair.length)) {
          wouldOverlap = true;
          break;
        }
      }
    }

    if (!wouldOverlap) {
      // Check if any connected doors would be invalid with new dimensions
      bool doorPositionsValid = true;
      for (Door door in selectedRoom!.doors) {
        double wallLength =
            door.wall == "north" || door.wall == "south" ? newWidth : newHeight;

        if (door.offsetFromWallStart + door.width >
                wallLength - Door.minDistanceFromCorner ||
            door.offsetFromWallStart < Door.minDistanceFromCorner) {
          doorPositionsValid = false;
          break;
        }
      }

      if (!doorPositionsValid) {
        Fluttertoast.showToast(
            msg: "Cannot resize room - would invalidate door positions");
        return;
      }

      selectedRoom!.width = newWidth;
      selectedRoom!.height = newHeight;
      Fluttertoast.showToast(msg: "Room resized successfully");
      notifyListeners();
    } else {
      Fluttertoast.showToast(
          msg: "Cannot resize room - would overlap with other elements");
    }
  }

  void resizeCutout(double newWidth, double newHeight) {
    if (selectedCutOut == null) {
      Fluttertoast.showToast(msg: "Please select a cutout first");
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
    Offset currentPosition = selectedCutOut!.position;

    // Check if the cutout would still fit within the base with new dimensions
    if (!_roomFitsWithinBase(newWidth, newHeight, currentPosition)) {
      Fluttertoast.showToast(
          msg: "New size would place cutout outside base boundaries");
      return;
    }

    // Check for overlaps with all elements
    bool wouldOverlap = false;

    // Check other cutouts
    for (final existingCutOut in _cutOuts) {
      if (existingCutOut != selectedCutOut &&
          _checkOverlap(
              currentPosition,
              newWidth,
              newHeight,
              existingCutOut.position,
              existingCutOut.width,
              existingCutOut.height)) {
        wouldOverlap = true;
        break;
      }
    }

    // Check rooms
    if (!wouldOverlap) {
      for (final room in _rooms) {
        if (_checkOverlap(currentPosition, newWidth, newHeight, room.position,
            room.width, room.height)) {
          wouldOverlap = true;
          break;
        }
      }
    }

    // Check stairs
    if (!wouldOverlap) {
      for (final stair in _stairs) {
        if (_checkOverlap(currentPosition, newWidth, newHeight, stair.position,
            stair.width, stair.length)) {
          wouldOverlap = true;
          break;
        }
      }
    }

    if (!wouldOverlap) {
      // Check if any connected doors would be invalid with new dimensions
      bool doorPositionsValid = true;
      for (Door door in selectedCutOut!.doors) {
        double wallLength =
            door.wall == "north" || door.wall == "south" ? newWidth : newHeight;

        if (door.offsetFromWallStart + door.width >
                wallLength - Door.minDistanceFromCorner ||
            door.offsetFromWallStart < Door.minDistanceFromCorner) {
          doorPositionsValid = false;
          break;
        }
      }

      if (!doorPositionsValid) {
        Fluttertoast.showToast(
            msg: "Cannot resize cutout - would invalidate door positions");
        return;
      }

      // Check if any windows would be invalid with new dimensions
      bool windowPositionsValid = true;
      for (Window window in selectedCutOut!.windows) {
        double wallLength = window.wall == "north" || window.wall == "south"
            ? newWidth
            : newHeight;

        if (window.offsetFromWallStart + window.width >
                wallLength - Window.minDistanceFromCorner ||
            window.offsetFromWallStart < Window.minDistanceFromCorner) {
          windowPositionsValid = false;
          break;
        }
      }

      if (!windowPositionsValid) {
        Fluttertoast.showToast(
            msg: "Cannot resize cutout - would invalidate window positions");
        return;
      }

      selectedCutOut!.width = newWidth;
      selectedCutOut!.height = newHeight;
      Fluttertoast.showToast(msg: "Cutout resized successfully");
      notifyListeners();
    } else {
      Fluttertoast.showToast(
          msg: "Cannot resize cutout - would overlap with other elements");
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
        deselectStairs();
        selectedStairs = stairs;
        deselectRoom();
        deselectCutOut();
        deselectDoor();
        deselectWindow();
        deselectSpace();
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

    // Check if the new position would keep the stairs within base bounds
    if (_elementFitsWithinBase(
        selectedStairs!.width, selectedStairs!.length, newPosition)) {
      // Check for overlaps with all elements
      if (!_hasOverlapWithExistingElements(
          selectedStairs!.width, selectedStairs!.length, newPosition)) {
        selectedStairs!.position = newPosition;
        notifyListeners();
      } else {
        Fluttertoast.showToast(
            msg: "Cannot move stairs - would overlap with other elements");
      }
    } else {
      Fluttertoast.showToast(msg: "Stairs must be completely inside the base");
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

  void moveStairsRelativeToCutout(int referenceCutoutIndex, String direction) {
    if (selectedStairs == null) {
      Fluttertoast.showToast(msg: "Please select stairs first");
      return;
    }

    if (referenceCutoutIndex < 0 || referenceCutoutIndex >= _cutOuts.length) {
      Fluttertoast.showToast(msg: "Invalid cutout reference");
      return;
    }

    CutOut referenceCutout = _cutOuts[referenceCutoutIndex];
    double newX = selectedStairs!.position.dx;
    double newY = selectedStairs!.position.dy;

    switch (direction.toLowerCase()) {
      case "right":
      case "east":
        newX =
            referenceCutout.position.dx + referenceCutout.width + roomSpacing;
        newY = referenceCutout.position.dy;
        break;
      case "left":
      case "west":
        newX =
            referenceCutout.position.dx - selectedStairs!.width - roomSpacing;
        newY = referenceCutout.position.dy;
        break;
      case "above":
      case "north":
        newX = referenceCutout.position.dx;
        newY =
            referenceCutout.position.dy - selectedStairs!.length - roomSpacing;
        break;
      case "below":
      case "south":
        newX = referenceCutout.position.dx;
        newY =
            referenceCutout.position.dy + referenceCutout.height + roomSpacing;
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

    // Only check absolute minimum dimensions
    if (newWidth < Stairs.minWidth) {
      Fluttertoast.showToast(
          msg: "Minimum stair width is ${Stairs.minWidth}ft");
      return;
    }

    if (newLength < Stairs.minLength) {
      Fluttertoast.showToast(
          msg: "Minimum stair length is ${Stairs.minLength}ft");
      return;
    }

    // Store current position
    Offset currentPosition = selectedStairs!.position;

    // Check if the stairs would still fit within the base
    if (!_stairsFitsWithinBase(newWidth, newLength, currentPosition)) {
      Fluttertoast.showToast(
          msg: "New size would place stairs outside base boundaries");
      return;
    }

    bool wouldOverlap = false;

    // Check overlaps with other elements
    for (final existingStairs in _stairs) {
      if (existingStairs != selectedStairs &&
          _checkOverlap(
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

    // Check rooms
    if (!wouldOverlap) {
      for (final room in _rooms) {
        if (_checkOverlap(currentPosition, newWidth, newLength, room.position,
            room.width, room.height)) {
          wouldOverlap = true;
          break;
        }
      }
    }

    // Check cutouts
    if (!wouldOverlap) {
      for (final cutOut in _cutOuts) {
        if (_checkOverlap(currentPosition, newWidth, newLength, cutOut.position,
            cutOut.width, cutOut.height)) {
          wouldOverlap = true;
          break;
        }
      }
    }

    if (!wouldOverlap) {
      selectedStairs!.width = newWidth;
      selectedStairs!.length = newLength;
      selectedStairs!.updateStepCalculations();
      notifyListeners();
      Fluttertoast.showToast(msg: "Stairs resized successfully");
    } else {
      Fluttertoast.showToast(
          msg: "Cannot resize stairs - would overlap with other elements");
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
    // _saveState();
    notifyListeners();

    Fluttertoast.showToast(msg: "Stairs rotated successfully");
  }

  void rotateStairsCounterclockwise() {
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

    // For 90-degree rotation, we still swap width and length
    double newWidth = currentStairs.length;
    double newLength = currentStairs.width;

    // Check if the stairs with new dimensions would fit and not overlap
    if (!_canRotateStairs(currentStairs, newWidth, newLength)) {
      Fluttertoast.showToast(msg: "Cannot rotate stairs - not enough space");
      return;
    }

    const List<String> directions = ["up", "right", "down", "left"];
    // The main difference is here: we subtract 1 instead of adding 1
    int newDirectionIndex = directions.indexOf(currentStairs.direction) - 1;
    if (newDirectionIndex < 0) {
      newDirectionIndex = directions.length - 1;
    }

    // Create new stairs with rotated dimensions
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
    // _saveState();
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
    if (!_elementFitsWithinBase(newWidth, newLength, stairs.position)) {
      return false;
    }

    // Check for overlaps with existing elements (excluding the current stairs)
    Offset position = stairs.position;
    List<Stairs> otherStairs = _stairs.where((s) => s != stairs).toList();

    // Create a temporary state without the current stairs
    List<Stairs> originalStairs = List.from(_stairs);
    _stairs = otherStairs;

    bool hasOverlap = _hasOverlapWithExistingElements(
      newWidth,
      newLength,
      position,
    );

    // Restore original stairs list
    _stairs = originalStairs;

    return !hasOverlap;
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
    // _saveState();
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
    double adjacentOffset = _calculateAdjacentDoorOffsetForRoom(
        sourceRoom, adjacentRoom, sourceDoor);

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

  double _calculateAdjacentDoorOffsetForRoom(
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

  double _calculateAdjacentDoorOffsetForCutOut(
      CutOut sourceCutOut, CutOut adjacentCutOut, Door sourceDoor) {
    bool isHorizontal = (sourceDoor.wall == "north" ||
        sourceDoor.wall == "south" ||
        sourceDoor.wall == "up" ||
        sourceDoor.wall == "down");

    if (isHorizontal) {
      double diff = adjacentCutOut.position.dx - sourceCutOut.position.dx;
      return sourceDoor.offsetFromWallStart - diff;
    } else {
      double diff = adjacentCutOut.position.dy - sourceCutOut.position.dy;
      return sourceDoor.offsetFromWallStart - diff;
    }
  }

  // Door modification methods
  void moveDoor(double newOffset) {
    if (selectedDoor == null) {
      Fluttertoast.showToast(msg: "No door selected");
      return;
    }

    // Find the parent of the selected door
    Room? doorRoom = _findRoomByDoor(selectedDoor!);
    CutOut? cutoutRoom = _findCutOutByDoor(selectedDoor!);

    if (doorRoom != null) {
      // Calculate wall length based on door's wall
      double wallLength = (selectedDoor!.wall == "north" ||
              selectedDoor!.wall == "south" ||
              selectedDoor!.wall == "up" ||
              selectedDoor!.wall == "down")
          ? doorRoom.width
          : doorRoom.height;

      // Use the actual door width instead of calculating a new one
      double doorWidth = selectedDoor!.width;

      // Adjust minimum corner distance for small rooms
      double minCornerDistance =
          (wallLength < 6) ? 0.5 : Door.minDistanceFromCorner;

      // Calculate valid range for door placement
      double minOffset = minCornerDistance;
      double maxOffset = wallLength - doorWidth - minCornerDistance;

      if (newOffset >= minOffset && newOffset <= maxOffset) {
        // Check if the new position would overlap with other elements
        if (doorRoom.canResizeDoor(selectedDoor!.wall, newOffset, doorWidth,
            excludeDoor: selectedDoor)) {
          selectedDoor!.offsetFromWallStart = newOffset;

          // Update connected door if exists
          if (selectedDoor!.connectedDoor != null) {
            Room? connectedRoom = _findRoomByDoor(selectedDoor!.connectedDoor!);
            if (connectedRoom != null) {
              double newConnectedOffset = _calculateAdjacentDoorOffsetForRoom(
                  doorRoom, connectedRoom, selectedDoor!);
              selectedDoor!.connectedDoor!.offsetFromWallStart =
                  newConnectedOffset;
            }
          }

          notifyListeners();
          Fluttertoast.showToast(msg: "Door moved");
        } else {
          Fluttertoast.showToast(
              msg: "Cannot move door: would overlap with other elements");
        }
      } else {
        Fluttertoast.showToast(
            msg:
                "Invalid door position. Must be between ${minOffset.toStringAsFixed(1)}ft and ${maxOffset.toStringAsFixed(1)}ft");
      }
    } else if (cutoutRoom != null) {
      // Calculate wall length based on door's wall
      double wallLength = (selectedDoor!.wall == "north" ||
              selectedDoor!.wall == "south" ||
              selectedDoor!.wall == "up" ||
              selectedDoor!.wall == "down")
          ? cutoutRoom.width
          : cutoutRoom.height;

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
          CutOut? connectedCutout =
              _findCutOutByDoor(selectedDoor!.connectedDoor!);
          if (connectedCutout != null) {
            double newConnectedOffset = _calculateAdjacentDoorOffsetForCutOut(
                cutoutRoom, connectedCutout, selectedDoor!);
            selectedDoor!.connectedDoor!.offsetFromWallStart =
                newConnectedOffset;
          }
        }

        // _saveState();
        notifyListeners();
        Fluttertoast.showToast(msg: "Door moved");
      } else {
        Fluttertoast.showToast(
            msg:
                "Invalid door position. Door must be at least ${minCornerDistance}ft from corners.");
      }
    } else {
      Fluttertoast.showToast(
          msg: "Could not find room or cutout for selected door");
      return;
    }
  }

  // Helper method to find room by door
  Room? _findRoomByDoor(Door door) {
    try {
      return _rooms.firstWhere((room) => room.doors.contains(door));
    } catch (e) {
      return null;
    }
  }

  CutOut? _findCutOutByDoor(Door door) {
    try {
      return _cutOuts.firstWhere((cutout) => cutout.doors.contains(door));
    } catch (e) {
      return null;
    }
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
    // _saveState();
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
      // _saveState();
      notifyListeners();

      Fluttertoast.showToast(msg: "Door removed from ${room.name}");
    } catch (e) {
      Fluttertoast.showToast(msg: "Door not found");
    }
    deselectDoor();
  }

  void changeDoorSwing(bool swingInward) {
// commands:
// door opens left
// door opens right

    if (selectedDoor == null) {
      Fluttertoast.showToast(msg: "No door selected");
      return;
    }

    selectedDoor!.swingInward = swingInward;

    // If this door is connected to another door, update its swing direction too
    if (selectedDoor!.connectedDoor != null) {
      selectedDoor!.connectedDoor!.swingInward =
          !swingInward; // Opposite direction for connected door
    }

    notifyListeners();
    Fluttertoast.showToast(msg: "Door swing direction changed");
  }

  // Helper method to change door opening direction (left/right)
  void changeDoorOpeningDirection(bool openLeft) {
    // commands:
    // swing door in
    // swing door out
    // door swing inward
    // door swing outward
    if (selectedDoor == null) {
      Fluttertoast.showToast(msg: "No door selected");
      return;
    }

    selectedDoor!.openLeft = openLeft;

    // If this door is connected to another door, update its opening direction too
    if (selectedDoor!.connectedDoor != null) {
      selectedDoor!.connectedDoor!.openLeft =
          !openLeft; // Opposite direction for connected door
    }

    notifyListeners();
    Fluttertoast.showToast(msg: "Door opening direction changed");
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
  void selectDoor(String parentName, String doorId) {
    // First try to find the door in rooms
    Room? room = _findRoomByName(parentName);
    if (room != null) {
      try {
        // Change: Use doorId instead of trying to find by name
        Door door = room.doors.firstWhere((d) => d.id == doorId);
        _selectDoorAndDeselect(door);
        return;
      } catch (e) {
        // Door not found in room, continue to check cutouts
      }
    }

    // Then try to find the door in cutouts
    try {
      CutOut cutOut = _cutOuts.firstWhere(
        (c) => c.name == parentName,
      );

      Door door = cutOut.doors.firstWhere((d) => d.id == doorId);
      _selectDoorAndDeselect(door);
    } catch (e) {
      Fluttertoast.showToast(msg: "Door not found");
    }
  }

  // Helper method to handle deselection and selection
  void _selectDoorAndDeselect(Door door) {
    // Clear highlight of previously selected room
    if (selectedRoom != null) {
      selectedRoom!.clearHighlight();
      selectedRoom = null;
      selectedRoomName = null;
    }
    if (selectedCutOut != null) {
      selectedCutOut!.clearHighlight();
      selectedCutOut = null;
      selectedCutOutName = null;
    }
    selectedStairs = null;
    selectedWindow = null;
    selectedDoor = door;
    notifyListeners();
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
        _calculateAdjacentOffsetForRoom(sourceRoom, adjacentRoom, sourceWindow);

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

  void selectWindow(String parentName, String windowId) {
    // First try to find the window in rooms
    Room? room = _findRoomByName(parentName);
    if (room != null) {
      try {
        Window window = room.windows.firstWhere((w) => w.id == windowId);
        _selectWindowAndDeselect(window);
        return;
      } catch (e) {
        // Window not found in room, continue to check cutouts
      }
    }

    // Then try to find the window in cutouts
    try {
      CutOut cutOut = _cutOuts.firstWhere(
        (c) => c.name == parentName,
      );

      Window window = cutOut.windows.firstWhere((w) => w.id == windowId);
      _selectWindowAndDeselect(window);
    } catch (e) {
      Fluttertoast.showToast(msg: "Window not found");
    }
  }

  void _selectWindowAndDeselect(Window window) {
    // Clear highlight of previously selected room
    if (selectedRoom != null) {
      selectedRoom!.clearHighlight();
      selectedRoom = null;
      selectedRoomName = null;
    }
    if (selectedCutOut != null) {
      selectedCutOut!.clearHighlight();
      selectedCutOut = null;
      selectedCutOutName = null;
    }
    selectedStairs = null;
    selectedDoor = null;
    selectedWindow = window;
    notifyListeners();
  }

  // void _selectDoorAndDeselect(Door door) {
  //   // Clear highlight of previously selected room
  //   if (selectedRoom != null) {
  //     selectedRoom!.clearHighlight();
  //     selectedRoom = null;
  //     selectedRoomName = null;
  //   }
  //   if (selectedCutOut != null) {
  //     selectedCutOut!.clearHighlight();
  //     selectedCutOut = null;
  //     selectedCutOutName = null;
  //   }
  //   selectedStairs = null;
  //   selectedWindow = null;
  //   selectedDoor = door;
  //   notifyListeners();
  // }

  CutOut? _findCutOutByWindow(Window window) {
    try {
      return _cutOuts.firstWhere(
        (cutOut) => cutOut.windows.contains(window),
      );
    } catch (e) {
      return null;
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
    CutOut? windowCutOut = _findCutOutByWindow(selectedWindow!);
    if (windowRoom != null) {
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
            double newConnectedOffset = _calculateAdjacentOffsetForRoom(
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
    } else if (windowCutOut != null) {
      // Calculate wall length based on window's wall
      double wallLength = (selectedWindow!.wall == "north" ||
              selectedWindow!.wall == "south" ||
              selectedWindow!.wall == "up" ||
              selectedWindow!.wall == "down")
          ? windowCutOut.width
          : windowCutOut.height;

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
          CutOut? connectedCutOut =
              _findCutOutByWindow(selectedWindow!.connectedWindow!);
          if (connectedCutOut != null) {
            double newConnectedOffset = _calculateAdjacentOffsetForCutOut(
                windowCutOut, connectedCutOut, selectedWindow!);
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
    } else {
      Fluttertoast.showToast(msg: "Could not find room for selected window");
      return;
    }
  }

  // Helper method to find room by window (if not already defined)
  Room? _findRoomByWindow(Window window) {
    try {
      return _rooms.firstWhere((room) => room.windows.contains(window));
    } catch (e) {
      return null;
    }
  }

  double _calculateAdjacentOffsetForRoom(
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

  double _calculateAdjacentOffsetForCutOut(
      CutOut sourceCutOut, CutOut adjacentCutOut, Window sourceWindow) {
    // Get the dimensions of both rooms
    double sourceWallLength = (sourceWindow.wall == "north" ||
            sourceWindow.wall == "south" ||
            sourceWindow.wall == "up" ||
            sourceWindow.wall == "down")
        ? sourceCutOut.width
        : sourceCutOut.height;

    double adjacentWallLength = (sourceWindow.wall == "north" ||
            sourceWindow.wall == "south" ||
            sourceWindow.wall == "up" ||
            sourceWindow.wall == "down")
        ? adjacentCutOut.width
        : adjacentCutOut.height;

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
    if (selectedCutOut != null) {
      selectedCutOut!.clearHighlight();
    }
    deselectRoom();
    deselectCutOut();
    deselectDoor();
    deselectWindow();
    deselectSpace();
    deselectStairs();
    notifyListeners();
  }

  void removeSelectedDoor() {
    if (selectedDoor == null) {
      Fluttertoast.showToast(msg: "No door selected");
      return;
    }

    // Try to find the door in rooms first
    Room? doorRoom = _findRoomByDoor(selectedDoor!);
    if (doorRoom != null) {
      doorRoom.doors.remove(selectedDoor!);
      selectedDoor = null;
      notifyListeners();
      Fluttertoast.showToast(msg: "Door removed from room");
      return;
    }

    // If not in rooms, try cutouts
    CutOut? doorCutOut = _findCutOutByDoor(selectedDoor!);
    if (doorCutOut != null) {
      doorCutOut.doors.remove(selectedDoor!);
      selectedDoor = null;
      notifyListeners();
      Fluttertoast.showToast(msg: "Door removed from cutout");
      return;
    }

    Fluttertoast.showToast(msg: "Could not find parent for selected door");
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
    Fluttertoast.showToast(msg: "Window removed from ${windowRoom.name}");
  }

  void removeSelectedSpace() {
    if (selectedSpace == null) {
      Fluttertoast.showToast(msg: "No space selected");
      return;
    }

    // Try to find the space in rooms first
    Room? spaceRoom = _findRoomBySpace(selectedSpace!);
    if (spaceRoom != null) {
      spaceRoom.spaces.remove(selectedSpace!);
      selectedSpace = null;
      notifyListeners();
      Fluttertoast.showToast(msg: "Space removed from room");
      return;
    }

    // If not in rooms, try cutouts
    CutOut? spaceCutOut = _findCutOutBySpace(selectedSpace!);
    if (spaceCutOut != null) {
      spaceCutOut.spaces.remove(selectedSpace!);
      selectedSpace = null;
      notifyListeners();
      Fluttertoast.showToast(msg: "Space removed from cutout");
      return;
    }

    Fluttertoast.showToast(msg: "Could not find parent for selected space");
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
      'cutOuts': _cutOuts.map((cutOut) => cutOut.toJson()).toList(),
      'base': _floorBase?.toJson(),
      'stairs': _stairs.map((stairs) => stairs.toJson()).toList(),
      'roomCounter': _roomCounter,
      'cutOutCounter': _cutOutCounter,
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

    // Restore cutouts
    if (json['cutOuts'] != null) {
      for (var cutOutJson in json['cutOuts']) {
        controller._cutOuts.add(CutOut.fromJson(cutOutJson));
      }
    }

    controller._cutOutCounter = json['cutOutCounter'] ?? 0;

    return controller;
  }

  // Add CutOut management methods
  void addCutOut(double width, double height) {
    if (_floorBase == null) {
      Fluttertoast.showToast(msg: "Base is not set yet.");
      return;
    }

    // Find next available position for the cutout
    Offset? nextPosition = _findNextAvailablePosition(width, height);

    if (nextPosition != null) {
      _cutOutCounter++;
      _cutOuts
          .add(CutOut(width, height, nextPosition, "cutout $_cutOutCounter"));
      notifyListeners();
    } else {
      Fluttertoast.showToast(msg: "No available space for cutout within base.");
    }
  }

  Offset? _findNextAvailablePosition(double width, double height) {
    if (_floorBase == null) return null;

    // If this is the first element, start from top-left
    if (_rooms.isEmpty && _stairs.isEmpty && _cutOuts.isEmpty) {
      Offset initialPosition = const Offset(roomSpacing, roomSpacing);
      if (_elementFitsWithinBase(width, height, initialPosition) &&
          !_hasOverlapWithExistingElements(width, height, initialPosition)) {
        return initialPosition;
      }
    }

    // Get the last placed element's position and dimensions
    Offset? lastPosition;
    double lastWidth = 0;
    double lastHeight = 0;

    // Find the most recently added element among rooms, stairs, and cutouts
    if (_rooms.isNotEmpty || _stairs.isNotEmpty || _cutOuts.isNotEmpty) {
      // Get timestamps or indices for comparison
      int lastRoomIndex = _rooms.isEmpty ? -1 : _roomCounter;
      int lastStairsIndex = _stairs.isEmpty ? -1 : _stairsCounter;
      int lastCutOutIndex = _cutOuts.isEmpty ? -1 : _cutOutCounter;

      // Find the most recent element
      if (lastRoomIndex >= lastStairsIndex &&
          lastRoomIndex >= lastCutOutIndex) {
        Room lastRoom = _rooms.last;
        lastPosition = lastRoom.position;
        lastWidth = lastRoom.width;
        lastHeight = lastRoom.height;
      } else if (lastStairsIndex >= lastCutOutIndex) {
        Stairs lastStairs = _stairs.last;
        lastPosition = lastStairs.position;
        lastWidth = lastStairs.width;
        lastHeight = lastStairs.length;
      } else {
        CutOut lastCutOut = _cutOuts.last;
        lastPosition = lastCutOut.position;
        lastWidth = lastCutOut.width;
        lastHeight = lastCutOut.height;
      }
    }

    if (lastPosition != null) {
      // Try positions in all four directions from the last element
      List<Offset> candidatePositions = [
        // Right
        Offset(lastPosition.dx + lastWidth + roomSpacing, lastPosition.dy),
        // Below
        Offset(lastPosition.dx, lastPosition.dy + lastHeight + roomSpacing),
        // Left
        Offset(lastPosition.dx - width - roomSpacing, lastPosition.dy),
        // Above
        Offset(lastPosition.dx, lastPosition.dy - height - roomSpacing),
      ];

      // Try each candidate position
      for (Offset position in candidatePositions) {
        if (_elementFitsWithinBase(width, height, position) &&
            !_hasOverlapWithExistingElements(width, height, position)) {
          return position;
        }
      }
    }

    // If no direct positions work, try a grid-based search
    return _findAlternativePosition(width, height);
  }

  bool _elementFitsWithinBase(double width, double height, Offset position) {
    if (_floorBase == null) return false;
    return position.dx >= 0 &&
        position.dy >= 0 &&
        position.dx + width <= _floorBase!.width &&
        position.dy + height <= _floorBase!.height;
  }

  bool _hasOverlapWithExistingElements(
    double width,
    double height,
    Offset position, {
    Object? excludeElement,
  }) {
    // Check overlap with rooms
    for (Room room in _rooms) {
      if (room != excludeElement &&
          _checkOverlap(position, width, height, room.position, room.width,
              room.height)) {
        return true;
      }
    }

    // Check overlap with stairs
    for (Stairs stairs in _stairs) {
      if (stairs != excludeElement &&
          _checkOverlap(position, width, height, stairs.position, stairs.width,
              stairs.length)) {
        return true;
      }
    }

    // Check overlap with cutouts
    for (CutOut cutOut in _cutOuts) {
      if (cutOut != excludeElement &&
          _checkOverlap(position, width, height, cutOut.position, cutOut.width,
              cutOut.height)) {
        return true;
      }
    }

    return false;
  }

  Offset? _findAlternativePosition(double width, double height) {
    if (_floorBase == null) return null;
    double x = roomSpacing;
    double y = roomSpacing;

    while (y + height <= _floorBase!.height) {
      while (x + width <= _floorBase!.width) {
        Offset position = Offset(x, y);
        if (!_hasOverlapWithExistingElements(width, height, position)) {
          return position;
        }
        x += roomSpacing + 1;
      }
      x = roomSpacing;
      y += roomSpacing + 1;
    }
    return null;
  }

  // CutOut selection methods
  void selectCutOut(String cutOutName) {
    deselectAll();

    // Remove "cutout" prefix if it exists in the name parameter
    String searchName =
        cutOutName.startsWith("cutout ") ? cutOutName : "cutout $cutOutName";

    try {
      selectedCutOut =
          _cutOuts.firstWhere((cutOut) => cutOut.name == searchName);
      selectedCutOutName = searchName;
      // Update the paint color to show selection
      selectedCutOut!.cutOutPaint.color = Colors.red.withOpacity(0.6);
      notifyListeners();
    } catch (e) {
      Fluttertoast.showToast(msg: "CutOut not found");
    }
  }

  void deselectCutOut() {
    if (selectedCutOut != null) {
      selectedCutOut!.clearHighlight();
      selectedCutOut = null;
      selectedCutOutName = null;
      notifyListeners();
    }
  }

  // Helper methods
  CutOut? _findCutOutByName(String name) {
    try {
      return _cutOuts.firstWhere((cutOut) => cutOut.name == name);
    } catch (e) {
      return null;
    }
  }

  // Space management methods
  void addSpace(String cutOutName, String wall, double offset,
      {bool connectToAdjacent = false}) {
    CutOut? targetCutOut = _findCutOutByName(cutOutName);
    if (targetCutOut == null) {
      Fluttertoast.showToast(msg: "CutOut not found");
      return;
    }

    if (!targetCutOut.canAddSpace(wall, offset, Space.defaultWidth)) {
      Fluttertoast.showToast(
          msg: "Cannot add space at this position. Check minimum distances.");
      return;
    }

    String spaceId = targetCutOut.getNextSpaceId();
    Space newSpace = Space(
      id: spaceId,
      offsetFromWallStart: offset,
      wall: wall,
    );

    if (connectToAdjacent) {
      _connectSpaceToAdjacent(targetCutOut, newSpace);
    }

    targetCutOut.spaces.add(newSpace);
    notifyListeners();
  }

  void removeSpace(String cutOutName, String spaceId) {
    if (selectedSpace?.id != spaceId) {
      Fluttertoast.showToast(msg: "Please select the space first");
      return;
    }

    CutOut? targetCutOut = _findCutOutByName(cutOutName);
    if (targetCutOut == null) return;

    try {
      Space? spaceToRemove = targetCutOut.spaces.firstWhere(
        (space) => space.id == spaceId,
      );

      // Remove connection if it exists
      if (spaceToRemove.connectedSpace != null) {
        spaceToRemove.connectedSpace!.connectedSpace = null;
      }
      targetCutOut.spaces.remove(spaceToRemove);
      if (selectedSpace == spaceToRemove) {
        selectedSpace = null;
      }
      notifyListeners();
      Fluttertoast.showToast(msg: "Space removed from ${targetCutOut.name}");
    } catch (e) {
      Fluttertoast.showToast(msg: "Space not found");
    }
  }

  void _connectSpaceToAdjacent(dynamic parent, Space newSpace) {
    double tolerance = 0.5; // Half a foot tolerance for alignment
    Offset spacePosition = _calculateSpacePosition(parent, newSpace);

    // First check rooms for potential connections
    for (Room room in _rooms) {
      // Skip if this is the parent room
      if (parent is Room && room == parent) continue;

      if (_canConnectToRoom(room, spacePosition, newSpace.wall, tolerance)) {
        String roomSpaceId = room.getNextSpaceId();
        Space roomSpace = Space(
          id: roomSpaceId,
          offsetFromWallStart: _calculateOffsetForConnectingSpace(
              room, spacePosition, newSpace.wall),
          wall: _getOppositeWall(newSpace.wall),
        );

        newSpace.connectedSpace = roomSpace;
        roomSpace.connectedSpace = newSpace;
        room.spaces.add(roomSpace);
        return;
      }
    }

    // Then check cutouts
    for (CutOut cutOut in _cutOuts) {
      // Skip if this is the parent cutout
      if (parent is CutOut && cutOut == parent) continue;

      if (_canConnectToCutOut(
          cutOut, spacePosition, newSpace.wall, tolerance)) {
        String cutOutSpaceId = cutOut.getNextSpaceId();
        Space cutOutSpace = Space(
          id: cutOutSpaceId,
          offsetFromWallStart: _calculateOffsetForConnectingSpace(
              cutOut, spacePosition, newSpace.wall),
          wall: _getOppositeWall(newSpace.wall),
        );

        newSpace.connectedSpace = cutOutSpace;
        cutOutSpace.connectedSpace = newSpace;
        cutOut.spaces.add(cutOutSpace);
        return;
      }
    }
  }

  Offset _calculateSpacePosition(dynamic parent, Space space) {
    double parentX = parent.position.dx;
    double parentY = parent.position.dy;
    double parentWidth = parent.width;
    double parentHeight = parent.height;

    switch (space.wall) {
      case "north":
      case "up":
        return Offset(
          parentX + space.offsetFromWallStart,
          parentY,
        );
      case "south":
      case "down":
        return Offset(
          parentX + space.offsetFromWallStart,
          parentY + parentHeight,
        );
      case "east":
      case "right":
        return Offset(
          parentX + parentWidth,
          parentY + space.offsetFromWallStart,
        );
      case "west":
      case "left":
        return Offset(
          parentX,
          parentY + space.offsetFromWallStart,
        );
      default:
        return Offset(parentX, parentY);
    }
  }

  bool _canConnectToRoom(
      Room room, Offset spacePosition, String spaceWall, double tolerance) {
    switch (spaceWall) {
      case "north":
      case "up":
        return _isWithinTolerance(
                spacePosition.dy, room.position.dy + room.height, tolerance) &&
            _isWithinHorizontalBounds(
                spacePosition.dx, room.position.dx, room.width);
      case "south":
      case "down":
        return _isWithinTolerance(
                spacePosition.dy, room.position.dy, tolerance) &&
            _isWithinHorizontalBounds(
                spacePosition.dx, room.position.dx, room.width);
      case "east":
      case "right":
        return _isWithinTolerance(
                spacePosition.dx, room.position.dx, tolerance) &&
            _isWithinVerticalBounds(
                spacePosition.dy, room.position.dy, room.height);
      case "west":
      case "left":
        return _isWithinTolerance(
                spacePosition.dx, room.position.dx + room.width, tolerance) &&
            _isWithinVerticalBounds(
                spacePosition.dy, room.position.dy, room.height);
      default:
        return false;
    }
  }

  bool _canConnectToCutOut(
      CutOut cutOut, Offset spacePosition, String spaceWall, double tolerance) {
    switch (spaceWall) {
      case "north":
      case "up":
        return _isWithinTolerance(spacePosition.dy,
                cutOut.position.dy + cutOut.height, tolerance) &&
            _isWithinHorizontalBounds(
                spacePosition.dx, cutOut.position.dx, cutOut.width);
      case "south":
      case "down":
        return _isWithinTolerance(
                spacePosition.dy, cutOut.position.dy, tolerance) &&
            _isWithinHorizontalBounds(
                spacePosition.dx, cutOut.position.dx, cutOut.width);
      case "east":
      case "right":
        return _isWithinTolerance(
                spacePosition.dx, cutOut.position.dx, tolerance) &&
            _isWithinVerticalBounds(
                spacePosition.dy, cutOut.position.dy, cutOut.height);
      case "west":
      case "left":
        return _isWithinTolerance(spacePosition.dx,
                cutOut.position.dx + cutOut.width, tolerance) &&
            _isWithinVerticalBounds(
                spacePosition.dy, cutOut.position.dy, cutOut.height);
      default:
        return false;
    }
  }

  bool _isWithinTolerance(double value1, double value2, double tolerance) {
    return (value1 - value2).abs() <= tolerance;
  }

  bool _isWithinHorizontalBounds(double x, double startX, double width) {
    return x >= startX && x <= startX + width;
  }

  bool _isWithinVerticalBounds(double y, double startY, double height) {
    return y >= startY && y <= startY + height;
  }

  double _calculateOffsetForConnectingSpace(
      dynamic target, Offset spacePosition, String spaceWall) {
    switch (spaceWall) {
      case "north":
      case "south":
      case "up":
      case "down":
        return spacePosition.dx - target.position.dx;
      case "east":
      case "west":
      case "right":
      case "left":
        return spacePosition.dy - target.position.dy;
      default:
        return 0;
    }
  }

  // Add these methods to the FloorPlanController class

  // Space Selection
  void selectSpace(String parentName, String spaceId) {
    deselectAll();

    // Check in rooms first
    Room? room = _findRoomByName(parentName);
    if (room != null) {
      try {
        selectedSpace = room.spaces.firstWhere(
          (space) => space.id == spaceId,
        );
        selectedSpace!.isHighlighted = true;
        notifyListeners();
        return;
      } catch (e) {
        // Space not found in room, continue to check cutouts
      }
    }

    // Check in cutouts if not found in rooms
    CutOut? cutOut = _findCutOutByName(parentName);
    if (cutOut != null) {
      try {
        selectedSpace = cutOut.spaces.firstWhere(
          (space) => space.id == spaceId,
        );
        selectedSpace!.isHighlighted = true;
        notifyListeners();
      } catch (e) {
        // Space not found in cutout
      }
    }
  }

  void deselectSpace() {
    if (selectedSpace != null) {
      selectedSpace!.isHighlighted = false;
      selectedSpace = null;
      notifyListeners();
    }
  }

  // Space Movement
  // void moveSpace(double newOffset) {
  //   if (selectedSpace == null) {
  //     Fluttertoast.showToast(msg: "No space selected");
  //     return;
  //   }

  //   // Find parent (room or cutout) of the selected space
  //   dynamic parent = _findSpaceParent(selectedSpace!);
  //   if (parent == null) {
  //     Fluttertoast.showToast(msg: "Could not find parent for selected space");
  //     return;
  //   }

  //   // Check if new position is valid
  //   if (!parent.canAddSpace(
  //       selectedSpace!.wall, newOffset, selectedSpace!.width)) {
  //     Fluttertoast.showToast(msg: "Cannot move space to this position");
  //     return;
  //   }

  //   // Move the space
  //   selectedSpace!.offsetFromWallStart = newOffset;

  //   // If this space is connected to another space, update the connection
  //   if (selectedSpace!.connectedSpace != null) {
  //     _updateConnectedSpacePosition(selectedSpace!, newOffset);
  //   }

  //   notifyListeners();
  // }

  Room? _findRoomBySpace(Space space) {
    try {
      return _rooms.firstWhere((room) => room.spaces.contains(space));
    } catch (e) {
      return null;
    }
  }

  CutOut? _findCutOutBySpace(Space space) {
    try {
      return _cutOuts.firstWhere((cutOut) => cutOut.spaces.contains(space));
    } catch (e) {
      return null;
    }
  }

  void moveSpace(double newOffset) {
    if (selectedSpace == null) {
      Fluttertoast.showToast(msg: "No door selected");
      return;
    }

    // Find the room that contains the selected door
    Room? spaceRoom = _findRoomBySpace(selectedSpace!);
    CutOut? spaceCutOut = _findCutOutBySpace(selectedSpace!);
    if (spaceRoom != null) {
      // Calculate wall length based on door's wall
      double wallLength = (selectedSpace!.wall == "north" ||
              selectedSpace!.wall == "south" ||
              selectedSpace!.wall == "up" ||
              selectedSpace!.wall == "down")
          ? spaceRoom.width
          : spaceRoom.height;

      // Adjust door width for small rooms
      double calculatedWidth = (wallLength / 3).clamp(1.5, 4.0);

      // Adjust minimum corner distance for small rooms
      double minCornerDistance =
          (wallLength < 6) ? 0.5 : Door.minDistanceFromCorner;

      // Calculate valid range for door placement
      double maxOffset = wallLength - calculatedWidth - minCornerDistance;
      double minOffset = minCornerDistance;

      if (newOffset >= minOffset && newOffset <= maxOffset) {
        selectedSpace!.offsetFromWallStart = newOffset;

        // TODO: Implement this if needed.
        // Update connected door if exists
        // if (selectedSpace!.connectedSpace != null) {
        //   Room? connectedRoom =
        //       _findRoomBySpace(selectedSpace!.connectedSpace!);
        //   if (connectedRoom != null) {
        //     double newConnectedOffset = _calculateAdjacentSpaceOffsetForRoom(
        //         spaceRoom, connectedRoom, selectedSpace!);
        //     selectedSpace!.connectedSpace!.offsetFromWallStart =
        //         newConnectedOffset;
        //   }
        // }

        // _saveState();
        notifyListeners();
        Fluttertoast.showToast(msg: "Space moved");
      } else {
        Fluttertoast.showToast(
            msg:
                "Invalid space position. Space must be at least ${minCornerDistance}ft from corners.");
      }
    } else if (spaceCutOut != null) {
      // Calculate wall length based on door's wall
      double wallLength = (selectedSpace!.wall == "north" ||
              selectedSpace!.wall == "south" ||
              selectedSpace!.wall == "up" ||
              selectedSpace!.wall == "down")
          ? spaceCutOut.width
          : spaceCutOut.height;

      // Adjust door width for small rooms
      double calculatedWidth = (wallLength / 3).clamp(1.5, 4.0);

      // Adjust minimum corner distance for small rooms
      double minCornerDistance =
          (wallLength < 6) ? 0.5 : Door.minDistanceFromCorner;

      // Calculate valid range for door placement
      double maxOffset = wallLength - calculatedWidth - minCornerDistance;
      double minOffset = minCornerDistance;

      if (newOffset >= minOffset && newOffset <= maxOffset) {
        selectedSpace!.offsetFromWallStart = newOffset;

        // TODO: Implement this if needed.
        // Update connected door if exists
        // if (selectedSpace!.connectedSpace != null) {
        //   CutOut? connectedCutout =
        //       _findCutOutBySpace(selectedSpace!.connectedSpace!);
        //   if (connectedCutout != null) {
        //     double newConnectedOffset = _calculateAdjacentOffsetForCutOut(
        //         spaceCutOut, connectedCutout, selectedSpace!);
        //     selectedSpace!.connectedSpace!.offsetFromWallStart =
        //         newConnectedOffset;
        //   }
        // }

        // _saveState();
        notifyListeners();
        Fluttertoast.showToast(msg: "Space moved");
      } else {
        Fluttertoast.showToast(
            msg:
                "Invalid space position. Space must be at least ${minCornerDistance}ft from corners.");
      }
    } else {
      Fluttertoast.showToast(
          msg: "Could not find room or cutout for selected space");
      return;
    }
  }

  // Helper methods
  dynamic _findSpaceParent(Space space) {
    // Check rooms first
    for (Room room in _rooms) {
      if (room.spaces.contains(space)) {
        return room;
      }
    }

    // Then check cutouts
    for (CutOut cutOut in _cutOuts) {
      if (cutOut.spaces.contains(space)) {
        return cutOut;
      }
    }

    return null;
  }

  void _removeSpaceAndConnection(List<Space> spacesList, Space spaceToRemove) {
    // If connected, remove the connection first
    if (spaceToRemove.connectedSpace != null) {
      Space connectedSpace = spaceToRemove.connectedSpace!;
      connectedSpace.connectedSpace = null;
      spaceToRemove.connectedSpace = null;

      // Find and remove the connected space from its parent
      dynamic connectedParent = _findSpaceParent(connectedSpace);
      if (connectedParent != null) {
        connectedParent.spaces.remove(connectedSpace);
      }
    }

    // Remove the space itself
    spacesList.remove(spaceToRemove);
    if (selectedSpace == spaceToRemove) {
      selectedSpace = null;
    }

    notifyListeners();
    Fluttertoast.showToast(msg: "Space removed");
  }

  void _updateConnectedSpacePosition(Space space, double newOffset) {
    if (space.connectedSpace == null) return;

    dynamic connectedParent = _findSpaceParent(space.connectedSpace!);
    if (connectedParent == null) return;

    // Calculate new offset for connected space based on the parent's dimensions
    double connectedOffset = _calculateConnectedSpaceOffset(
        space, space.connectedSpace!, connectedParent, newOffset);

    // Update the connected space's position if valid
    if (connectedParent.canAddSpace(space.connectedSpace!.wall, connectedOffset,
        space.connectedSpace!.width)) {
      space.connectedSpace!.offsetFromWallStart = connectedOffset;
    }
  }

  double _calculateConnectedSpaceOffset(Space space, Space connectedSpace,
      dynamic connectedParent, double newOffset) {
    // This calculation depends on the walls that are connected
    // For example, if connecting north to south walls
    switch (space.wall) {
      case "north":
      case "south":
        return newOffset;
      case "east":
      case "west":
        return newOffset;
      default:
        return newOffset;
    }
  }

  // Add this public method
  void addSpaceToSelected(String wall, bool connectToAdjacent) {
    if (selectedRoom != null) {
      _addSpaceToRoom(selectedRoom!, wall, connectToAdjacent);
    } else if (selectedCutOut != null) {
      _addSpaceToCutOut(selectedCutOut!, wall, connectToAdjacent);
    } else {
      Fluttertoast.showToast(msg: "Please select a room or cutout first");
    }
  }

  void _addSpaceToRoom(Room room, String wall, bool connectToAdjacent) {
    double wallLength =
        wall == "north" || wall == "south" ? room.width : room.height;
    double defaultWidth = wallLength / 3;
    double centerOffset = (wallLength - defaultWidth) / 2;

    if (room.canAddSpace(wall, centerOffset, defaultWidth)) {
      String spaceId = room.getNextSpaceId();
      Space newSpace = Space(
        id: spaceId,
        offsetFromWallStart: centerOffset,
        wall: wall,
        width: defaultWidth,
      );
      room.spaces.add(newSpace);

      if (connectToAdjacent) {
        _connectSpaceToAdjacent(room, newSpace);
      }

      notifyListeners();
    } else {
      Fluttertoast.showToast(msg: "Cannot add space at this position");
    }
  }

  void _addSpaceToCutOut(CutOut cutOut, String wall, bool connectToAdjacent) {
    double wallLength =
        wall == "north" || wall == "south" ? cutOut.width : cutOut.height;
    double defaultWidth = wallLength / 3;
    double centerOffset = (wallLength - defaultWidth) / 2;

    if (cutOut.canAddSpace(wall, centerOffset, defaultWidth)) {
      String spaceId = cutOut.getNextSpaceId();
      Space newSpace = Space(
        id: spaceId,
        offsetFromWallStart: centerOffset,
        wall: wall,
        width: defaultWidth,
      );
      cutOut.spaces.add(newSpace);

      if (connectToAdjacent) {
        _connectSpaceToAdjacent(cutOut, newSpace);
      }

      notifyListeners();
    } else {
      Fluttertoast.showToast(msg: "Cannot add space at this position");
    }
  }

  // Update or add these methods
  void addDoorToSelected(String wall) {
    if (selectedRoom != null) {
      _addDoorToRoom(selectedRoom!, wall);
    } else if (selectedCutOut != null) {
      _addDoorToCutOut(selectedCutOut!, wall);
    } else {
      Fluttertoast.showToast(msg: "Please select a room or cutout first");
    }
  }

  void addWindowToSelected(String wall) {
    if (selectedRoom != null) {
      _addWindowToRoom(selectedRoom!, wall);
    } else if (selectedCutOut != null) {
      _addWindowToCutOut(selectedCutOut!, wall);
    } else {
      Fluttertoast.showToast(msg: "Please select a room or cutout first");
    }
  }

  void _addDoorToRoom(Room room, String wall) {
    double wallLength =
        wall == "north" || wall == "south" ? room.width : room.height;
    double defaultWidth = wallLength / 3; // Default width is 1/3 of wall length
    double centerOffset = (wallLength - defaultWidth) / 2; // Center the door

    if (room.canAddDoor(wall, centerOffset, defaultWidth)) {
      String doorId = room.getNextDoorId();
      Door newDoor = Door(
        id: doorId,
        offsetFromWallStart: centerOffset,
        wall: wall,
        width: defaultWidth,
      );
      room.doors.add(newDoor);
      notifyListeners();
    } else {
      Fluttertoast.showToast(msg: "Cannot add door at this position");
    }
  }

  void _addDoorToCutOut(CutOut cutOut, String wall) {
    double wallLength =
        wall == "north" || wall == "south" ? cutOut.width : cutOut.height;
    double defaultWidth = wallLength / 3;
    double centerOffset = (wallLength - defaultWidth) / 2;

    if (cutOut.canAddDoor(wall, centerOffset, defaultWidth)) {
      String doorId = cutOut.getNextDoorId();
      Door newDoor = Door(
        id: doorId,
        offsetFromWallStart: centerOffset,
        wall: wall,
        width: defaultWidth,
      );
      cutOut.doors.add(newDoor);
      notifyListeners();
    } else {
      Fluttertoast.showToast(msg: "Cannot add door at this position");
    }
  }

  void _addWindowToRoom(Room room, String wall) {
    double wallLength =
        wall == "north" || wall == "south" ? room.width : room.height;
    double defaultWidth = wallLength / 3;
    double centerOffset = (wallLength - defaultWidth) / 2;

    if (room.canAddWindow(wall, centerOffset, defaultWidth)) {
      String windowId = room.getNextWindowId();
      Window newWindow = Window(
        id: windowId,
        offsetFromWallStart: centerOffset,
        wall: wall,
        width: defaultWidth,
      );
      room.windows.add(newWindow);
      notifyListeners();
    } else {
      Fluttertoast.showToast(msg: "Cannot add window at this position");
    }
  }

  void _addWindowToCutOut(CutOut cutOut, String wall) {
    double wallLength =
        wall == "north" || wall == "south" ? cutOut.width : cutOut.height;
    double defaultWidth = wallLength / 3;
    double centerOffset = (wallLength - defaultWidth) / 2;

    if (cutOut.canAddWindow(wall, centerOffset, defaultWidth)) {
      String windowId = cutOut.getNextWindowId();
      Window newWindow = Window(
        id: windowId,
        offsetFromWallStart: centerOffset,
        wall: wall,
        width: defaultWidth,
      );
      cutOut.windows.add(newWindow);
      notifyListeners();
    } else {
      Fluttertoast.showToast(msg: "Cannot add window at this position");
    }
  }

  void resizeDoor(double newWidth) {
    if (selectedDoor == null) {
      Fluttertoast.showToast(msg: "No door selected");
      return;
    }

    // Find the parent (room or cutout) of the door
    Room? parentRoom = _findRoomByDoor(selectedDoor!);
    CutOut? parentCutOut = _findCutOutByDoor(selectedDoor!);

    if (parentRoom != null) {
      double wallLength =
          selectedDoor!.wall == "north" || selectedDoor!.wall == "south"
              ? parentRoom.width
              : parentRoom.height;

      // Validate new width
      if (newWidth < Door.minWidth || newWidth > wallLength * 0.8) {
        Fluttertoast.showToast(
            msg:
                "Invalid door width. Must be between ${Door.minWidth} and ${(wallLength * 0.8).toStringAsFixed(1)} feet");
        return;
      }

      // Check if new size would overlap with other doors or windows
      if (parentRoom.canResizeDoor(
          selectedDoor!.wall, selectedDoor!.offsetFromWallStart, newWidth,
          excludeDoor: selectedDoor)) {
        selectedDoor!.width = newWidth;
        notifyListeners();
      } else {
        Fluttertoast.showToast(
            msg: "Cannot resize door: would overlap with other elements");
      }
    } else if (parentCutOut != null) {
      double wallLength =
          selectedDoor!.wall == "north" || selectedDoor!.wall == "south"
              ? parentCutOut.width
              : parentCutOut.height;

      // Validate new width
      if (newWidth < Door.minWidth || newWidth > wallLength * 0.8) {
        Fluttertoast.showToast(
            msg:
                "Invalid door width. Must be between ${Door.minWidth} and ${(wallLength * 0.8).toStringAsFixed(1)} feet");
        return;
      }

      // Check if new size would overlap with other doors or windows
      if (parentCutOut.canResizeDoor(
          selectedDoor!.wall, selectedDoor!.offsetFromWallStart, newWidth,
          excludeDoor: selectedDoor)) {
        selectedDoor!.width = newWidth;
        notifyListeners();
      } else {
        Fluttertoast.showToast(
            msg: "Cannot resize door: would overlap with other elements");
      }
    }
  }

  void resizeWindow(double newWidth) {
    if (selectedWindow == null) {
      Fluttertoast.showToast(msg: "No window selected");
      return;
    }

    // Find the parent (room or cutout) of the window
    Room? parentRoom = _findRoomByWindow(selectedWindow!);
    CutOut? parentCutOut = _findCutOutByWindow(selectedWindow!);

    if (parentRoom != null) {
      double wallLength =
          selectedWindow!.wall == "north" || selectedWindow!.wall == "south"
              ? parentRoom.width
              : parentRoom.height;

      // Validate new width
      if (newWidth < Window.minWidth || newWidth > wallLength * 0.8) {
        Fluttertoast.showToast(
            msg:
                "Invalid window width. Must be between ${Window.minWidth} and ${(wallLength * 0.8).toStringAsFixed(1)} feet");
        return;
      }

      // Check if new size would overlap with other elements
      if (parentRoom.canResizeWindow(
          selectedWindow!.wall, selectedWindow!.offsetFromWallStart, newWidth,
          excludeWindow: selectedWindow)) {
        selectedWindow!.width = newWidth;
        notifyListeners();
      } else {
        Fluttertoast.showToast(
            msg: "Cannot resize window: would overlap with other elements");
      }
    } else if (parentCutOut != null) {
      double wallLength =
          selectedWindow!.wall == "north" || selectedWindow!.wall == "south"
              ? parentCutOut.width
              : parentCutOut.height;

      // Validate new width
      if (newWidth < Window.minWidth || newWidth > wallLength * 0.8) {
        Fluttertoast.showToast(
            msg:
                "Invalid window width. Must be between ${Window.minWidth} and ${(wallLength * 0.8).toStringAsFixed(1)} feet");
        return;
      }

      // Check if new size would overlap with other elements
      if (parentCutOut.canResizeWindow(
          selectedWindow!.wall, selectedWindow!.offsetFromWallStart, newWidth,
          excludeWindow: selectedWindow)) {
        selectedWindow!.width = newWidth;
        notifyListeners();
      } else {
        Fluttertoast.showToast(
            msg: "Cannot resize window: would overlap with other elements");
      }
    }
  }

  void resizeSpace(double newWidth) {
    if (selectedSpace == null) {
      Fluttertoast.showToast(msg: "No space selected");
      return;
    }

    // Find the parent (room or cutout) of the space
    Room? parentRoom = _findRoomBySpace(selectedSpace!);
    CutOut? parentCutOut = _findCutOutBySpace(selectedSpace!);

    if (parentRoom != null) {
      double wallLength =
          selectedSpace!.wall == "north" || selectedSpace!.wall == "south"
              ? parentRoom.width
              : parentRoom.height;

      // Validate new width
      if (newWidth < Space.minWidth || newWidth > wallLength * 0.8) {
        Fluttertoast.showToast(
            msg:
                "Invalid space width. Must be between ${Space.minWidth} and ${(wallLength * 0.8).toStringAsFixed(1)} feet");
        return;
      }

      // Check if new size would overlap with other elements
      if (parentRoom.canResizeSpace(
          selectedSpace!.wall, selectedSpace!.offsetFromWallStart, newWidth,
          excludeSpace: selectedSpace)) {
        selectedSpace!.width = newWidth;
        notifyListeners();
      } else {
        Fluttertoast.showToast(
            msg: "Cannot resize space: would overlap with other elements");
      }
    } else if (parentCutOut != null) {
      double wallLength =
          selectedSpace!.wall == "north" || selectedSpace!.wall == "south"
              ? parentCutOut.width
              : parentCutOut.height;

      // Validate new width
      if (newWidth < Space.minWidth || newWidth > wallLength * 0.8) {
        Fluttertoast.showToast(
            msg:
                "Invalid space width. Must be between ${Space.minWidth} and ${(wallLength * 0.8).toStringAsFixed(1)} feet");
        return;
      }

      // Check if new size would overlap with other elements
      if (parentCutOut.canResizeSpace(
          selectedSpace!.wall, selectedSpace!.offsetFromWallStart, newWidth,
          excludeSpace: selectedSpace)) {
        selectedSpace!.width = newWidth;
        notifyListeners();
      } else {
        Fluttertoast.showToast(
            msg: "Cannot resize space: would overlap with other elements");
      }
    }
  }

  void resetZoom() {
    _zoomLevel = 1.0; // Reset to default zoom level
    notifyListeners();
  }
}
