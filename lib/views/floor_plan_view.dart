import 'dart:math';

import 'package:flutter/material.dart';
import 'package:saysketch_v2/controllers/floor_plan_controller.dart';
import 'package:saysketch_v2/models/door.dart';
import 'package:saysketch_v2/models/floor_base_model.dart';
import 'package:saysketch_v2/models/stairs.dart';

import '../models/room_model.dart';
import '../models/window.dart';
import 'widgets/scale_indicator.dart';

class FloorPlanView extends StatelessWidget {
  final FloorPlanController controller;

  const FloorPlanView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(100),
          minScale: 0.25,
          maxScale: 6.0,
          child: CustomPaint(
            painter: FloorPlanPainter(
              controller.getRooms(),
              controller.getStairs(),
              controller.getBase(),
              controller.selectedRoomName,
              controller.selectedStairs,
              controller.zoomLevel,
              controller.selectedDoor,
              controller.selectedWindow,
            ),
            size: Size(
              MediaQuery.sizeOf(context).width,
              MediaQuery.sizeOf(context).height,
            ),
          ),
        ),
        // Floating Scale Indicator
        Positioned(
          right: 20,
          bottom: 20,
          child: ScaleIndicator(zoomLevel: controller.zoomLevel),
        ),
      ],
    );
  }
}

class FloorPlanPainter extends CustomPainter {
  final List<Room> rooms;
  final List<Stairs> stairs;
  final FloorBase? floorBase;
  String? selectedRoomName;
  Stairs? selectedStairs;
  static const double scaleFactor = 24.0; // 1:50 (1ft = 24px)
  final double zoomLevel;
  final Door? selectedDoor;
  final Window? selectedWindow;

  FloorPlanPainter(
      this.rooms,
      this.stairs,
      this.floorBase,
      this.selectedRoomName,
      this.selectedStairs,
      this.zoomLevel,
      this.selectedDoor,
      this.selectedWindow);

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
      print("Drawing base: $floorBase"); // Debug print
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

        // Draw normal room walls if not hidden
        if (!room.hasHiddenWalls) {
          Paint normalPaint = Paint()
            ..color = Colors.black
            ..strokeWidth = room.roomPaint.strokeWidth
            ..style = PaintingStyle.stroke;
          canvas.drawRect(roomRect, normalPaint);
        }

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

