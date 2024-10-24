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
  static const double SCALE_FACTOR = 10.0;

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

    const TextStyle roomTextStyle = TextStyle(
      color: Colors.black,
      fontSize: 14,
    );

    // Draw base if present
    if (floorBase != null) {
      final baseWidthInPixels = floorBase!.width * SCALE_FACTOR;
      final baseHeightInPixels = floorBase!.height * SCALE_FACTOR;

      // Calculate base position relative to screen center
      final baseLeft = screenCenterX - (baseWidthInPixels / 2);
      final baseTop = screenCenterY - (baseHeightInPixels / 2);

      final baseRect = Rect.fromLTWH(
        baseLeft,
        baseTop,
        baseWidthInPixels,
        baseHeightInPixels,
      );

      canvas.drawRect(baseRect, baseFillPaint);
      canvas.drawRect(baseRect, basePaint);

      // Draw rooms
      for (int i = 0; i < rooms.length; i++) {
        Room room = rooms[i];

        // Convert room position to screen coordinates
        final roomLeft = baseLeft + (room.position.dx * SCALE_FACTOR);
        final roomTop = baseTop + (room.position.dy * SCALE_FACTOR);

        final roomRect = Rect.fromLTWH(
          roomLeft,
          roomTop,
          room.width * SCALE_FACTOR,
          room.height * SCALE_FACTOR,
        );

        canvas.drawRect(roomRect, roomPaint);

        // Draw room label
        final roomCenterX = roomLeft + (room.width * SCALE_FACTOR / 2);
        final roomCenterY = roomTop + (room.height * SCALE_FACTOR / 2);

        final roomText = "Room ${i + 1}\n${room.width} x ${room.height}";
        final roomTextSpan = TextSpan(text: roomText, style: roomTextStyle);
        final roomTextPainter = TextPainter(
          text: roomTextSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );

        roomTextPainter.layout(
            minWidth: 0, maxWidth: room.width * SCALE_FACTOR);
        roomTextPainter.paint(
          canvas,
          Offset(
            roomCenterX - roomTextPainter.width / 2,
            roomCenterY - roomTextPainter.height / 2,
          ),
        );
      }

      // Draw base dimensions
      const baseTextStyle = TextStyle(color: Colors.black, fontSize: 16);
      final baseDimensions = "${floorBase!.width} x ${floorBase!.height}";
      final baseTextSpan = TextSpan(text: baseDimensions, style: baseTextStyle);
      final baseTextPainter = TextPainter(
        text: baseTextSpan,
        textDirection: TextDirection.ltr,
      );

      baseTextPainter.layout();
      baseTextPainter.paint(
        canvas,
        Offset(
          screenCenterX - baseTextPainter.width / 2,
          baseTop - baseTextPainter.height - 10,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(FloorPlanPainter oldDelegate) => true;
}
