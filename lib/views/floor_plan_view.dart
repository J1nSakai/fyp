import 'dart:math';

import 'package:flutter/material.dart';
import 'package:saysketch_v2/controllers/floor_plan_controller.dart';
import 'package:saysketch_v2/models/floor_base_model.dart';
import 'package:saysketch_v2/models/stairs.dart';

import '../models/room_model.dart';

class FloorPlanView extends StatelessWidget {
  final FloorPlanController controller;

  const FloorPlanView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: FloorPlanPainter(
          controller.getRooms(),
          controller.getStairs(),
          controller.getBase(),
          controller.selectedRoomName,
          controller.selectedStairs),
      size: Size(MediaQuery.of(context).size.width,
          MediaQuery.of(context).size.height),
      child: Container(),
    );
  }
}

class FloorPlanPainter extends CustomPainter {
  final List<Room> rooms;
  final List<Stairs> stairs;
  final FloorBase? floorBase;
  String? selectedRoomName;
  Stairs? selectedStairs;
  static const double scaleFactor = 10.0;

  FloorPlanPainter(this.rooms, this.stairs, this.floorBase,
      this.selectedRoomName, this.selectedStairs);

  @override
  void paint(Canvas canvas, Size size) {
    final screenCenterX = size.width / 2;
    final screenCenterY = size.height / 2;

    final roomPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final basePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 6
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
      final baseWidthInPixels = floorBase!.width * scaleFactor;
      final baseHeightInPixels = floorBase!.height * scaleFactor;

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
      for (Room room in rooms) {
        // Convert room position to screen coordinates
        final roomLeft = baseLeft + (room.position.dx * scaleFactor);
        final roomTop = baseTop + (room.position.dy * scaleFactor);

        final roomRect = Rect.fromLTWH(
          roomLeft,
          roomTop,
          room.width * scaleFactor,
          room.height * scaleFactor,
        );

        canvas.drawRect(roomRect, roomPaint);

        // Draw room label
        final roomCenterX = roomLeft + (room.width * scaleFactor / 2);
        final roomCenterY = roomTop + (room.height * scaleFactor / 2);

        final roomText =
            "${room.name[0].toUpperCase()}${room.name.substring(1)}\n${room.width}ft x ${room.height}ft";
        final roomTextSpan = TextSpan(text: roomText, style: roomTextStyle);
        final roomTextPainter = TextPainter(
          text: roomTextSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );

        roomTextPainter.layout(minWidth: 0, maxWidth: room.width * scaleFactor);
        roomTextPainter.paint(
          canvas,
          Offset(
            roomCenterX - roomTextPainter.width / 2,
            roomCenterY - roomTextPainter.height / 2,
          ),
        );

        if (selectedRoomName != null) {
          if (room.name == selectedRoomName) {
            final highlightPaint = Paint()
              ..color = Colors.blue
              ..strokeWidth = 3
              ..style = PaintingStyle.stroke;

            canvas.drawRect(roomRect, highlightPaint);
          }
        }
      }

      // After drawing rooms, draw their doors and windows

      // Draw base dimensions
      const baseTextStyle = TextStyle(color: Colors.black, fontSize: 16);
      final baseDimensions = "${floorBase!.width}ft x ${floorBase!.height}ft";
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

    for (Stairs stair in stairs) {
      final baseWidthInPixels = floorBase!.width * scaleFactor;
      final baseHeightInPixels = floorBase!.height * scaleFactor;

      final baseLeft = screenCenterX - (baseWidthInPixels / 2);
      final baseTop = screenCenterY - (baseHeightInPixels / 2);
      final stairLeft = baseLeft + (stair.position.dx * scaleFactor);
      final stairTop = baseTop + (stair.position.dy * scaleFactor);

      final stairRect = Rect.fromLTWH(
        stairLeft,
        stairTop,
        stair.width * scaleFactor,
        stair.length * scaleFactor,
      );

      // Draw stairs outline
      final stairPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawRect(stairRect, stairPaint);

      // Draw step lines
      final stepPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 1;

      final stepHeight = stair.length / stair.numberOfSteps;

      for (int i = 1; i < stair.numberOfSteps; i++) {
        final y = stairTop + (i * stepHeight * scaleFactor);
        canvas.drawLine(
          Offset(stairLeft, y),
          Offset(stairLeft + (stair.width * scaleFactor), y),
          stepPaint,
        );
      }

      // Draw direction arrow
      final arrowPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 2;

      final centerX = stairLeft + (stair.width * scaleFactor / 2);
      final centerY = stairTop + (stair.length * scaleFactor / 2);
      final arrowSize = min(stair.width, stair.length) * scaleFactor * 0.3;

      if (stair.direction == "up") {
        canvas.drawLine(
          Offset(centerX, centerY + arrowSize),
          Offset(centerX, centerY - arrowSize),
          arrowPaint,
        );
        canvas.drawLine(
          Offset(centerX, centerY - arrowSize),
          Offset(centerX - arrowSize * 0.5, centerY - arrowSize * 0.5),
          arrowPaint,
        );
        canvas.drawLine(
          Offset(centerX, centerY - arrowSize),
          Offset(centerX + arrowSize * 0.5, centerY - arrowSize * 0.5),
          arrowPaint,
        );
      } else {
        canvas.drawLine(
          Offset(centerX, centerY - arrowSize),
          Offset(centerX, centerY + arrowSize),
          arrowPaint,
        );
        canvas.drawLine(
          Offset(centerX, centerY + arrowSize),
          Offset(centerX - arrowSize * 0.5, centerY + arrowSize * 0.5),
          arrowPaint,
        );
        canvas.drawLine(
          Offset(centerX, centerY + arrowSize),
          Offset(centerX + arrowSize * 0.5, centerY + arrowSize * 0.5),
          arrowPaint,
        );
      }

      // Highlight selected stairs
      if (selectedStairs == stair) {
        final highlightPaint = Paint()
          ..color = Colors.blue
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;

        canvas.drawRect(stairRect, highlightPaint);
      }
    }
  }

  @override
  bool shouldRepaint(FloorPlanPainter oldDelegate) => true;
}