        // Always draw selection highlight if room is selected, regardless of hidden walls
        if (selectedRoomName != null && room.name == selectedRoomName) {
          Paint selectionPaint = Paint()
            ..color = Colors.red
            ..strokeWidth = room.roomPaint.strokeWidth
            ..style = PaintingStyle.stroke;
          canvas.drawRect(roomRect, selectionPaint);
        }
      }

      // After drawing rooms but before drawing their dimensions, draw the doors
      if (floorBase != null) {
        for (Room room in rooms) {
          _drawDoorsForRoom(
              canvas, room, baseLeft, baseTop, adjustedScaleFactor);
        }
      }

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
    //else {
    //   print("No base to draw"); // Debug print
    // }

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

    // After drawing rooms and before drawing doors, add window drawing
    for (Room room in rooms) {
      final baseWidthInPixels = floorBase!.width * adjustedScaleFactor;
      final baseHeightInPixels = floorBase!.height * adjustedScaleFactor;

      final baseLeft = screenCenterX - (baseWidthInPixels / 2);
      final baseTop = screenCenterY - (baseHeightInPixels / 2);

      _drawWindowsForRoom(canvas, room, baseLeft, baseTop, adjustedScaleFactor);
    }
  }

  void _drawDoorsForRoom(Canvas canvas, Room room, double baseLeft,
      double baseTop, double scaleFactor) {
    for (Door door in room.doors) {
      final doorPaint = Paint()
        ..color = door == selectedDoor
            ? Colors.green
            : (door.isHighlighted ? Colors.blue : Colors.black)
        ..strokeWidth = (door == selectedDoor || door.isHighlighted)
            ? room.roomPaint.strokeWidth - 1
            : room.roomPaint.strokeWidth - 1.5
        ..style = PaintingStyle.stroke;

      // Convert room position to screen coordinates
      final roomLeft = baseLeft + (room.position.dx * scaleFactor);
      final roomTop = baseTop + (room.position.dy * scaleFactor);
      final roomRight = roomLeft + (room.width * scaleFactor);
      final roomBottom = roomTop + (room.height * scaleFactor);

      // Calculate door length based on room dimensions
      double doorLength;
      switch (door.wall) {
        case "north":
        case "south":
        case "up":
        case "down":
          doorLength = (room.width * scaleFactor) / 3; // 1/3 of room width
          break;
        case "east":
        case "west":
        case "left":
        case "right":
          doorLength = (room.height * scaleFactor) / 3; // 1/3 of room height
          break;
        default:
          doorLength = Door.defaultWidth * scaleFactor;
      }

      // Calculate door position and dimensions
      double doorStart;
      Offset gapStart, gapEnd;
      Offset doorLineStart, doorLineEnd;

      switch (door.wall) {
        case "north":
        case "up":
          doorStart = roomLeft + (door.offsetFromWallStart * scaleFactor);
          gapStart = Offset(doorStart, roomTop);
          gapEnd = Offset(doorStart + doorLength, roomTop);
          doorLineStart = door.openLeft ? gapStart : gapEnd;
          doorLineEnd = Offset(doorLineStart.dx,
              door.swingInward ? roomTop + doorLength : roomTop - doorLength);
          break;

        case "south":
        case "down":
          doorStart = roomLeft + (door.offsetFromWallStart * scaleFactor);
          gapStart = Offset(doorStart, roomBottom);
          gapEnd = Offset(doorStart + doorLength, roomBottom);
          doorLineStart = door.openLeft ? gapStart : gapEnd;
          doorLineEnd = Offset(
              doorLineStart.dx,
              door.swingInward
                  ? roomBottom - doorLength
                  : roomBottom + doorLength);
          break;

        case "east":
        case "right":
          doorStart = roomTop + (door.offsetFromWallStart * scaleFactor);
          gapStart = Offset(roomRight, doorStart);
          gapEnd = Offset(roomRight, doorStart + doorLength);
          doorLineStart = door.openLeft ? gapStart : gapEnd;
          doorLineEnd = Offset(
              door.swingInward
                  ? roomRight - doorLength
                  : roomRight + doorLength,
              doorLineStart.dy);
          break;

        case "west":
        case "left":
          doorStart = roomTop + (door.offsetFromWallStart * scaleFactor);
          gapStart = Offset(roomLeft, doorStart);
          gapEnd = Offset(roomLeft, doorStart + doorLength);
          doorLineStart = door.openLeft ? gapStart : gapEnd;
          doorLineEnd = Offset(
              door.swingInward ? roomLeft + doorLength : roomLeft - doorLength,
              doorLineStart.dy);
          break;

        default:
          continue;
      }

      // Draw door gap (erase part of the wall)
      final gapPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = doorPaint.strokeWidth + 1
        ..style = PaintingStyle.stroke;
      canvas.drawLine(gapStart, gapEnd, gapPaint);

      // Draw door line
      canvas.drawLine(doorLineStart, doorLineEnd, doorPaint);

      // Create a dotted effect for the arc
      const dashLength = 3.0;
      const gapLength = 3.0;
      final arcPath = Path()..moveTo(doorLineEnd.dx, doorLineEnd.dy);

      // Calculate control point for the arc
      Offset controlPoint;
      if (door.wall == "north" ||
          door.wall == "south" ||
          door.wall == "up" ||
          door.wall == "down") {
        controlPoint =
            Offset(door.openLeft ? gapEnd.dx : gapStart.dx, doorLineEnd.dy);
      } else {
        controlPoint =
            Offset(doorLineEnd.dx, door.openLeft ? gapEnd.dy : gapStart.dy);
      }

      // Draw arc to the opposite end of the gap from where the door line starts
      Offset arcEndPoint = door.openLeft ? gapEnd : gapStart;

      // Create the quadratic bezier path
      arcPath.quadraticBezierTo(
        controlPoint.dx,
        controlPoint.dy,
        arcEndPoint.dx,
        arcEndPoint.dy,
      );

      // Draw the path with dashes
      final metric = arcPath.computeMetrics().first;
      double distance = 0;
      bool drawDash = true;

      while (distance < metric.length) {
        double nextDistance = distance + (drawDash ? dashLength : gapLength);
        if (nextDistance > metric.length) {
          nextDistance = metric.length;
        }

        if (drawDash) {
          final pathSegment = metric.extractPath(distance, nextDistance);
          canvas.drawPath(pathSegment, doorPaint);
        }

        distance = nextDistance;
        drawDash = !drawDash;
      }

      // Draw connecting door indicator if this is a connecting door
      if (door.connectedDoor != null) {
        final connectingDotPaint = Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill;
        canvas.drawCircle(doorLineStart, 2, connectingDotPaint);
      }
    }
  }

  void _drawWindowsForRoom(Canvas canvas, Room room, double baseLeft,
      double baseTop, double scaleFactor) {
    for (Window window in room.windows) {
      final windowPaint = Paint()
        ..color = window == selectedWindow
            ? Colors.yellow
            : (window.isHighlighted ? Colors.blue : Colors.black)
        ..strokeWidth =
            room.roomPaint.strokeWidth * 0.25 // Match room's stroke width
        ..style = PaintingStyle.stroke;

      // Convert room position to screen coordinates
      final roomLeft = baseLeft + (room.position.dx * scaleFactor);
      final roomTop = baseTop + (room.position.dy * scaleFactor);
      final roomRight = roomLeft + (room.width * scaleFactor);
      final roomBottom = roomTop + (room.height * scaleFactor);

      // Calculate window length (1/3 of wall length)
      double windowLength;
      switch (window.wall) {
        case "north":
        case "south":
        case "up":
        case "down":
          windowLength = (room.width * scaleFactor) / 3;
          break;
        case "east":
        case "west":
        case "left":
        case "right":
          windowLength = (room.height * scaleFactor) / 3;
          break;
        default:
          windowLength = Window.defaultWidth * scaleFactor;
      }

      // Calculate window frame points
      double windowStart;
      Offset gapStart, gapEnd;
      Rect windowFrame;
      final frameThickness = room.roomPaint.strokeWidth; // Frame thickness

      switch (window.wall) {
        case "north":
        case "up":
          windowStart = roomLeft + (window.offsetFromWallStart * scaleFactor);
          gapStart = Offset(windowStart, roomTop);
          gapEnd = Offset(windowStart + windowLength, roomTop);
          windowFrame = Rect.fromLTWH(
              windowStart, // Align with gap start
              roomTop - frameThickness / 2, // Center on wall
              windowLength, // Match gap length
              frameThickness);
          break;

        case "south":
        case "down":
          windowStart = roomLeft + (window.offsetFromWallStart * scaleFactor);
          gapStart = Offset(windowStart, roomBottom);
          gapEnd = Offset(windowStart + windowLength, roomBottom);
          windowFrame = Rect.fromLTWH(
              windowStart, // Align with gap start
              roomBottom - frameThickness / 2, // Center on wall
              windowLength, // Match gap length
              frameThickness);
          break;

        case "east":
        case "right":
          windowStart = roomTop + (window.offsetFromWallStart * scaleFactor);
          gapStart = Offset(roomRight, windowStart);
          gapEnd = Offset(roomRight, windowStart + windowLength);
          windowFrame = Rect.fromLTWH(
              roomRight - frameThickness / 2, // Center on wall
              windowStart, // Align with gap start
              frameThickness,
              windowLength // Match gap length
              );
          break;

        case "west":
        case "left":
          windowStart = roomTop + (window.offsetFromWallStart * scaleFactor);
          gapStart = Offset(roomLeft, windowStart);
          gapEnd = Offset(roomLeft, windowStart + windowLength);
          windowFrame = Rect.fromLTWH(
              roomLeft - frameThickness / 2, // Center on wall
              windowStart, // Align with gap start
              frameThickness,
              windowLength // Match gap length
              );
          break;

        default:
          continue;
      }

      // Draw window gap (erase part of the wall)
      final gapPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = windowPaint.strokeWidth + 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(gapStart, gapEnd, gapPaint);

      // Draw window frame
      canvas.drawRect(windowFrame, windowPaint);

      // Draw center line
      final centerStart = Offset(
        (gapStart.dx + gapEnd.dx) / 2,
        (gapStart.dy + gapEnd.dy) / 2,
      );
      final centerOffset = window.wall == "north" ||
              window.wall == "south" ||
              window.wall == "up" ||
              window.wall == "down"
          ? Offset(0, frameThickness / 2)
          : Offset(frameThickness / 2, 0);

      canvas.drawLine(
        centerStart - centerOffset,
        centerStart + centerOffset,
        windowPaint,
      );

      // Draw connecting window indicator if this is a connecting window
      if (window.connectedWindow != null) {
        final connectingDotPaint = Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill;
        canvas.drawCircle(centerStart, 1, connectingDotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(FloorPlanPainter oldDelegate) => true;
}
