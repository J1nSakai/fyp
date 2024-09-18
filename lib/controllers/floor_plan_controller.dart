import 'dart:ui';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:saysketch_v2/models/floor_base_model.dart';

import '../models/room_model.dart';

class FloorPlanController {
  FloorBase? _floorBase;
  final List<Room> _rooms = [];

  void setDefaultBase() {
    const double defaultBaseWidth = 30.5;
    const double defaultBaseHeight = 60;
    const Offset defaultBasePosition = Offset(40, 35);

    _floorBase =
        FloorBase(defaultBaseWidth, defaultBaseHeight, defaultBasePosition);
  }

  void addDefaultRoom() {
    const double defaultRoomWidth = 10;
    const double defaultRoomHeight = 10;
    const Offset defaultRoomPosition = Offset(40, 35);

    addRoom(defaultRoomWidth, defaultRoomHeight, defaultRoomPosition);
  }

  void setBase(double width, double height, Offset position) {
    _floorBase = FloorBase(width, height, position);
  }

  void addRoom(double width, double height, Offset position) {
    if (_floorBase != null) {
      // check if the room fits within the base
      if (_roomFitsWithinTheBase(width, height, position)) {
        _rooms.add(Room(width, height, position));
      } else {
        Fluttertoast.showToast(msg: "Room does not fit within the  Base.");
      }
    } else {
      Fluttertoast.showToast(msg: "Base is not set yet.");
    }
    print(_rooms);
  }

  bool _roomFitsWithinTheBase(double roomWidth, roomHeight, Offset position) {
    if (_floorBase == null) return false;

    double baseRight = _floorBase!.position.dx + _floorBase!.width;
    double baseBottom = _floorBase!.position.dy + _floorBase!.height;

    double roomRight = position.dx + roomWidth;
    double roomBottom = position.dy + roomHeight;

    return (position.dx >= _floorBase!.position.dx &&
        roomRight <= baseRight &&
        position.dy >= _floorBase!.position.dy &&
        roomBottom <= baseBottom);
  }

  bool _roomDoesNotOverlapWithOtherRooms() {
    return false;
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
    if (_rooms.isNotEmpty) {
      removeAllRooms();
    }
    print("Base removed");
    _floorBase = null;
  }

  void removeLastAddedRoom() {
    _rooms.removeLast();
  }
}
