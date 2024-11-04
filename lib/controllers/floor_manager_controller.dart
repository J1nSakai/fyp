import 'package:flutter/material.dart';
import 'package:saysketch_v2/controllers/floor_plan_controller.dart';
import 'package:saysketch_v2/models/floor_model.dart';
import 'package:saysketch_v2/services/message_service.dart';

class FloorManagerController extends ChangeNotifier {
  final List<Floor> _floors = [];
  Floor? _activeFloor;
  final BuildContext context;

  FloorManagerController(this.context) {
    // Create first floor by default
    Floor firstFloor = Floor(
      level: 0, // Level 0 represents first floor
      controller: FloorPlanController(),
      isActive: true, // First floor is active by default
    );

    _floors.add(firstFloor);
    _activeFloor = firstFloor;
    notifyListeners(); // Notify listeners after initialization
  }

  Floor? get activeFloor => _activeFloor;
  List<Floor> get floors =>
      List.unmodifiable(_floors); // Return unmodifiable list

  void addNewFloor() {
    int newLevel = _floors.length;
    Floor newFloor = Floor(
      level: newLevel,
      controller: FloorPlanController(),
      isActive: true,
    );

    // Deactivate current floor
    if (_activeFloor != null) {
      _activeFloor!.isActive = false;
    }

    _floors.add(newFloor);
    _activeFloor = newFloor;

    MessageService.showMessage(
      context,
      "Floor ${newLevel + 1} created and activated",
      type: MessageType.success,
    );

    notifyListeners(); // Notify after floor addition
  }

  void switchToFloor(int level) {
    if (level < 0 || level >= _floors.length) {
      MessageService.showMessage(
        context,
        "Floor ${level + 1} does not exist",
        type: MessageType.error,
      );
      return;
    }

    // Only switch if it's a different floor
    if (_activeFloor?.level != level) {
      if (_activeFloor != null) {
        _activeFloor!.isActive = false;
      }

      _activeFloor = _floors[level];
      _activeFloor!.isActive = true;

      MessageService.showMessage(
        context,
        "Switched to Floor ${level + 1}",
        type: MessageType.info,
      );
      notifyListeners(); // Notify after floor switch
    }
  }

  FloorPlanController? getActiveController() {
    return _activeFloor?.controller;
  }
}
