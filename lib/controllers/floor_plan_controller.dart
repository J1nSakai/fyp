import 'dart:ui';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:saysketch_v2/models/floor_base_model.dart';

import '../models/room_model.dart';

class FloorPlanController {
  FloorBase? _floorBase;
  final List<Room> _rooms = [];
  final double defaultRoomWidth = 100;
  final double defaultRoomHeight = 100;
  final Offset defaultRoomPosition = const Offset(51, 51);
  final double defaultBaseWidth = 300;
  final double defaultBaseHeight = 200;
  final Offset defaultBasePosition = const Offset(50, 50);

  void setDefaultBase() {
    _floorBase =
        FloorBase(defaultBaseWidth, defaultBaseHeight, defaultBasePosition);
  }

  void addDefaultRoom() {
    _rooms.add(Room(defaultRoomWidth, defaultRoomHeight, defaultRoomPosition));
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
        Fluttertoast.showToast(
            msg: "Room does not fit within the defined Base.");
      }
    } else {
      Fluttertoast.showToast(msg: "Base is not set yet.");
    }
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

  List<Room> getRooms() {
    return _rooms;
  }

  FloorBase? getBase() {
    return _floorBase;
  }

  void removeAllRooms() {
    _rooms.clear();
  }

  void removeLastAddedRoom() {
    _rooms.removeLast();
  }
}
