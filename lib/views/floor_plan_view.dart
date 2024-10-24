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
      size: Size(MediaQuery.of(context).size.width,
          MediaQuery.of(context).size.height),
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
    final screenCenterX = size.width / 2;
    final screenCenterY = size.height / 2;

    final roomPaint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final basePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    final baseFillPaint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.fill;

    // TextStyle for room names and dimensions
    const TextStyle roomTextStyle =
        TextStyle(color: Colors.black, fontSize: 14);

    // Draw rooms with their names and dimensions at the center
    if (rooms.isNotEmpty) {
      for (int i = 0; i < rooms.length; i++) {
        Room room = rooms[i];
        Rect rect = Rect.fromLTWH(room.position.dx, room.position.dy,
            room.width * 10, room.height * 10);
        canvas.drawRect(rect, roomPaint);

        // Calculate the center of the room
        final roomCenterX = room.position.dx + (room.width * 10) / 2;
        final roomCenterY = room.position.dy + (room.height * 10) / 2;

        // Create text for room name and dimensions
        String roomText = "Room ${i + 1} \n ${room.width} x ${room.height}";
        TextSpan roomTextSpan = TextSpan(text: roomText, style: roomTextStyle);
        TextPainter roomTextPainter =
            TextPainter(text: roomTextSpan, textDirection: TextDirection.ltr);
        roomTextPainter.layout();

        // Draw the room name and dimensions at the center of the room
        roomTextPainter.paint(
            canvas,
            Offset(roomCenterX - roomTextPainter.width / 2,
                roomCenterY - roomTextPainter.height / 2));
      }
    }

    // Draw base if present
    if (floorBase != null) {
      final baseWidthInPixels = floorBase!.width * 10;
      final baseHeightInPixels = floorBase!.height * 10;

      // Draw the base
      Rect rect = Rect.fromLTWH(
          screenCenterX - (baseWidthInPixels / 2),
          screenCenterY - (baseHeightInPixels / 2),
          baseWidthInPixels,
          baseHeightInPixels);
      Rect rectFill = Rect.fromLTWH(
          screenCenterX - (baseWidthInPixels / 2),
          screenCenterY - (baseHeightInPixels / 2),
          baseWidthInPixels,
          baseHeightInPixels);
      canvas.drawRect(rect, basePaint);
      canvas.drawRect(rectFill, baseFillPaint);

      // Create TextPainter for base name and dimensions
      TextStyle baseTextStyle =
          const TextStyle(color: Colors.black, fontSize: 16);
      final baseTextPainter = TextPainter(
        text: TextSpan(text: "Base", style: baseTextStyle),
        textDirection: TextDirection.ltr,
      );
      baseTextPainter.layout();

      final baseDimensionsPainter = TextPainter(
        text: TextSpan(
            text: "${floorBase!.width} x ${floorBase!.height}",
            style: baseTextStyle),
        textDirection: TextDirection.ltr,
      );
      baseDimensionsPainter.layout();

      // Draw base text outside the base (top-center)
      double baseTextX = screenCenterX - baseTextPainter.width / 2;
      double baseTextY =
          screenCenterY - baseHeightInPixels / 2 - baseTextPainter.height - 20;

      baseTextPainter.paint(canvas, Offset(baseTextX, baseTextY));
      baseDimensionsPainter.paint(
          canvas, Offset(baseTextX, baseTextY + baseTextPainter.height));
    }
  }

  @override
  bool shouldRepaint(FloorPlanPainter oldDelegate) => true;
}
