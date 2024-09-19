import 'dart:ui';

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
      ..color = Colors.black12
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final basePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    final baseFillPaint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.fill;

    if (rooms.isNotEmpty) {
      for (Room room in rooms) {
        Rect rect = Rect.fromLTWH(room.position.dx, room.position.dy,
            room.width * 10, room.height * 10);
        canvas.drawRect(rect, roomPaint);
      }
    }

    if (floorBase != null) {
      final baseWidthInPixels = floorBase!.width * 10;
      final baseHeightInPixels = floorBase!.height * 10;

      // ParagraphStyle baseParagraphStyle = ParagraphStyle(fontSize: 18);
      TextStyle textStyle = const TextStyle(color: Colors.black, fontSize: 16);
      // ParagraphBuilder baseParagraphBuilder =
      //     ParagraphBuilder(baseParagraphStyle);
      // baseParagraphBuilder
      //     .addText("Base\n${floorBase!.width}ft x ${floorBase!.height}ft");
      // Paragraph baseParagraph = baseParagraphBuilder.build();
      // baseParagraph.layout(ParagraphConstraints(width: size.width));

      // canvas.drawParagraph(
      //     baseParagraph,
      //     Offset(
      //         screenCenterX, screenCenterY - (baseHeightInPixels / 2)));

      // Create a TextPainter for "Base"
      final baseTextPainter = TextPainter(
        text: TextSpan(text: "Base", style: textStyle),
        textDirection: TextDirection.ltr,
      );
      baseTextPainter.layout();

      // Create a TextPainter for the base dimensions (e.g., "300 x 200")
      final dimensionsTextPainter = TextPainter(
        text: TextSpan(
            text: "${floorBase!.width} x ${floorBase!.height}",
            style: textStyle),
        textDirection: TextDirection.ltr,
      );
      dimensionsTextPainter.layout();

      // Position the text above the rectangle's top boundary
      double textX = floorBase!.position.dx +
          (floorBase!.width - baseTextPainter.width) / 2;
      double textY = floorBase!.position.dy -
          baseTextPainter.height -
          dimensionsTextPainter.height -
          10; // Small padding above the base

      // Draw the "Base" text
      baseTextPainter.paint(canvas, Offset(textX, textY));

      // Draw the dimensions text below "Base"
      dimensionsTextPainter.paint(
          canvas, Offset(textX, textY + baseTextPainter.height));

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
    }
  }

  @override
  bool shouldRepaint(FloorPlanPainter oldDelegate) => true;
}
