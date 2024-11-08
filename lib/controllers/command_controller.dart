import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:saysketch_v2/controllers/floor_manager_controller.dart';
import 'package:saysketch_v2/controllers/floor_plan_controller.dart';
import 'package:saysketch_v2/models/room_model.dart';
import 'package:saysketch_v2/services/message_service.dart';

import '../models/door.dart';

class CommandController {
  final FloorManagerController floorManagerController;
  Room? selectedRoom;

  CommandController(this.floorManagerController);

  FloorPlanController? get floorPlanController =>
      floorManagerController.getActiveController();

  void handleCommand(String command, BuildContext context) {
    // Convert command to lowercase for easier comparison
    command = command.toLowerCase();
    List<String> tokens = command.split(" ");

    if ((tokens.contains("new") || tokens.contains("add")) &&
        (tokens.contains("floor") ||
            tokens.contains("flower") ||
            tokens.contains("flour"))) {
      floorManagerController.addNewFloor();
      return;
    }

    // Switch floor command handling
    if (tokens.contains("switch") || tokens.contains("go")) {
      if (tokens.contains("floor") ||
          tokens.contains("flower") ||
          tokens.contains("flour")) {
        for (int i = 0; i < tokens.length; i++) {
          try {
            int floorNum = int.parse(tokens[i]);
            if (floorNum <= 0) {
              MessageService.showMessage(floorManagerController.context,
                  "Floor number must be 1 or greater",
                  type: MessageType.error);
              return;
            }
            floorManagerController.switchToFloor(floorNum - 1);
            return;
          } catch (e) {
            continue;
          }
        }
        MessageService.showMessage(
            floorManagerController.context, "Please specify floor number",
            type: MessageType.error);
        return;
      }
    }

    // Get the active floor's controller for other commands
    if (floorPlanController == null) {
      MessageService.showMessage(
          floorManagerController.context, "No active floor",
          type: MessageType.error);
      return;
    }

    print("Recognized command: $command"); // Debug print

    if (tokens.contains("resize") ||
        tokens.contains("change") ||
        (tokens.contains("increase") &&
            (tokens.contains("size") ||
                tokens.contains("width") ||
                tokens.contains("height"))) ||
        (tokens.contains("decrease") &&
            (tokens.contains("size") ||
                tokens.contains("width") ||
                tokens.contains("height")))) {
      _handleResizeCommand(tokens);
    } else if (tokens.contains("remove") || tokens.contains("delete")) {
      _handleRemoveCommand(tokens);
    } else if (tokens.contains("hide")) {
      _handleHideCommand(tokens);
    } else if (tokens.contains("show")) {
      _handleShowCommand(tokens);
    }
    // Handle base creation commands
    else if (tokens.contains("base") || tokens.contains("bass")) {
      _handleBaseCommand(command, tokens);
    } else if (tokens.contains("select")) {
      if (tokens.contains("stairs")) {
        _handleSelectStairsCommand(tokens);
      } else {
        _handleSelectCommand(tokens);
      }
    } else if (tokens.contains("deselect")) {
      selectedRoom = null;
      floorPlanController?.deselectRoom();
      floorPlanController?.deselectStairs();
    } else if (tokens.contains("rename")) {
      _handleRenameCommand(tokens);
    } else if (tokens.contains("move")) {
      _handleMoveCommand(tokens, context);
    } else if (tokens.contains("rotate")) {
      _handleRotateCommand();
    }
    // Handle room commands
    else if (tokens.contains("room") ||
        tokens.contains("rooms") ||
        tokens.contains("dhoom") ||
        tokens.contains("dhooms")) {
      _handleRoomCommand(command, tokens);
    } else if (tokens.contains("stairs")) {
      _handleStairsCommand(command, tokens);
    }
    // Add zoom command handling
    else if (tokens.contains("zoom")) {
      _handleZoomCommand(tokens);
      return;
    } else if (tokens.contains("door") || tokens.contains("doors")) {
      _handleDoorCommand(command, tokens);
      return;
    } else {
      Fluttertoast.showToast(msg: "Invalid Command: $command");
    }
  }

  void _handleHideCommand(List<String> tokens) {
    if (selectedRoom != null) {
      if (tokens.contains("wall") ||
          tokens.contains("walls") ||
          tokens.contains("boundary") ||
          tokens.contains("boundaries")) {
        floorPlanController?.hideWalls();
      } else {
        MessageService.showMessage(
            floorManagerController.context, "Please specify what to hide.",
            type: MessageType.error);
      }
    } else {
      MessageService.showMessage(
          floorManagerController.context, "Please select a room first.",
          type: MessageType.error);
    }
  }

