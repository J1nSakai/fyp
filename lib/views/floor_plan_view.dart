import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saysketch_v2/controllers/floor_plan_controller.dart';
import 'package:saysketch_v2/models/door.dart';
import 'package:saysketch_v2/models/floor_base_model.dart';
import 'package:saysketch_v2/models/stairs.dart';

import '../models/cut_out.dart';
import '../models/room_model.dart';
import '../models/space.dart';
import '../models/window.dart';
import 'widgets/scale_indicator.dart';

class FloorPlanView extends StatefulWidget {
  final FloorPlanController controller;

  const FloorPlanView({super.key, required this.controller});

  @override
  State<FloorPlanView> createState() => _FloorPlanViewState();
}

class _FloorPlanViewState extends State<FloorPlanView> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    // Update the InteractiveViewer's transform when zoom changes
    final scale = widget.controller.zoomLevel;
    final matrix = Matrix4.identity()..scale(scale, scale, 1.0);
    _transformationController.value = matrix;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transformationController,
          boundaryMargin: const EdgeInsets.all(1000),
          minScale: 0.1,
          maxScale: 10.0,
          child: CustomPaint(
            painter: FloorPlanPainter(
              widget.controller.getRooms(),
              widget.controller.getStairs(),
              widget.controller.getBase(),
              widget.controller.selectedRoomName,
              widget.controller.selectedStairs,
              widget.controller.zoomLevel,
              widget.controller.selectedDoor,
              widget.controller.selectedWindow,
              widget.controller.getCutOuts(),
              widget.controller.selectedCutOut,
              widget.controller.selectedSpace,
              isDarkMode,
            ),
            size: Size(
              MediaQuery.sizeOf(context).width * 4,
              MediaQuery.sizeOf(context).height * 4,
            ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: ScaleIndicator(
            zoomLevel: widget.controller.zoomLevel,
          ),
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
  final List<CutOut> cutOuts;
  final CutOut? selectedCutOut;
  final Space? selectedSpace;
  final bool isDarkMode;

  // Define theme-dependent colors
  late final Color wallColor;
  late final Color backgroundColor;
  late final Color textColor;

  FloorPlanPainter(
      this.rooms,
      this.stairs,
      this.floorBase,
      this.selectedRoomName,
      this.selectedStairs,
      this.zoomLevel,
      this.selectedDoor,
      this.selectedWindow,
      this.cutOuts,
      this.selectedCutOut,
      this.selectedSpace,
      this.isDarkMode) {
    // Initialize colors based on theme
    wallColor = isDarkMode ? Colors.white70 : Colors.black;
    backgroundColor = isDarkMode ? const Color(0xFF1A1B26) : Colors.white;
    textColor = isDarkMode ? Colors.white70 : Colors.black;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (floorBase == null) return;

    final screenCenterX = size.width / 2;
    final screenCenterY = size.height / 2;
    final adjustedScaleFactor = scaleFactor * zoomLevel;

    final basePaint = Paint()
      ..color = wallColor
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    final baseFillPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final roomTextStyle = TextStyle(
      color: textColor,
      fontSize: 14,
      fontFamily: GoogleFonts.outfit().fontFamily,
    );

    final baseTextStyle = TextStyle(
      color: textColor,
      fontSize: 16,
      fontFamily: GoogleFonts.outfit().fontFamily,
    );

    // Draw base if present
    if (floorBase != null) {
      // print("Drawing base: $floorBase"); // Debug print
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
            ..color = wallColor
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
          minWidth: 0,
          maxWidth: room.width * adjustedScaleFactor,
        );
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

      // Draw spaces for rooms (add before doors and windows)
      for (Room room in rooms) {
        final roomWidthInPixels =
            double.parse((room.width * adjustedScaleFactor).toStringAsFixed(2));
        final roomHeightInPixels = double.parse(
            (room.height * adjustedScaleFactor).toStringAsFixed(2));

        final roomLeft = baseLeft + (room.position.dx * adjustedScaleFactor);
        final roomTop = baseTop + (room.position.dy * adjustedScaleFactor);

        _drawSpaces(canvas, room, roomLeft, roomTop, roomWidthInPixels,
            roomHeightInPixels, adjustedScaleFactor);
      }

      // After drawing rooms and before drawing doors, add window drawing
      for (Room room in rooms) {
        _drawWindowsForRoom(
            canvas, room, baseLeft, baseTop, adjustedScaleFactor);
      }

      // After drawing rooms but before drawing their dimensions, draw the doors
      if (floorBase != null) {
        for (Room room in rooms) {
          _drawDoorsForRoom(
              canvas, room, baseLeft, baseTop, adjustedScaleFactor);
        }
      }

      // Draw base dimensions
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
        ..color = wallColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawRect(stairRect, stairPaint);

      // Draw step lines
      final stepPaint = Paint()
        ..color = wallColor
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
        ..color = isDarkMode ? Colors.white70 : Colors.black54
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

      // Add stair number label
      final stairTextStyle = TextStyle(
        color: textColor,
        fontSize: 14 * zoomLevel,
        fontWeight: FontWeight.w500,
        fontFamily: GoogleFonts.outfit().fontFamily,
      );

      final stairText = "Stairs ${stair.name.substring(stair.name.length - 1)}";
      final stairTextSpan = TextSpan(
        text: stairText,
        style: stairTextStyle,
      );

      final stairTextPainter = TextPainter(
        text: stairTextSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      stairTextPainter.layout();

      // Position the text in the center of the stairs
      final textX = stairLeft +
          (stair.width * adjustedScaleFactor - stairTextPainter.width) / 2;
      final textY = stairTop +
          (stair.length * adjustedScaleFactor - stairTextPainter.height) / 2;

      // Draw a background for better readability
      final textBackground = Paint()
        ..color = backgroundColor.withOpacity(0.8)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(
          textX - 4,
          textY - 2,
          stairTextPainter.width + 8,
          stairTextPainter.height + 4,
        ),
        textBackground,
      );

      stairTextPainter.paint(
        canvas,
        Offset(textX, textY),
      );

      // Continue with existing highlight code
      if (selectedStairs == stair) {
        final highlightPaint = Paint()
          ..color = isDarkMode ? Colors.lightBlueAccent : Colors.blue
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;

        canvas.drawRect(stairRect, highlightPaint);
      }
    }

    // Draw cutouts
    for (CutOut cutOut in cutOuts) {
      final baseWidthInPixels = floorBase!.width * adjustedScaleFactor;
      final baseHeightInPixels = floorBase!.height * adjustedScaleFactor;

      final baseLeft = screenCenterX - (baseWidthInPixels / 2);
      final baseTop = screenCenterY - (baseHeightInPixels / 2);

      final cutOutWidthInPixels = cutOut.width * adjustedScaleFactor;
      final cutOutHeightInPixels = cutOut.height * adjustedScaleFactor;

      final cutOutLeft = baseLeft + (cutOut.position.dx * adjustedScaleFactor);
      final cutOutTop = baseTop + (cutOut.position.dy * adjustedScaleFactor);

      final cutOutRect = Rect.fromLTWH(
        cutOutLeft,
        cutOutTop,
        cutOutWidthInPixels,
        cutOutHeightInPixels,
      );

      // Draw cutout outline
      final cutOutPaint = Paint()
        ..color = cutOut == selectedCutOut
            ? (isDarkMode ? Colors.redAccent : Colors.red)
            : wallColor
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      canvas.drawRect(cutOutRect, cutOutPaint);

      // Draw spaces for cutouts (add before doors and windows)
      for (CutOut cutout in cutOuts) {
        final cutOutWidthInPixels = cutout.width * adjustedScaleFactor;
        final cutOutHeightInPixels = cutout.height * adjustedScaleFactor;

        final cutOutLeft =
            baseLeft + (cutout.position.dx * adjustedScaleFactor);
        final cutOutTop = baseTop + (cutout.position.dy * adjustedScaleFactor);

        _drawSpaces(canvas, cutout, cutOutLeft, cutOutTop, cutOutWidthInPixels,
            cutOutHeightInPixels, adjustedScaleFactor);
      }

      for (CutOut cutout in cutOuts) {
        _drawWindowsForCutout(
            canvas, cutout, baseLeft, baseTop, adjustedScaleFactor);
      }

      if (floorBase != null) {
        for (CutOut cutout in cutOuts) {
          _drawDoorsForCutout(
              canvas, cutout, baseLeft, baseTop, adjustedScaleFactor);
        }
      }
      final cutOutTextStyle = TextStyle(
        color: textColor.withOpacity(0.4),
        fontSize: 16,
        fontFamily: GoogleFonts.outfit().fontFamily,
      );
      // Draw cutout label
      final cutOutText =
          "${cutOut.name}\n${cutOut.width}ft x ${cutOut.height}ft";
      final cutOutTextSpan = TextSpan(text: cutOutText, style: cutOutTextStyle);
      final cutOutTextPainter = TextPainter(
        text: cutOutTextSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      cutOutTextPainter.layout(
        minWidth: 0,
        maxWidth: cutOutWidthInPixels,
      );

      cutOutTextPainter.paint(
        canvas,
        Offset(
          cutOutLeft + (cutOutWidthInPixels - cutOutTextPainter.width) / 2,
          cutOutTop + (cutOutHeightInPixels - cutOutTextPainter.height) / 2,
        ),
      );
    }
  }

  void _drawDoorsForRoom(Canvas canvas, Room room, double baseLeft,
      double baseTop, double scaleFactor) {
    for (Door door in room.doors) {
      final doorPaint = Paint()
        ..color = door == selectedDoor
            ? (isDarkMode ? Colors.greenAccent : Colors.green)
            : (door.isHighlighted
                ? (isDarkMode ? Colors.lightBlueAccent : Colors.blue)
                : wallColor)
        ..strokeWidth = (door == selectedDoor || door.isHighlighted)
            ? room.roomPaint.strokeWidth - 1
            : room.roomPaint.strokeWidth - 1.5
        ..style = PaintingStyle.stroke;

      // Convert room position to screen coordinates
      final roomLeft = baseLeft + (room.position.dx * scaleFactor);
      final roomTop = baseTop + (room.position.dy * scaleFactor);
      final roomRight = roomLeft + (room.width * scaleFactor);
      final roomBottom = roomTop + (room.height * scaleFactor);

      // Calculate door length
      double doorLength;
      if (door.width != Door.defaultWidth) {
        // If door has been resized, use its actual width
        doorLength = door.width * scaleFactor;
      } else {
        // Use the default 1/3 calculation for unmodified doors
        switch (door.wall) {
          case "north":
          case "south":
          case "up":
          case "down":
            doorLength = (room.width * scaleFactor) / 3;
            break;
          case "east":
          case "west":
          case "left":
          case "right":
            doorLength = (room.height * scaleFactor) / 3;
            break;
          default:
            doorLength = Door.defaultWidth * scaleFactor;
        }
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
        ..color = backgroundColor
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
            ? (isDarkMode ? Colors.yellowAccent : Colors.yellow)
            : (window.isHighlighted
                ? (isDarkMode ? Colors.lightBlueAccent : Colors.blue)
                : wallColor)
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
      if (window.width != Window.defaultWidth) {
        // If window has been resized, use its actual width
        windowLength = window.width * scaleFactor;
      } else {
        // Use the default calculation for unmodified windows
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
        ..color = backgroundColor
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

  void _drawSpaces(
    Canvas canvas,
    dynamic parent,
    double left,
    double top,
    double widthInPixels,
    double heightInPixels,
    double adjustedScaleFactor,
  ) {
    final right = left + widthInPixels;
    final bottom = top + heightInPixels;

    for (Space space in parent.spaces) {
      // Calculate space length based on whether it's been resized or not
      double spaceLength;
      if (space.width != Space.defaultWidth) {
        // If space has been resized, use its actual width
        spaceLength = space.width * adjustedScaleFactor;
      } else {
        // Use the default calculation for unmodified spaces
        switch (space.wall) {
          case "north":
          case "south":
          case "up":
          case "down":
            spaceLength = widthInPixels / 3; // 1/3 of parent width
            break;
          case "east":
          case "west":
          case "left":
          case "right":
            spaceLength = heightInPixels / 3; // 1/3 of parent height
            break;
          default:
            spaceLength = Space.defaultWidth * adjustedScaleFactor;
        }
      }

      double spaceStart;
      Offset gapStart;
      Offset gapEnd;
      Rect spaceFrame;
      const frameThickness = 3.0;

      final spacePaint = Paint()
        ..color = space == selectedSpace
            ? (isDarkMode ? Colors.yellowAccent : Colors.yellow)
            : (space.isHighlighted
                ? Colors.red
                : (isDarkMode ? const Color(0x001a1b26) : Colors.white70))
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      switch (space.wall) {
        case "north":
        case "up":
          spaceStart = left + (space.offsetFromWallStart * adjustedScaleFactor);
          gapStart = Offset(spaceStart, top);
          gapEnd = Offset(spaceStart + spaceLength, top);
          spaceFrame = Rect.fromLTWH(
            spaceStart,
            top - frameThickness / 2,
            spaceLength,
            frameThickness,
          );
          break;

        case "south":
        case "down":
          spaceStart = left + (space.offsetFromWallStart * adjustedScaleFactor);
          gapStart = Offset(spaceStart, bottom);
          gapEnd = Offset(spaceStart + spaceLength, bottom);
          spaceFrame = Rect.fromLTWH(
            spaceStart,
            bottom - frameThickness / 2,
            spaceLength,
            frameThickness,
          );
          break;

        case "east":
        case "right":
          spaceStart = top + (space.offsetFromWallStart * adjustedScaleFactor);
          gapStart = Offset(right, spaceStart);
          gapEnd = Offset(right, spaceStart + spaceLength);
          spaceFrame = Rect.fromLTWH(
            right - frameThickness / 2,
            spaceStart,
            frameThickness,
            spaceLength,
          );
          break;

        case "west":
        case "left":
          spaceStart = top + (space.offsetFromWallStart * adjustedScaleFactor);
          gapStart = Offset(left, spaceStart);
          gapEnd = Offset(left, spaceStart + spaceLength);
          spaceFrame = Rect.fromLTWH(
            left - frameThickness / 2,
            spaceStart,
            frameThickness,
            spaceLength,
          );
          break;

        default:
          continue;
      }

      // Draw space gap (erase part of the wall)
      final gapPaint = Paint()
        ..color = backgroundColor
        ..strokeWidth = spacePaint.strokeWidth + 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(gapStart, gapEnd, gapPaint);

      // Draw space frame
      canvas.drawRect(spaceFrame, spacePaint);

      // Draw connecting space indicator if this is a connecting space
      if (space.connectedSpace != null) {
        final centerStart = Offset(
          (gapStart.dx + gapEnd.dx) / 2,
          (gapStart.dy + gapEnd.dy) / 2,
        );
        final connectingDotPaint = Paint()
          ..color = isDarkMode ? const Color(0x001a1b26) : Colors.white70
          ..style = PaintingStyle.fill;
        canvas.drawCircle(centerStart, 2, connectingDotPaint);
      }
    }
  }

  void _drawDoorsForCutout(Canvas canvas, CutOut cutOut, double baseLeft,
      double baseTop, double scaleFactor) {
    for (Door door in cutOut.doors) {
      final doorPaint = Paint()
        ..color = door == selectedDoor
            ? (isDarkMode ? Colors.greenAccent : Colors.green)
            : (door.isHighlighted
                ? (isDarkMode ? Colors.lightBlueAccent : Colors.blue)
                : wallColor)
        ..strokeWidth = (door == selectedDoor || door.isHighlighted)
            ? cutOut.cutOutPaint.strokeWidth - 1
            : cutOut.cutOutPaint.strokeWidth - 1.5
        ..style = PaintingStyle.stroke;

      // Convert room position to screen coordinates
      final cutOutLeft = baseLeft + (cutOut.position.dx * scaleFactor);
      final cutOutTop = baseTop + (cutOut.position.dy * scaleFactor);
      final cutOutRight = cutOutLeft + (cutOut.width * scaleFactor);
      final cutOutBottom = cutOutTop + (cutOut.height * scaleFactor);

      // Calculate door length
      double doorLength;
      if (door.width != Door.defaultWidth) {
        // If door has been resized, use its actual width
        doorLength = door.width * scaleFactor;
      } else {
        // Use the default 1/3 calculation for unmodified doors
        switch (door.wall) {
          case "north":
          case "south":
          case "up":
          case "down":
            doorLength = (cutOut.width * scaleFactor) / 3;
            break;
          case "east":
          case "west":
          case "left":
          case "right":
            doorLength = (cutOut.height * scaleFactor) / 3;
            break;
          default:
            doorLength = Door.defaultWidth * scaleFactor;
        }
      }

      // Calculate door position and dimensions
      double doorStart;
      Offset gapStart, gapEnd;
      Offset doorLineStart, doorLineEnd;

      switch (door.wall) {
        case "north":
        case "up":
          doorStart = cutOutLeft + (door.offsetFromWallStart * scaleFactor);
          gapStart = Offset(doorStart, cutOutTop);
          gapEnd = Offset(doorStart + doorLength, cutOutTop);
          doorLineStart = door.openLeft ? gapStart : gapEnd;
          doorLineEnd = Offset(
              doorLineStart.dx,
              door.swingInward
                  ? cutOutTop + doorLength
                  : cutOutTop - doorLength);
          break;

        case "south":
        case "down":
          doorStart = cutOutLeft + (door.offsetFromWallStart * scaleFactor);
          gapStart = Offset(doorStart, cutOutBottom);
          gapEnd = Offset(doorStart + doorLength, cutOutBottom);
          doorLineStart = door.openLeft ? gapStart : gapEnd;
          doorLineEnd = Offset(
              doorLineStart.dx,
              door.swingInward
                  ? cutOutBottom - doorLength
                  : cutOutBottom + doorLength);
          break;

        case "east":
        case "right":
          doorStart = cutOutTop + (door.offsetFromWallStart * scaleFactor);
          gapStart = Offset(cutOutRight, doorStart);
          gapEnd = Offset(cutOutRight, doorStart + doorLength);
          doorLineStart = door.openLeft ? gapStart : gapEnd;
          doorLineEnd = Offset(
              door.swingInward
                  ? cutOutRight - doorLength
                  : cutOutRight + doorLength,
              doorLineStart.dy);
          break;

        case "west":
        case "left":
          doorStart = cutOutTop + (door.offsetFromWallStart * scaleFactor);
          gapStart = Offset(cutOutLeft, doorStart);
          gapEnd = Offset(cutOutLeft, doorStart + doorLength);
          doorLineStart = door.openLeft ? gapStart : gapEnd;
          doorLineEnd = Offset(
              door.swingInward
                  ? cutOutLeft + doorLength
                  : cutOutLeft - doorLength,
              doorLineStart.dy);
          break;

        default:
          continue;
      }

      // Draw door gap (erase part of the wall)
      final gapPaint = Paint()
        ..color = backgroundColor
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

  void _drawWindowsForCutout(Canvas canvas, CutOut cutOut, double baseLeft,
      double baseTop, double scaleFactor) {
    for (Window window in cutOut.windows) {
      final windowPaint = Paint()
        ..color = window == selectedWindow
            ? (isDarkMode ? Colors.yellowAccent : Colors.yellow)
            : (window.isHighlighted
                ? (isDarkMode ? Colors.lightBlueAccent : Colors.blue)
                : wallColor)
        ..strokeWidth =
            cutOut.cutOutPaint.strokeWidth * 0.25 // Match room's stroke width
        ..style = PaintingStyle.stroke;

      // Convert room position to screen coordinates
      final cutOutLeft = baseLeft + (cutOut.position.dx * scaleFactor);
      final cutOutTop = baseTop + (cutOut.position.dy * scaleFactor);
      final cutOutRight = cutOutLeft + (cutOut.width * scaleFactor);
      final cutOutBottom = cutOutTop + (cutOut.height * scaleFactor);

      // Calculate window length (1/3 of wall length)
      double windowLength;
      if (window.width != Window.defaultWidth) {
        // If window has been resized, use its actual width
        windowLength = window.width * scaleFactor;
      } else {
        // Use the default calculation for unmodified windows
        switch (window.wall) {
          case "north":
          case "south":
          case "up":
          case "down":
            windowLength = (cutOut.width * scaleFactor) / 3;
            break;
          case "east":
          case "west":
          case "left":
          case "right":
            windowLength = (cutOut.height * scaleFactor) / 3;
            break;
          default:
            windowLength = Window.defaultWidth * scaleFactor;
        }
      }

      // Calculate window frame points
      double windowStart;
      Offset gapStart, gapEnd;
      Rect windowFrame;
      final frameThickness = cutOut.cutOutPaint.strokeWidth; // Frame thickness

      switch (window.wall) {
        case "north":
        case "up":
          windowStart = cutOutLeft + (window.offsetFromWallStart * scaleFactor);
          gapStart = Offset(windowStart, cutOutTop);
          gapEnd = Offset(windowStart + windowLength, cutOutTop);
          windowFrame = Rect.fromLTWH(
              windowStart, // Align with gap start
              cutOutTop - frameThickness / 2, // Center on wall
              windowLength, // Match gap length
              frameThickness);
          break;

        case "south":
        case "down":
          windowStart = cutOutLeft + (window.offsetFromWallStart * scaleFactor);
          gapStart = Offset(windowStart, cutOutBottom);
          gapEnd = Offset(windowStart + windowLength, cutOutBottom);
          windowFrame = Rect.fromLTWH(
              windowStart, // Align with gap start
              cutOutBottom - frameThickness / 2, // Center on wall
              windowLength, // Match gap length
              frameThickness);
          break;

        case "east":
        case "right":
          windowStart = cutOutTop + (window.offsetFromWallStart * scaleFactor);
          gapStart = Offset(cutOutRight, windowStart);
          gapEnd = Offset(cutOutRight, windowStart + windowLength);
          windowFrame = Rect.fromLTWH(
              cutOutRight - frameThickness / 2, // Center on wall
              windowStart, // Align with gap start
              frameThickness,
              windowLength // Match gap length
              );
          break;

        case "west":
        case "left":
          windowStart = cutOutTop + (window.offsetFromWallStart * scaleFactor);
          gapStart = Offset(cutOutLeft, windowStart);
          gapEnd = Offset(cutOutLeft, windowStart + windowLength);
          windowFrame = Rect.fromLTWH(
              cutOutLeft - frameThickness / 2, // Center on wall
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
        ..color = backgroundColor
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
  bool shouldRepaint(FloorPlanPainter oldDelegate) {
    return true;
  }
}
