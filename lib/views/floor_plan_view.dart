import 'dart:math';

import 'package:flutter/material.dart';
import 'package:saysketch_v2/controllers/floor_plan_controller.dart';
import 'package:saysketch_v2/models/door.dart';
import 'package:saysketch_v2/models/floor_base_model.dart';
import 'package:saysketch_v2/models/window.dart';

import '../models/room_model.dart';

class FloorPlanView extends StatelessWidget {
  final FloorPlanController controller;

  const FloorPlanView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: FloorPlanPainter(controller.getRooms(), controller.getBase(),
          controller.selectedRoomName),
      size: Size(MediaQuery.of(context).size.width,
          MediaQuery.of(context).size.height),
      child: Container(),
    );
  }
}

class FloorPlanPainter extends CustomPainter {
  final List<Room> rooms;
  final FloorBase? floorBase;
  String? selectedRoomName;
  static const double scaleFactor = 10.0;

  FloorPlanPainter(this.rooms, this.floorBase, this.selectedRoomName);

  @override
  void paint(Canvas canvas, Size size) {
    final screenCenterX = size.width / 2;
    final screenCenterY = size.height / 2;

    final roomPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final doorPaint = Paint()
      ..color = Colors.brown
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final windowPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final basePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 7
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
      for (int i = 0; i < rooms.length; i++) {
        Room room = rooms[i];

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
            "${room.name[0].toUpperCase()}${room.name.substring(1)}\n${room.width} x ${room.height}";
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
      for (final room in rooms) {
        final roomLeft = baseLeft + (room.position.dx * scaleFactor);
        final roomTop = baseTop + (room.position.dy * scaleFactor);

        // Draw doors
        for (final door in room.doors) {
          _drawDoor(
            canvas,
            door,
            roomLeft,
            roomTop,
            doorPaint,
          );
        }

        // Draw windows
        for (final window in room.windows) {
          _drawWindow(
            canvas,
            window,
            roomLeft,
            roomTop,
            windowPaint,
          );
        }
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

  void _drawDoor(
    Canvas canvas,
    Door door,
    double roomLeft,
    double roomTop,
    Paint doorPaint,
  ) {
    final startX = roomLeft + (door.position.dx * scaleFactor);
    final startY = roomTop + (door.position.dy * scaleFactor);

    // Draw door frame
    final rect = Rect.fromLTWH(
      startX,
      startY,
      door.width * scaleFactor,
      door.length * scaleFactor,
    );

    canvas.save();
    canvas.translate(startX, startY);
    canvas.rotate(door.angle);

    // Draw the door frame
    canvas.drawRect(
      rect,
      doorPaint,
    );

    // Draw door swing arc
    final arcRect = Rect.fromLTWH(
      door.opensInward ? 0 : -door.width * scaleFactor,
      0,
      door.width * scaleFactor * 2,
      door.width * scaleFactor * 2,
    );

    canvas.drawArc(
      arcRect,
      door.opensInward ? -pi / 2 : pi / 2,
      pi / 2,
      false,
      doorPaint,
    );

    canvas.restore();
  }

  void _drawWindow(
    Canvas canvas,
    Window window,
    double roomLeft,
    double roomTop,
    Paint windowPaint,
  ) {
    final startX = roomLeft + (window.position.dx * scaleFactor);
    final startY = roomTop + (window.position.dy * scaleFactor);

    canvas.save();
    canvas.translate(startX, startY);
    canvas.rotate(window.angle);

    // Draw window frame
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        window.width * scaleFactor,
        window.length * scaleFactor,
      ),
      windowPaint,
    );

    // Draw window panes
    final paneSpacing = window.width * scaleFactor / 3;
    canvas.drawLine(
      Offset(paneSpacing, 0),
      Offset(paneSpacing, window.length * scaleFactor),
      windowPaint,
    );
    canvas.drawLine(
      Offset(paneSpacing * 2, 0),
      Offset(paneSpacing * 2, window.length * scaleFactor),
      windowPaint,
    );

    // Draw window sill if needed
    if (window.hasWindowSill) {
      final sillWidth = window.width * scaleFactor * 1.2;
      final sillOffset = (sillWidth - window.width * scaleFactor) / 2;

      canvas.drawRect(
        Rect.fromLTWH(
          -sillOffset,
          window.length * scaleFactor,
          sillWidth,
          scaleFactor * 0.2,
        ),
        windowPaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(FloorPlanPainter oldDelegate) => true;
}