  void _handleShowCommand(List<String> tokens) {
    if (selectedRoom != null) {
      if (tokens.contains("wall") ||
          tokens.contains("walls") ||
          tokens.contains("boundary") ||
          tokens.contains("boundaries")) {
        floorPlanController?.showWalls();
      } else {
        MessageService.showMessage(
            floorManagerController.context, "Please specify what to show.",
            type: MessageType.error);
      }
    } else {
      MessageService.showMessage(
          floorManagerController.context, "Please select a room first.",
          type: MessageType.error);
    }
  }

  void _handleRemoveCommand(List<String> tokens) {
    if (selectedRoom != null) {
      if (tokens.contains("wall") ||
          tokens.contains("walls") ||
          tokens.contains("boundary") ||
          tokens.contains("boundaries")) {
        selectedRoom!.roomPaint.color = Colors.transparent;
      } else {
        MessageService.showMessage(
            floorManagerController.context, "'${selectedRoom!.name}' removed.",
            type: MessageType.success);
        floorPlanController?.removeSelectedRoom();
        selectedRoom = null;
      }
    } else if (floorPlanController?.selectedStairs != null) {
      MessageService.showMessage(floorManagerController.context,
          "'${floorPlanController?.selectedStairs!.name}' removed.",
          type: MessageType.success);
      floorPlanController?.removeSelectedStairs();
    } else {
      if (tokens.contains("base") || tokens.contains("bass")) {
        floorPlanController?.removeBase();
        MessageService.showMessage(
            floorManagerController.context, "Base removed",
            type: MessageType.success);
      } else if (tokens.contains("rooms") || tokens.contains("all")) {
        floorPlanController?.removeAllRooms();
        MessageService.showMessage(
            floorManagerController.context, "All rooms removed",
            type: MessageType.success);
      } else if (tokens.contains("last") &&
          (tokens.contains("room") || tokens.contains("rooms"))) {
        floorPlanController?.removeLastAddedRoom();
        MessageService.showMessage(
            floorManagerController.context, "Last room removed",
            type: MessageType.success);
      } else {
        MessageService.showMessage(floorManagerController.context,
            "Please specify what to remove (base, rooms, or last room)",
            type: MessageType.error);
      }
    }
  }

  void _handleRotateCommand() {
    if (floorPlanController?.selectedStairs != null) {
      floorPlanController?.rotateStairs();
    } else {
      MessageService.showMessage(
          floorManagerController.context, "Select stairs first.",
          type: MessageType.error);
    }
  }

  void _handleSelectCommand(List<String> tokens) {
    if (tokens.length == 1) {
      MessageService.showMessage(floorManagerController.context,
          "Please specify the room name to select that room.",
          type: MessageType.error);
      return;
    }

    selectedRoom = null;
    String roomName = tokens.sublist(1).join(" ");
    selectedRoom = floorPlanController?.selectRoom(roomName.trim());
  }

  void _handleRenameCommand(List<String> tokens) {
    if (tokens.length == 1) {
      if (selectedRoom == null) {
        MessageService.showMessage(
            floorManagerController.context, "Please select a room first.",
            type: MessageType.error);
      } else {
        MessageService.showMessage(floorManagerController.context,
            "Please specify the new name for the selected room.",
            type: MessageType.error);
      }
      return;
    }

    if (selectedRoom != null) {
      List<String> nameTokens;
      if (tokens.contains("to")) {
        nameTokens = tokens.sublist(tokens.indexOf("to") + 1);
      } else {
        nameTokens = tokens.sublist(1);
      }
      String newName = nameTokens.join(" ");
      floorPlanController?.renameRoom(newName.trim());
      floorPlanController?.deselectRoom();
    } else {
      MessageService.showMessage(
          floorManagerController.context, "Please select a room first.",
          type: MessageType.error);
    }
  }

