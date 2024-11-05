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
    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(100),
      minScale: 0.5,
      maxScale: 4.0,
      child: CustomPaint(
        painter: FloorPlanPainter(
            controller.getRooms(),
            controller.getStairs(),
            controller.getBase(),
            controller.selectedRoomName,
            controller.selectedStairs,
            controller.zoomLevel),
        size: Size(MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.height),
        child: Container(),
      ),
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
  final double zoomLevel;

  FloorPlanPainter(this.rooms, this.stairs, this.floorBase,
      this.selectedRoomName, this.selectedStairs, this.zoomLevel);

  @override
  void paint(Canvas canvas, Size size) {
    final screenCenterX = size.width / 2;
    final screenCenterY = size.height / 2;

    // Apply zoom to scaleFactor
    final adjustedScaleFactor = scaleFactor * zoomLevel;

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
      final baseWidthInPixels = floorBase!.width * adjustedScaleFactor;
      final baseHeightInPixels = floorBase!.height * adjustedScaleFactor;

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
        final roomLeft = baseLeft + (room.position.dx * adjustedScaleFactor);
        final roomTop = baseTop + (room.position.dy * adjustedScaleFactor);

        final roomRect = Rect.fromLTWH(
          roomLeft,
          roomTop,
          room.width * adjustedScaleFactor,
          room.height * adjustedScaleFactor,
        );

        canvas.drawRect(roomRect, room.roomPaint);

        // Draw room label
        final roomCenterX = roomLeft + (room.width * adjustedScaleFactor / 2);
        final roomCenterY = roomTop + (room.height * adjustedScaleFactor / 2);

        final roomText =
            "${room.name[0].toUpperCase()}${room.name.substring(1)}\n${room.width}ft x ${room.height}ft";
        final roomTextSpan = TextSpan(text: roomText, style: roomTextStyle);
        final roomTextPainter = TextPainter(
          text: roomTextSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );

        roomTextPainter.layout(
            minWidth: 0, maxWidth: room.width * adjustedScaleFactor);
        roomTextPainter.paint(
          canvas,
          Offset(
            roomCenterX - roomTextPainter.width / 2,
            roomCenterY - roomTextPainter.height / 2,
          ),
        );

        if (selectedRoomName != null) {
          if (room.name == selectedRoomName) {
            room.roomPaint.color = Colors.red;
            canvas.drawRect(roomRect, room.roomPaint);
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
      final baseWidthInPixels = floorBase!.width * adjustedScaleFactor;
      final baseHeightInPixels = floorBase!.height * adjustedScaleFactor;

      final baseLeft = screenCenterX - (baseWidthInPixels / 2);
      final baseTop = screenCenterY - (baseHeightInPixels / 2);
      final stairLeft = baseLeft + (stair.position.dx * adjustedScaleFactor);
      final stairTop = baseTop + (stair.position.dy * adjustedScaleFactor);

      final stairRect = Rect.fromLTWH(
        stairLeft,
        stairTop,
        stair.width * adjustedScaleFactor,
        stair.length * adjustedScaleFactor,
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

      switch (stair.direction) {
        case "up":
        case "down":
          // Horizontal steps for up/down stairs
          final stepHeight = stair.length / stair.numberOfSteps;
          for (int i = 1; i < stair.numberOfSteps; i++) {
            final y = stairTop + (i * stepHeight * adjustedScaleFactor);
            canvas.drawLine(
              Offset(stairLeft, y),
              Offset(stairLeft + (stair.width * adjustedScaleFactor), y),
              stepPaint,
            );
          }
          break;

        case "left":
        case "right":
          // Vertical steps for left/right stairs
          final stepWidth = stair.width / stair.numberOfSteps;
          for (int i = 1; i < stair.numberOfSteps; i++) {
            final x = stairLeft + (i * stepWidth * adjustedScaleFactor);
            canvas.drawLine(
              Offset(x, stairTop),
              Offset(x, stairTop + (stair.length * adjustedScaleFactor)),
              stepPaint,
            );
          }
          break;
      }

      // Draw direction arrow
      final arrowPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 2;

      final centerX = stairLeft + (stair.width * adjustedScaleFactor / 2);
      final centerY = stairTop + (stair.length * adjustedScaleFactor / 2);
      final arrowSize =
          min(stair.width, stair.length) * adjustedScaleFactor * 0.3;

      switch (stair.direction) {
        case "up":
          // Draw vertical line up
          canvas.drawLine(
            Offset(centerX, centerY + arrowSize),
            Offset(centerX, centerY - arrowSize),
            arrowPaint,
          );
          // Draw arrow head
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
          break;

        case "down":
          // Draw vertical line down
          canvas.drawLine(
            Offset(centerX, centerY - arrowSize),
            Offset(centerX, centerY + arrowSize),
            arrowPaint,
          );
          // Draw arrow head
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
          break;

        case "left":
          // Draw horizontal line left
          canvas.drawLine(
            Offset(centerX + arrowSize, centerY),
            Offset(centerX - arrowSize, centerY),
            arrowPaint,
          );
          // Draw arrow head
          canvas.drawLine(
            Offset(centerX - arrowSize, centerY),
            Offset(centerX - arrowSize * 0.5, centerY - arrowSize * 0.5),
            arrowPaint,
          );
          canvas.drawLine(
            Offset(centerX - arrowSize, centerY),
            Offset(centerX - arrowSize * 0.5, centerY + arrowSize * 0.5),
            arrowPaint,
          );
          break;

        case "right":
          // Draw horizontal line right
          canvas.drawLine(
            Offset(centerX - arrowSize, centerY),
            Offset(centerX + arrowSize, centerY),
            arrowPaint,
          );
          // Draw arrow head
          canvas.drawLine(
            Offset(centerX + arrowSize, centerY),
            Offset(centerX + arrowSize * 0.5, centerY - arrowSize * 0.5),
            arrowPaint,
          );
          canvas.drawLine(
            Offset(centerX + arrowSize, centerY),
            Offset(centerX + arrowSize * 0.5, centerY + arrowSize * 0.5),
            arrowPaint,
          );
          break;
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
