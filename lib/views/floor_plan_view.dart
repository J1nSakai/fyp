import 'package:flutter/material.dart';
import 'package:saysketch_v2/controllers/floor_plan_controller.dart';
import 'package:saysketch_v2/models/floor_base_model.dart';

import '../models/room_model.dart';

class FloorPlanView extends StatelessWidget {
  final FloorPlanController controller;

  const FloorPlanView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: FloorPlanPainter(controller.getRooms(), controller.getBase()),
      child: Container(),
    );
  }
}

class FloorPlanPainter extends CustomPainter {
  final List<Room> rooms;
  final FloorBase? floorBase;

  FloorPlanPainter(this.rooms, this.floorBase);

  @override
  void paint(Canvas canvas, Size size) {
    final roomsPaint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final basePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    if (rooms.isNotEmpty) {
      for (Room room in rooms) {
        Rect rect = Rect.fromLTWH(room.position.dx, room.position.dy,
            room.width * 10, room.height * 10);
        canvas.drawRect(rect, roomsPaint);
      }
    }

    if (floorBase != null) {
      Rect rect = Rect.fromLTWH(floorBase!.position.dx, floorBase!.position.dy,
          floorBase!.width * 10, floorBase!.height * 10);
      canvas.drawRect(rect, basePaint);
    }
  }

  @override
  bool shouldRepaint(FloorPlanPainter oldDelegate) => true;
}