  void _handleMoveCommand(List<String> tokens, BuildContext context) {
    if (floorPlanController?.selectedStairs != null) {
      // Handle stairs movement
      if (tokens.contains("to")) {
        // Handle predefined positions for stairs
        for (String position in [
          "center",
          "topleft",
          "topright",
          "bottomleft",
          "bottomright",
        ]) {
          if (tokens.contains(position)) {
            floorPlanController?.moveStairsToPosition(position);
            return;
          }
        }

        // Handle relative positioning to rooms or other stairs
        int referenceRoomIndex = _findReferenceRoomIndex(
            tokens, floorPlanController?.getRooms() ?? []);
        int referenceStairsIndex = _findReferenceStairsIndex(tokens);

        if (referenceRoomIndex != -1 || referenceStairsIndex != -1) {
          for (String direction in [
            "right",
            "left",
            "above",
            "below",
            "north",
            "south",
            "east",
            "west"
          ]) {
            if (tokens.contains(direction)) {
              if (referenceRoomIndex != -1) {
                floorPlanController?.moveStairsRelativeToRoom(
                    referenceRoomIndex, direction);
              } else {
                floorPlanController?.moveStairsRelativeToOther(
                    referenceStairsIndex, direction);
              }
              return;
            }
          }
        }
      }

      // Rest of stairs movement handling...
      double? distance = _extractDistance(tokens);
      if (distance != null) {
        for (String direction in [
          "right",
          "left",
          "up",
          "down",
          "north",
          "south",
          "east",
          "west"
        ]) {
          if (tokens.contains(direction)) {
            floorPlanController?.moveStairsRelative(distance, direction);
            return;
          }
        }
      }

      // Handle absolute coordinates for stairs...
      try {
        int xIndex = tokens.indexOf("x");
        int yIndex = tokens.indexOf("y");

        if (xIndex != -1 &&
            yIndex != -1 &&
            xIndex + 1 < tokens.length &&
            yIndex + 1 < tokens.length) {
          double x = double.parse(tokens[xIndex + 1]);
          double y = double.parse(tokens[yIndex + 1]);
          floorPlanController?.moveStairs(x, y);
          return;
        }
      } catch (e) {
        // Handle parsing errors
      }

      MessageService.showMessage(floorManagerController.context,
          "Invalid stairs move command. Try: 'move stairs to center', 'move stairs 5 feet right', 'move stairs to the right of bedroom', 'move stairs to the left of stairs 1'",
          type: MessageType.error);
    } else if (selectedRoom != null) {
      // Handle room movement
      if (tokens.contains("to")) {
        // Handle predefined positions for rooms
        for (String position in [
          "center",
          "topleft",
          "topright",
          "bottomleft",
          "bottomright"
        ]) {
          if (tokens.contains(position)) {
            floorPlanController?.moveRoomToPosition(position, context);
            return;
          }
        }

        // Handle relative positioning to rooms or stairs
        int referenceRoomIndex = _findReferenceRoomIndex(
            tokens, floorPlanController?.getRooms() ?? []);
        int referenceStairsIndex = _findReferenceStairsIndex(tokens);

        if (referenceRoomIndex != -1 || referenceStairsIndex != -1) {
          for (String direction in [
            "right",
            "left",
            "above",
            "below",
            "north",
            "south",
            "east",
            "west"
          ]) {
            if (tokens.contains(direction)) {
              if (referenceRoomIndex != -1) {
                floorPlanController?.moveRoomRelativeToOther(
                    referenceRoomIndex, direction);
              } else {
                floorPlanController?.moveRoomRelativeToStairs(
                    referenceStairsIndex, direction);
              }
              return;
            }
          }
        }
      }

      // Rest of room movement handling...
      double? distance = _extractDistance(tokens);
      if (distance != null) {
        for (String direction in [
          "right",
          "left",
          "up",
          "down",
          "north",
          "south",
          "east",
          "west"
        ]) {
          if (tokens.contains(direction)) {
            floorPlanController?.moveRoomRelative(distance, direction);
            return;
          }
        }
      }

      // Handle absolute coordinates for rooms...
      try {
        int xIndex = tokens.indexOf("x");
        int yIndex = tokens.indexOf("y");

        if (xIndex != -1 &&
            yIndex != -1 &&
            xIndex + 1 < tokens.length &&
            yIndex + 1 < tokens.length) {
          double x = double.parse(tokens[xIndex + 1]);
          double y = double.parse(tokens[yIndex + 1]);
          floorPlanController?.moveRoom(x, y);
          return;
        }
      } catch (e) {
        // Handle parsing errors
      }

      MessageService.showMessage(floorManagerController.context,
          "Invalid room move command. Try: 'move to center', 'move 5 feet right', 'move to the right of bedroom', 'move to the left of stairs 1'",
          type: MessageType.error);
    } else {
      MessageService.showMessage(floorManagerController.context,
          "Please select a room or stairs first.",
          type: MessageType.error);
    }
  }

  void _handleBaseCommand(String command, List<String> tokens) {
    if (tokens.contains("by") || tokens.contains("/")) {
      Map<String, double> dimensions = extractMeasurements(command);
      if (dimensions.isNotEmpty) {
        floorPlanController?.setBase(
          dimensions['width']!,
          dimensions['height']!,
          const Offset(100, 100),
        );
        MessageService.showMessage(floorManagerController.context,
            "Base created with custom dimensions",
            type: MessageType.success);
      } else {
        MessageService.showMessage(
            floorManagerController.context, "Could not understand dimensions",
            type: MessageType.error);
      }
    } else {
      floorPlanController?.setDefaultBase();
      MessageService.showMessage(
          floorManagerController.context, "Default base created",
          type: MessageType.success);
    }
  }

