import '../controllers/floor_plan_controller.dart';

class Floor {
  final int level;
  final FloorPlanController controller;
  bool isActive;

  Floor({
    required this.level,
    required this.controller,
    this.isActive = false,
  });
}