  void _handleRoomCommand(String command, List<String> tokens) {
    if (floorPlanController?.getBase() == null) {
      MessageService.showMessage(
          floorManagerController.context, "Please create a base first",
          type: MessageType.error);
      return;
    }

    // Handle relative positioning commands
    if (tokens.contains("below") ||
        tokens.contains("above") ||
        tokens.contains("right") ||
        tokens.contains("left")) {
      _handleRelativeRoomCommand(command, tokens);
      return;
    }

    // Handle room with specific dimensions
    if (tokens.contains("by") || tokens.contains("/")) {
      Map<String, double> dimensions = extractMeasurements(command);
      if (dimensions.isNotEmpty) {
        floorPlanController?.addNextRoomWithDimensions(
            width: dimensions['width']!, height: dimensions['height']!);
        MessageService.showMessage(
            floorManagerController.context, "Added room with custom dimensions",
            type: MessageType.success);
      } else {
        MessageService.showMessage(floorManagerController.context,
            "Could not understand room dimensions",
            type: MessageType.error);
      }
    }
    // Handle "another room" or "next room" or "add room" commands
    else if (tokens.contains("another") ||
        tokens.contains("next") ||
        (tokens.contains("add") && tokens.contains("room"))) {
      floorPlanController?.addNextRoom();
      MessageService.showMessage(
          floorManagerController.context, "Added new room",
          type: MessageType.success);
    }
    // Handle default room command
    else if (tokens.contains("room") || tokens.contains("rooms")) {
      floorPlanController?.addDefaultRoom();
      MessageService.showMessage(
          floorManagerController.context, "Added default room",
          type: MessageType.success);
    }
  }

  void _handleRelativeRoomCommand(String command, List<String> tokens) {
    // Extract reference room number
    int? referenceRoomIndex;
    String? position;

    // Find the position word (below/above/right/left)
    for (String pos in ['below', 'above', 'right', 'left']) {
      if (tokens.contains(pos)) {
        position = pos;
        break;
      }
    }

    // Find room number
    referenceRoomIndex =
        _findReferenceRoomIndex(tokens, floorPlanController?.getRooms() ?? []);

    if (position == null) {
      MessageService.showMessage(floorManagerController.context,
          "Please specify a valid room number and position",
          type: MessageType.error);
      return;
    }

    // Handle dimensions
    if (tokens.contains("by") || tokens.contains("/")) {
      Map<String, double> dimensions = extractMeasurements(command);
      if (dimensions.isNotEmpty) {
        floorPlanController?.addRoomRelativeTo(dimensions['width']!,
            dimensions['height']!, referenceRoomIndex, position);
        MessageService.showMessage(floorManagerController.context,
            "Added room $position room ${referenceRoomIndex + 1}",
            type: MessageType.success);
      } else {
        MessageService.showMessage(floorManagerController.context,
            "Could not understand room dimensions",
            type: MessageType.error);
      }
    } else {
      // Use default dimensions
      floorPlanController?.addRoomRelativeTo(
          10, 10, referenceRoomIndex, position);
      MessageService.showMessage(floorManagerController.context,
          "Added default room $position room ${referenceRoomIndex + 1}",
          type: MessageType.success);
    }
  }

  double? _extractDistance(List<String> tokens) {
    for (int i = 0; i < tokens.length - 1; i++) {
      try {
        double value = double.parse(tokens[i]);
        String unit = tokens[i + 1];
        return floorPlanController?.convertToMetricUnits(value, unit);
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  int _findReferenceRoomIndex(List<String> tokens, List<Room> rooms) {
    // Helper function to check if a token matches a room name
    bool isMatchingRoom(String token, Room room) {
      String roomName = room.name;

      // Check for different possible formats:
      // 1. Direct name match (e.g., "bedroom" matches room named "bedroom")
      // 2. "room N" format (e.g., "room 1" matches first room)
      // 3. "roomN" format (e.g., "room1" matches first room)

      if (roomName == token) {
        return true;
      }

      // Handle original numbered room formats
      if (token.startsWith("room")) {
        String numStr = token.substring(4).trim();
        try {
          int roomNum = int.parse(numStr);
          return roomNum - 1 == rooms.indexOf(room);
        } catch (e) {
          return false;
        }
      }

      // Handle "room N" format
      if (token == "room") {
        return false; // Skip the word "room" alone
      }

      return false;
    }

    // Look for room references in the tokens
    for (int i = 0; i < tokens.length; i++) {
      // Check for "room N" format
      if (tokens[i] == "room" && i + 1 < tokens.length) {
        try {
          int roomIndex = int.parse(tokens[i + 1]) - 1;
          if (roomIndex >= 0 && roomIndex < rooms.length) {
            return roomIndex;
          }
        } catch (e) {
          // Not a number, continue checking
        }
      }

      // Check if current token matches any room name
      for (int roomIndex = 0; roomIndex < rooms.length; roomIndex++) {
        if (isMatchingRoom(tokens[i], rooms[roomIndex])) {
          return roomIndex;
        }
      }
    }

    return -1; // Room not found
  }

  // Helper function to find reference stairs index
  int _findReferenceStairsIndex(List<String> tokens) {
    for (int i = 0; i < tokens.length; i++) {
      if (tokens[i].toLowerCase() == "stairs") {
        if (i + 1 < tokens.length) {
          try {
            return int.parse(tokens[i + 1]) - 1; // Convert to 0-based index
          } catch (e) {
            // If next token isn't a number, might be named stairs
            continue;
          }
        }
      }
    }
    return -1;
  }

  Map<String, double> extractMeasurements(String command) {
    RegExp regExp = RegExp(
        r'(\d+)\s*(feet|meters|foot|ft)?\s*(?:by|x|\/)\s*(\d+)\s*(feet|meters|foot|ft)?');
    var match = regExp.firstMatch(command);

    if (match != null) {
      double width = double.parse(match.group(1)!);
      double height = double.parse(match.group(3)!);

      // Handle units if present
      String? widthUnit = match.group(2);
      String? heightUnit = match.group(4);

      if (widthUnit != null) {
        width =
            floorPlanController?.convertToMetricUnits(width, widthUnit) ?? 0;
      }
      if (heightUnit != null) {
        height =
            floorPlanController?.convertToMetricUnits(height, heightUnit) ?? 0;
      }

      return {'width': width, 'height': height};
    }

    return {};
  }

  void _handleResizeCommand(List<String> tokens) {
    if (selectedRoom != null) {
      // Handle single dimension changes first
      if (_handleSingleDimensionChange(tokens)) {
        return;
      }

      // Handle "resize to X by Y" format
      if (tokens.contains("to") &&
          (tokens.contains("by") ||
              tokens.contains("x") ||
              tokens.contains("/"))) {
        String command = tokens.join(" ");
        Map<String, double> dimensions = extractMeasurements(command);
        if (dimensions.isNotEmpty) {
          floorPlanController?.resizeRoom(
              dimensions['width']!, dimensions['height']!);
          return;
        }
      }

      // Handle increase/decrease by percentage for both dimensions
      if (tokens.contains("increase") || tokens.contains("decrease")) {
        bool increase = tokens.contains("increase");
        double? percentage;

        for (int i = 0; i < tokens.length - 1; i++) {
          if (tokens[i] == "by" && tokens[i + 1].endsWith("%")) {
            try {
              percentage =
                  double.parse(tokens[i + 1].replaceAll("%", "")) / 100;
              break;
            } catch (e) {
              continue;
            }
          }
        }

        if (percentage != null) {
          double factor = increase ? (1 + percentage) : (1 - percentage);
          double newWidth = selectedRoom!.width * factor;
          double newHeight = selectedRoom!.height * factor;
          floorPlanController?.resizeRoom(newWidth, newHeight);
          return;
        }
      }

      MessageService.showMessage(floorManagerController.context,
          "Invalid resize command. Try: 'resize to X by Y', 'change width to X', or 'increase height by Z%'",
          type: MessageType.error);
      return;
    } else if (floorPlanController?.selectedStairs != null) {
      // Handle single dimension changes first
      if (_handleSingleDimensionChange(tokens)) {
        return;
      }

      // Handle "resize to X by Y" format
      if (tokens.contains("to") &&
          (tokens.contains("by") ||
              tokens.contains("x") ||
              tokens.contains("/"))) {
        String command = tokens.join(" ");
        Map<String, double> dimensions = extractMeasurements(command);
        if (dimensions.isNotEmpty) {
          floorPlanController?.resizeStairs(
              dimensions['width']!, dimensions['height']!);
          return;
        }
      }

      // Handle increase/decrease by percentage for both dimensions
      if (tokens.contains("increase") || tokens.contains("decrease")) {
        bool increase = tokens.contains("increase");
        double? percentage;

        for (int i = 0; i < tokens.length - 1; i++) {
          if (tokens[i] == "by" && tokens[i + 1].endsWith("%")) {
            try {
              percentage =
                  double.parse(tokens[i + 1].replaceAll("%", "")) / 100;
              break;
            } catch (e) {
              continue;
            }
          }
        }

        if (percentage != null) {
          double factor = increase ? (1 + percentage) : (1 - percentage);
          double newWidth = floorPlanController!.selectedStairs!.width * factor;
          double newLength =
              floorPlanController!.selectedStairs!.length * factor;
          floorPlanController?.resizeStairs(newWidth, newLength);
          return;
        }
      }

      MessageService.showMessage(floorManagerController.context,
          "Invalid resize command. Try: 'resize to X by Y', 'change width to X', or 'increase height by Z%'",
          type: MessageType.error);
      return;
    } else {
      MessageService.showMessage(floorManagerController.context,
          "Please select a room or stairs first.",
          type: MessageType.error);
    }
  }

// Add new method to handle single dimension changes
  bool _handleSingleDimensionChange(List<String> tokens) {
    if (selectedRoom != null) {
      bool isWidth = tokens.contains("width");
      bool isHeight = tokens.contains("height");

      if (!isWidth && !isHeight) return false;

      // Prevent ambiguous commands
      if (isWidth && isHeight) {
        MessageService.showMessage(floorManagerController.context,
            "Please specify only one dimension at a time",
            type: MessageType.error);
        return true;
      }

      String dimension = isWidth ? "width" : "height";
      double currentValue =
          isWidth ? selectedRoom!.width : selectedRoom!.height;
      double? newValue;

      // Handle absolute value changes (e.g., "change width to 15 feet")
      if (tokens.contains("to")) {
        int toIndex = tokens.indexOf("to");
        if (toIndex + 1 < tokens.length) {
          try {
            double value = double.parse(tokens[toIndex + 1]);
            String? unit =
                toIndex + 2 < tokens.length ? tokens[toIndex + 2] : null;
            if (unit != null) {
              value = floorPlanController!.convertToMetricUnits(value, unit);
            }
            newValue = value;
          } catch (e) {
            // Handle parsing error
          }
        }
      }
      // Handle percentage changes (e.g., "increase width by 20%")
      else if (tokens.contains("by")) {
        bool increase = tokens.contains("increase");
        int byIndex = tokens.indexOf("by");
        if (byIndex + 1 < tokens.length && tokens[byIndex + 1].endsWith("%")) {
          try {
            double percentage =
                double.parse(tokens[byIndex + 1].replaceAll("%", "")) / 100;
            double factor = increase ? (1 + percentage) : (1 - percentage);
            newValue = currentValue * factor;
          } catch (e) {
            // Handle parsing error
          }
        }
      }

      if (newValue != null && newValue > 0) {
        if (isWidth) {
          floorPlanController!.resizeRoom(newValue, selectedRoom!.height);
        } else {
          floorPlanController!.resizeRoom(selectedRoom!.width, newValue);
        }
        return true;
      }

      MessageService.showMessage(floorManagerController.context,
          "Invalid $dimension change. Try: 'change $dimension to X' or 'increase $dimension by Y%'",
          type: MessageType.error);
      return true;
    } else if (floorPlanController!.selectedStairs != null) {
      bool isWidth = tokens.contains("width");
      bool isHeight = tokens.contains("height");

      if (!isWidth && !isHeight) return false;

      // Prevent ambiguous commands
      if (isWidth && isHeight) {
        MessageService.showMessage(floorManagerController.context,
            "Please specify only one dimension at a time",
            type: MessageType.error);
        return true;
      }

      String dimension = isWidth ? "width" : "height";
      double currentValue = isWidth
          ? floorPlanController!.selectedStairs!.width
          : floorPlanController!.selectedStairs!.length;
      double? newValue;

      // Handle absolute value changes (e.g., "change width to 15 feet")
      if (tokens.contains("to")) {
        int toIndex = tokens.indexOf("to");
        if (toIndex + 1 < tokens.length) {
          try {
            double value = double.parse(tokens[toIndex + 1]);
            String? unit =
                toIndex + 2 < tokens.length ? tokens[toIndex + 2] : null;
            if (unit != null) {
              value = floorPlanController!.convertToMetricUnits(value, unit);
            }
            newValue = value;
          } catch (e) {
            // Handle parsing error
          }
        }
      }
      // Handle percentage changes (e.g., "increase width by 20%")
      else if (tokens.contains("by")) {
        bool increase = tokens.contains("increase");
        int byIndex = tokens.indexOf("by");
        if (byIndex + 1 < tokens.length && tokens[byIndex + 1].endsWith("%")) {
          try {
            double percentage =
                double.parse(tokens[byIndex + 1].replaceAll("%", "")) / 100;
            double factor = increase ? (1 + percentage) : (1 - percentage);
            newValue = currentValue * factor;
          } catch (e) {
            // Handle parsing error
          }
        }
      }

      if (newValue != null && newValue > 0) {
        if (isWidth) {
          floorPlanController!.resizeStairs(
              newValue, floorPlanController!.selectedStairs!.length);
        } else {
          floorPlanController!.resizeStairs(
              floorPlanController!.selectedStairs!.width, newValue);
        }
        return true;
      }

      MessageService.showMessage(floorManagerController.context,
          "Invalid $dimension change. Try: 'change $dimension to X' or 'increase $dimension by Y%'",
          type: MessageType.error);
      return true;
    } else {
      MessageService.showMessage(
          floorManagerController.context, "Try giving right single dimension",
          type: MessageType.error);
      return true;
    }
  }

  void _handleStairsCommand(String command, List<String> tokens) {
    if (floorPlanController?.getBase() == null) {
      MessageService.showMessage(
          floorManagerController.context, "Please create a base first",
          type: MessageType.error);
      return;
    }

    // Handle "remove stairs" command
    if (tokens.contains("remove")) {
      if (tokens.contains("all")) {
        floorPlanController?.removeAllStairs();
        MessageService.showMessage(
            floorManagerController.context, "All stairs removed",
            type: MessageType.success);
        return;
      }
      if (floorPlanController?.selectedStairs != null) {
        floorPlanController?.removeSelectedStairs();
        MessageService.showMessage(
            floorManagerController.context, "Selected stairs removed",
            type: MessageType.success);
        return;
      }
      return;
    }

    // Extract dimensions if provided
    Map<String, double> dimensions = {};
    if (tokens.contains("by") || tokens.contains("/")) {
      dimensions = extractMeasurements(command);
    }

    // Default dimensions if not specified
    double width = dimensions['width'] ?? 4.0; // 4 feet wide by default
    double length = dimensions['height'] ?? 10.0; // 10 feet long by default

    // Extract direction
    String direction = "up";
    if (tokens.contains("down")) {
      direction = "down";
    }

    // Extract number of steps
    int steps = 12; // default number of steps
    for (int i = 0; i < tokens.length - 1; i++) {
      if (tokens[i] == "steps") {
        try {
          steps = int.parse(tokens[i - 1]);
          break;
        } catch (e) {
          continue;
        }
      }
    }

    // Position the stairs (similar to room positioning)
    // Offset position = const Offset(
    //     0, 0); // You may want to implement better positioning logic

    floorPlanController?.addNextStairs(
      width: width,
      length: length,
      direction: direction,
      numberOfSteps: steps,
    );
  }

  void _handleSelectStairsCommand(List<String> tokens) {
    if (tokens.length == 2) {
      MessageService.showMessage(floorManagerController.context,
          "Please specify which stairs to select",
          type: MessageType.error);
      return;
    }

    String stairsName = tokens.sublist(1).join(" ");
    print(stairsName);
    floorPlanController?.selectStairs(stairsName.trim());
  }

  void _handleZoomCommand(List<String> tokens) {
    if (tokens.contains("in")) {
      floorPlanController?.zoomIn();
      MessageService.showMessage(
        floorManagerController.context,
        "Zoomed in",
        type: MessageType.info,
      );
      return;
    }

    if (tokens.contains("out")) {
      floorPlanController?.zoomOut();
      MessageService.showMessage(
        floorManagerController.context,
        "Zoomed out",
        type: MessageType.info,
      );
      return;
    }

    // Handle specific zoom level
    if (tokens.contains("to")) {
      int toIndex = tokens.indexOf("to");
      if (toIndex + 1 < tokens.length) {
        try {
          double zoomLevel = double.parse(tokens[toIndex + 1]);
          floorPlanController?.setZoom(zoomLevel);
          MessageService.showMessage(
            floorManagerController.context,
            "Zoom level set to $zoomLevel",
            type: MessageType.info,
          );
          return;
        } catch (e) {
          // Handle parsing error
        }
      }
    }

    MessageService.showMessage(
      floorManagerController.context,
      "Invalid zoom command. Try: 'zoom in', 'zoom out', or 'zoom to 2.0'",
      type: MessageType.error,
    );
  }

  void _handleDoorCommand(String command, List<String> tokens) {
    // Check if a room is selected first
    if (selectedRoom == null) {
      MessageService.showMessage(floorManagerController.context,
          "Please select a room first before performing door operations",
          type: MessageType.error);
      return;
    }

    // Handle door removal
    if (tokens.contains("remove") || tokens.contains("delete")) {
      _handleRemoveDoorCommand(tokens);
      return;
    }

    // Handle door addition
    if (tokens.contains("add") || tokens.contains("create")) {
      _handleAddDoorCommand(command, tokens);
      return;
    }

    // Handle door movement
    if (tokens.contains("move")) {
      _handleMoveDoorCommand(command, tokens);
      return;
    }

    // Handle door swing changes
    if (tokens.contains("swing")) {
      _handleDoorSwingCommand(tokens);
      return;
    }

    MessageService.showMessage(floorManagerController.context,
        "Invalid door command. Try: 'add door on [wall]', 'move door', 'change door swing', or 'remove door'",
        type: MessageType.error);
  }

  void _handleAddDoorCommand(String command, List<String> tokens) {
    // Extract wall
    String? wall;
    for (String direction in [
      "north",
      "up",
      "south",
      "down",
      "east",
      "right",
      "west",
      "left"
    ]) {
      if (tokens.contains(direction)) {
        wall = direction;
        break;
      }
    }

    if (wall == null) {
      MessageService.showMessage(floorManagerController.context,
          "Please specify a wall (north, south, east, or west)",
          type: MessageType.error);
      return;
    }

    // Extract offset (if specified) or calculate center position
    double offset;
    if (tokens.contains("at")) {
      int atIndex = tokens.indexOf("at");
      if (atIndex + 1 < tokens.length) {
        try {
          offset = double.parse(tokens[atIndex + 1]);
        } catch (e) {
          // If parsing fails, use center position
          offset = _calculateDefaultDoorOffset(selectedRoom!, wall);
        }
      } else {
        offset = _calculateDefaultDoorOffset(selectedRoom!, wall);
      }
    } else {
      // If no offset specified, place door at center of wall
      offset = _calculateDefaultDoorOffset(selectedRoom!, wall);
    }

    // Check for connecting door
    bool connectToAdjacent =
        tokens.contains("connecting") || tokens.contains("connected");

    // Extract width if specified
    double? width;
    if (tokens.contains("width")) {
      int widthIndex = tokens.indexOf("width");
      if (widthIndex + 1 < tokens.length) {
        try {
          width = double.parse(tokens[widthIndex + 1]);
        } catch (e) {
          // Keep default width if parsing fails
        }
      }
    }

    // Add the door to the selected room
    floorPlanController?.addDoor(
      selectedRoom!.name,
      wall,
      offset,
      width: width ?? Door.defaultWidth,
      connectToAdjacent: connectToAdjacent,
    );
  }

  // Add this helper method
  double _calculateDefaultDoorOffset(Room room, String wall) {
    double wallLength =
        (wall == "north" || wall == "south" || wall == "up" || wall == "down")
            ? room.width
            : room.height;
    // Place door at center of wall by default
    return (wallLength - Door.defaultWidth) / 2;
  }

  void _handleMoveDoorCommand(String command, List<String> tokens) {
    if (selectedRoom == null) {
      MessageService.showMessage(
          floorManagerController.context, "Please select a room first",
          type: MessageType.error);
      return;
    }

    // Extract door number
    int? doorNumber;
    for (int i = 0; i < tokens.length; i++) {
      if (tokens[i] == "door" && i + 1 < tokens.length) {
        try {
          doorNumber = int.parse(tokens[i + 1]);
          break;
        } catch (e) {
          continue;
        }
      }
    }

    if (doorNumber == null) {
      MessageService.showMessage(
          floorManagerController.context, "Please specify which door to move",
          type: MessageType.error);
      return;
    }

    // Extract new offset
    double? newOffset;
    if (tokens.contains("to")) {
      int toIndex = tokens.indexOf("to");
      if (toIndex + 1 < tokens.length) {
        try {
          newOffset = double.parse(tokens[toIndex + 1]);
        } catch (e) {
          // Handle parsing error
        }
      }
    }

    if (newOffset == null) {
      MessageService.showMessage(floorManagerController.context,
          "Please specify where to move the door",
          type: MessageType.error);
      return;
    }

    String doorId = "${selectedRoom!.name}:$doorNumber";
    floorPlanController?.moveDoor(selectedRoom!.name, doorId, newOffset);
  }

  void _handleDoorSwingCommand(List<String> tokens) {
    if (selectedRoom == null) {
      MessageService.showMessage(
          floorManagerController.context, "Please select a room first",
          type: MessageType.error);
      return;
    }

    // Extract door number
    int? doorNumber;
    for (int i = 0; i < tokens.length; i++) {
      if (tokens[i] == "door" && i + 1 < tokens.length) {
        try {
          doorNumber = int.parse(tokens[i + 1]);
          break;
        } catch (e) {
          continue;
        }
      }
    }

    if (doorNumber == null) {
      MessageService.showMessage(
          floorManagerController.context, "Please specify which door to modify",
          type: MessageType.error);
      return;
    }

    // Determine swing direction
    bool? swingInward;
    if (tokens.contains("in") || tokens.contains("inward")) {
      swingInward = true;
    } else if (tokens.contains("out") || tokens.contains("outward")) {
      swingInward = false;
    }

    if (swingInward == null) {
      MessageService.showMessage(floorManagerController.context,
          "Please specify swing direction (in/out)",
          type: MessageType.error);
      return;
    }

    floorPlanController?.changeDoorSwing(
        selectedRoom!.name, "${selectedRoom!.name}:$doorNumber", swingInward);
  }

  void _handleRemoveDoorCommand(List<String> tokens) {
    if (selectedRoom == null) {
      MessageService.showMessage(
          floorManagerController.context, "Please select a room first",
          type: MessageType.error);
      return;
    }

    // Handle "remove all doors"
    if (tokens.contains("all")) {
      floorPlanController?.removeAllDoors(selectedRoom!.name);
      return;
    }

    // Extract door number
    int? doorNumber;
    for (int i = 0; i < tokens.length; i++) {
      if (tokens[i] == "door" && i + 1 < tokens.length) {
        try {
          doorNumber = int.parse(tokens[i + 1]);
          break;
        } catch (e) {
          continue;
        }
      }
    }

    if (doorNumber == null) {
      MessageService.showMessage(
          floorManagerController.context, "Please specify which door to remove",
          type: MessageType.error);
      return;
    }

    floorPlanController?.removeDoor(
        selectedRoom!.name, "${selectedRoom!.name}:$doorNumber");
  }
}
