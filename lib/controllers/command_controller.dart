import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:saysketch_v2/controllers/floor_manager_controller.dart';
import 'package:saysketch_v2/controllers/floor_plan_controller.dart';
import 'package:saysketch_v2/models/room_model.dart';
import 'package:saysketch_v2/services/message_service.dart';

class CommandController {
  final FloorManagerController floorManagerController;
  Room? selectedRoom;

  CommandController(this.floorManagerController);

  FloorPlanController? get floorPlanController =>
      floorManagerController.getActiveController();

  void handleCommand(String command, BuildContext context) {
    command = command.toLowerCase();
    List<String> tokens = command.split(" ");

    if (tokens.contains("undo")) {
      // TODO: Implement undo
      // In your command handler when processing the "undo" command:
      // print("Before undo:");
      // floorPlanController?.printState();
      // floorPlanController?.undo();
      // print("After undo:");
      // floorPlanController?.printState();
      return;
    }

    if (tokens.contains("redo")) {
      // TODO: Implement redo
      // floorPlanController?.redo();
      return;
    }

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

    if (tokens.contains("select") &&
        (tokens.contains("cutout") ||
            tokens.contains("cut") && tokens.contains("out"))) {
      _handleSelectCutOutCommand(tokens);
      return;
    }

    if (tokens.contains("door") || tokens.contains("doors")) {
      print("remove door");
      _handleDoorCommand(command, tokens);
      return;
    } else if (tokens.contains("space") || tokens.contains("spaces")) {
      print("0");
      _handleSpaceCommand(command, tokens);
      return;
    }
    // Add window command handling
    else if (tokens.contains("window") || tokens.contains("windows")) {
      _handleWindowCommand(command, tokens);
      return;
    }

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
      return;
    } else if (tokens.contains("hide")) {
      _handleHideCommand(tokens);
      return;
    } else if (tokens.contains("show")) {
      _handleShowCommand(tokens);
      return;
    }
    // Handle base creation commands
    else if (tokens.contains("base") || tokens.contains("bass")) {
      _handleBaseCommand(command, tokens);
      return;
    } else if (tokens.contains("select")) {
      if (tokens.contains("stairs")) {
        _handleSelectStairsCommand(tokens);
        return;
      } else {
        _handleSelectCommand(tokens);
        return;
      }
    } else if (tokens.contains("deselect") || tokens.contains("unselect")) {
      // if (tokens.contains("door")) {
      //   floorPlanController?.deselectDoor();
      //   return;
      // } else if (tokens.contains("room")) {
      //   selectedRoom = null;
      //   floorPlanController?.deselectRoom();
      //   return;
      // } else if (tokens.contains("stairs")) {
      //   floorPlanController?.deselectStairs();
      //   return;
      // } else {
      //   // Deselect everything
      //   selectedRoom = null;
      //   floorPlanController?.deselectRoom(); // This will also deselect door
      //   floorPlanController?.deselectStairs();
      //   return;
      // }
      floorPlanController?.deselectAll();
    } else if (tokens.contains("rename")) {
      _handleRenameCommand(tokens);
      return;
    } else if (tokens.contains("move")) {
      print("move command");
      _handleMoveCommand(tokens, context);
      return;
    } else if (tokens.contains("rotate")) {
      _handleRotateCommand(tokens);
      return;
    }
    // Handle room commands
    else if (tokens.contains("room") ||
        tokens.contains("rooms") ||
        tokens.contains("dhoom") ||
        tokens.contains("dhooms")) {
      _handleRoomCommand(command, tokens);
      return;
    } else if (tokens.contains("stairs")) {
      _handleStairsCommand(command, tokens);
      return;
    } else if (tokens.contains("scale")) {
      _handleZoomCommand(tokens);
      return;
    } else if ((tokens.contains("add") || tokens.contains("create")) &&
        (tokens.contains("cutout") ||
            (tokens.contains("cut") || tokens.contains("out")))) {
      _handleAddCutOutCommand(command, tokens);
      return;
    } else {
      Fluttertoast.showToast(msg: "Invalid Command: $command");
      return;
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
    // Check for door removal first
    if (tokens.contains("door")) {
      if (floorPlanController?.selectedDoor == null) {
        MessageService.showMessage(
            floorManagerController.context, "Please select a door first",
            type: MessageType.error);
        return;
      }
      floorPlanController?.removeSelectedDoor();
      return;
    }

    // Check for window removal
    if (tokens.contains("window")) {
      if (floorPlanController?.selectedWindow == null) {
        MessageService.showMessage(
            floorManagerController.context, "Please select a window first",
            type: MessageType.error);
        return;
      }
      floorPlanController?.removeSelectedWindow();
      return;
    }

    if (tokens.contains("space")) {
      if (floorPlanController?.selectedSpace == null) {
        MessageService.showMessage(
            floorManagerController.context, "Please select a space first",
            type: MessageType.error);
        return;
      }
      floorPlanController?.removeSelectedSpace();
      return;
    }
    if (tokens.contains("base")) {
      if (floorPlanController?.getBase() == null) {
        MessageService.showMessage(
            floorManagerController.context, "No base exists.",
            type: MessageType.error);
        return;
      }
      floorPlanController?.removeBase();
      return;
    }

    if (tokens.contains("rooms")) {
      floorPlanController?.removeAllRooms();
      return;
    }

    if (tokens.contains("last") && tokens.contains("room")) {
      floorPlanController?.removeLastAddedRoom();
      return;
    }

    if (tokens.contains("room")) {
      if (selectedRoom == null) {
        MessageService.showMessage(
            floorManagerController.context, "Please select a room first",
            type: MessageType.error);
        return;
      }
      floorPlanController?.removeSelectedRoom();
      return;
    }

    if (tokens.contains("cutout") ||
        (tokens.contains("cut") && tokens.contains("out"))) {
      if (floorPlanController?.selectedCutOut == null) {
        MessageService.showMessage(
            floorManagerController.context, "Please select a cutout first",
            type: MessageType.error);
        return;
      }
      floorPlanController?.removeSelectedCutOut();
      return;
    }

    if (tokens.contains("stairs")) {
      if (floorPlanController?.selectedStairs == null) {
        MessageService.showMessage(
            floorManagerController.context, "Please select stairs first",
            type: MessageType.error);
        return;
      }
      floorPlanController?.removeSelectedStairs();
      return;
    }
  }

  void _handleRotateCommand(List<String> tokens) {
    if (floorPlanController?.selectedStairs != null) {
      if (tokens.contains("left") || tokens.contains("anticlockwise")) {
        floorPlanController?.rotateStairsCounterclockwise();
      } else {
        floorPlanController?.rotateStairs();
      }
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
      String newName = nameTokens.join(" ").trim();

      // Rename the room but don't deselect it
      floorPlanController?.renameRoom(selectedRoom!.name, newName);

      // Update the selected room reference with the new name
      selectedRoom = floorPlanController
          ?.getRooms()
          .firstWhere((room) => room.name == newName);
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
          "top",
          "bottom",
        ]) {
          if (tokens.contains(position)) {
            floorPlanController?.moveStairsToPosition(
                position, tokens, context);
            return;
          }
        }

        // Handle relative positioning to rooms or other stairs
        int referenceRoomIndex = _findReferenceRoomIndex(
            tokens, floorPlanController?.getRooms() ?? []);
        int referenceStairsIndex = _findReferenceStairsIndex(tokens);
        int referenceCutoutIndex = _findReferenceCutoutIndex(tokens);

        if (referenceRoomIndex != -1 ||
            referenceStairsIndex != -1 ||
            referenceCutoutIndex != -1) {
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
              } else if (referenceStairsIndex != -1) {
                floorPlanController?.moveStairsRelativeToOther(
                    referenceStairsIndex, direction);
              } else if (referenceCutoutIndex != -1) {
                floorPlanController?.moveStairsRelativeToCutout(
                    referenceCutoutIndex, direction);
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
    } else if (floorPlanController?.selectedCutOut != null) {
      print("cutout move command");
      // Handle cutout movement
      if (tokens.contains("to")) {
        // Handle predefined positions for stairs
        for (String position in [
          "center",
          "top",
          "bottom",
        ]) {
          if (tokens.contains(position)) {
            floorPlanController?.moveCutoutToPosition(
                position, tokens, context);
            return;
          }
        }

        // Handle relative positioning to rooms or other stairs
        int referenceRoomIndex = _findReferenceRoomIndex(
            tokens, floorPlanController?.getRooms() ?? []);
        int referenceStairsIndex = _findReferenceStairsIndex(tokens);
        int referenceCutoutIndex = _findReferenceCutoutIndex(tokens);

        if (referenceRoomIndex != -1 ||
            referenceStairsIndex != -1 ||
            referenceCutoutIndex != -1) {
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
                floorPlanController?.moveCutoutRelativeToRoom(
                    referenceRoomIndex, direction);
              } else if (referenceCutoutIndex != -1) {
                floorPlanController?.moveCutoutRelativeToOther(
                    referenceCutoutIndex, direction);
              } else if (referenceStairsIndex != -1) {
                floorPlanController?.moveCutoutRelativeToStairs(
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
            print(
                "floorPlanController?.moveCutoutRelative(distance, direction);");
            floorPlanController?.moveCutoutRelative(distance, direction);
            return;
          }
        }
      }

      // Handle absolute coordinates for cutouts...
      try {
        int xIndex = tokens.indexOf("x");
        int yIndex = tokens.indexOf("y");

        if (xIndex != -1 &&
            yIndex != -1 &&
            xIndex + 1 < tokens.length &&
            yIndex + 1 < tokens.length) {
          double x = double.parse(tokens[xIndex + 1]);
          double y = double.parse(tokens[yIndex + 1]);
          floorPlanController?.moveCutout(x, y);
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
          "top",
          "bottom",
        ]) {
          if (tokens.contains(position)) {
            floorPlanController?.moveRoomToPosition(position, tokens, context);
            return;
          }
        }

        // Handle relative positioning to rooms or stairs
        int referenceRoomIndex = _findReferenceRoomIndex(
            tokens, floorPlanController?.getRooms() ?? []);
        int referenceStairsIndex = _findReferenceStairsIndex(tokens);
        int referenceCutoutIndex = _findReferenceCutoutIndex(tokens);

        if (referenceRoomIndex != -1 ||
            referenceStairsIndex != -1 ||
            referenceCutoutIndex != -1) {
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
              } else if (referenceStairsIndex != -1) {
                floorPlanController?.moveRoomRelativeToStairs(
                    referenceStairsIndex, direction);
              } else if (referenceCutoutIndex != -1) {
                floorPlanController?.moveRoomRelativeToCutout(
                    referenceCutoutIndex, direction);
              }
              return;
            }
          }
        }
        // else {
        //   for (String direction in [
        //     "right",
        //     "left",
        //     "up",
        //     "down",
        //     "north",
        //     "south",
        //     "east",
        //     "west"
        //   ]) {
        //     if (tokens.contains(direction)) {
        //       floorPlanController?.moveRoomToPosition(
        //           direction, tokens, context);
        //     }
        //   }
        // }
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
          "Please select a room, stairs, or cutout first.",
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
      // Use default dimensions
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
      floorPlanController?.addNextRoom();
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

  // Helper function to find reference cutout index
  int _findReferenceCutoutIndex(List<String> tokens) {
    for (int i = 0; i < tokens.length; i++) {
      if (tokens[i].toLowerCase() == "cutout") {
        if (i + 1 < tokens.length) {
          try {
            return int.parse(tokens[i + 1]) - 1; // Convert to 0-based index
          } catch (e) {
            // If next token isn't a number, might be named cutout
            continue;
          }
        }
      }
    }
    return -1;
  }

  Map<String, double> extractMeasurements(String command) {
    // Updated regex to handle decimal numbers
    RegExp regExp = RegExp(
        r'(\d*\.?\d+)\s*(feet|meters|foot|ft)?\s*(?:by|x|\/)\s*(\d*\.?\d+)\s*(feet|meters|foot|ft)?');
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
    } else if (floorPlanController?.selectedCutOut != null) {
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
          floorPlanController?.resizeCutout(
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
          double newWidth = floorPlanController!.selectedCutOut!.width * factor;
          double newHeight =
              floorPlanController!.selectedCutOut!.height * factor;
          floorPlanController?.resizeCutout(newWidth, newHeight);
          return;
        }
      }

      MessageService.showMessage(floorManagerController.context,
          "Invalid resize command. Try: 'resize to X by Y', 'change width to X', or 'increase height by Z%'",
          type: MessageType.error);
      return;
    } else {
      MessageService.showMessage(floorManagerController.context,
          "Please select a room or stairs or cutout first.",
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
    } else if (floorPlanController?.selectedCutOut != null) {
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
          ? floorPlanController!.selectedCutOut!.width
          : floorPlanController!.selectedCutOut!.height;
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
          floorPlanController!.resizeCutout(
              newValue, floorPlanController!.selectedCutOut!.height);
        } else {
          floorPlanController!.resizeCutout(
              floorPlanController!.selectedCutOut!.width, newValue);
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

    if (tokens.contains("reset")) {
      floorPlanController?.resetZoom();
      MessageService.showMessage(
        floorManagerController.context,
        "Zoom reset to default",
        type: MessageType.info,
      );
      return;
    }

    // Handle specific zoom level
    if (tokens.contains("to") || tokens.contains("by")) {
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
      "Invalid zoom command. Try: 'zoom in', 'zoom out', 'zoom reset', or 'zoom to 2.0'",
      type: MessageType.error,
    );
  }

  void _handleDoorCommand(String command, List<String> tokens) {
    // First, handle door selection
    if (tokens.contains("select")) {
      _handleSelectDoorCommand(tokens);
      return;
    }

    // Handle other door commands
    if (tokens.contains("add")) {
      _handleAddDoorCommand(tokens);
    } else if (tokens.contains("move")) {
      _handleMoveDoorCommand(tokens);
    } else if (tokens.contains("swing")) {
      _handleDoorSwingCommand(tokens);
    } else if (tokens.contains("remove") || tokens.contains("delete")) {
      _handleRemoveDoorCommand(tokens);
    } else if (tokens.contains("opens")) {
      _handleDoorOpeningDirectionCommand(tokens);
    } else if (tokens.contains("resize")) {
      _handleResizeDoorCommand(tokens);
    } else {
      MessageService.showMessage(
        floorManagerController.context,
        "Invalid door command",
        type: MessageType.error,
      );
    }
  }

  void _handleSpaceCommand(String command, List<String> tokens) {
    // First, handle door selection
    if (tokens.contains("select")) {
      _handleSelectSpaceCommand(tokens);
      return;
    }

    // Handle other door commands
    if (tokens.contains("add")) {
      _handleAddSpaceCommand(tokens);
    } else if (tokens.contains("move")) {
      _handleMoveSpaceCommand(tokens);
    } else if (tokens.contains("remove") || tokens.contains("delete")) {
      _handleRemoveSpaceCommand(tokens);
    } else if (tokens.contains("resize")) {
      _handleResizeSpaceCommand(tokens);
    } else {
      MessageService.showMessage(
        floorManagerController.context,
        "Invalid space command",
        type: MessageType.error,
      );
    }
  }

  // Add new method for door selection
  void _handleSelectDoorCommand(List<String> tokens) {
    String? parentName;
    int? doorNumber;

    // Find door number
    for (int i = 0; i < tokens.length; i++) {
      if (tokens[i] == "door" && i + 1 < tokens.length) {
        doorNumber = int.tryParse(tokens[i + 1]);
        break;
      }
    }

    // Find parent (room or cutout) name
    if (floorPlanController?.selectedRoom != null) {
      parentName = floorPlanController?.selectedRoom?.name;
    } else if (floorPlanController?.selectedCutOut != null) {
      parentName = floorPlanController?.selectedCutOut?.name;
    } else {
      // Look for "in room X" or "in cutout X" pattern
      for (int i = 0; i < tokens.length - 2; i++) {
        if (tokens[i] == "in") {
          if (tokens[i + 1] == "room" || tokens[i + 1] == "cutout") {
            String type = tokens[i + 1];
            String number = tokens[i + 2];
            parentName = "$type $number";
            break;
          }
        }
      }
    }

    if (doorNumber == null) {
      MessageService.showMessage(
        floorManagerController.context,
        "Please specify which door to select (e.g., 'select door 1')",
        type: MessageType.error,
      );
      return;
    }

    if (parentName == null) {
      MessageService.showMessage(
        floorManagerController.context,
        "Please select a room/cutout first or specify which room/cutout (e.g., 'select door 1 in room 1' or 'select door 1 in cutout 1')",
        type: MessageType.error,
      );
      return;
    }

    String doorId = "$parentName:d:$doorNumber";
    floorPlanController?.selectDoor(parentName, doorId);
  }

  void _handleAddDoorCommand(List<String> tokens) {
    String? wall;

    // Extract wall
    for (int i = 0; i < tokens.length - 1; i++) {
      if (tokens[i] == "on") {
        wall = tokens[i + 1];
        break;
      }
    }

    if (wall == null) {
      MessageService.showMessage(
        floorManagerController.context,
        "Please specify which wall (e.g., 'add door on north')",
        type: MessageType.error,
      );
      return;
    }

    wall = _normalizeWallDirection(wall);
    floorPlanController?.addDoorToSelected(wall);
  }

  void _handleMoveDoorCommand(List<String> tokens) {
    if (floorPlanController?.selectedDoor == null) {
      MessageService.showMessage(
          floorManagerController.context, "Please select a door first",
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
          "Please specify where to move the door (e.g., 'move door to 3')",
          type: MessageType.error);
      return;
    }

    // Move the selected door
    floorPlanController?.moveDoor(newOffset);
  }

  void _handleDoorSwingCommand(List<String> tokens) {
    if (floorPlanController?.selectedDoor == null) {
      MessageService.showMessage(
          floorManagerController.context, "Please select a door first",
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

    // Use the selected door directly
    floorPlanController?.changeDoorSwing(swingInward);
  }

  void _handleRemoveDoorCommand(List<String> tokens) {
    if (floorPlanController?.selectedDoor == null) {
      MessageService.showMessage(
          floorManagerController.context, "Please select a door first",
          type: MessageType.error);
      return;
    }

    floorPlanController?.removeSelectedDoor();
  }

  void _handleDoorOpeningDirectionCommand(List<String> tokens) {
    if (floorPlanController?.selectedDoor == null) {
      MessageService.showMessage(
        floorManagerController.context,
        "Please select a door first",
        type: MessageType.error,
      );
      return;
    }

    bool? openLeft;
    if (tokens.contains("left")) {
      openLeft = true;
    } else if (tokens.contains("right")) {
      openLeft = false;
    }

    if (openLeft == null) {
      MessageService.showMessage(
        floorManagerController.context,
        "Please specify opening direction (left/right)",
        type: MessageType.error,
      );
      return;
    }

    floorPlanController?.changeDoorOpeningDirection(openLeft);
  }

  void _handleWindowCommand(String command, List<String> tokens) {
    if (tokens.contains("select")) {
      _handleSelectWindowCommand(tokens);
      return;
    }

    if (tokens.contains("add")) {
      _handleAddWindowCommand(tokens);
    } else if (tokens.contains("remove") || tokens.contains("delete")) {
      _handleRemoveWindowCommand(tokens);
    } else if (tokens.contains("move")) {
      _handleMoveWindowCommand(tokens);
    } else if (tokens.contains("resize")) {
      _handleResizeWindowCommand(tokens);
    } else {
      MessageService.showMessage(
        floorManagerController.context,
        "Invalid window command. Available commands: add, remove, move, select",
        type: MessageType.error,
      );
    }
  }

  void _handleAddWindowCommand(List<String> tokens) {
    String? wall;

    // Extract wall
    for (int i = 0; i < tokens.length - 1; i++) {
      if (tokens[i] == "on") {
        wall = tokens[i + 1];
        break;
      }
    }

    if (wall == null) {
      MessageService.showMessage(
        floorManagerController.context,
        "Please specify which wall (e.g., 'add window on north')",
        type: MessageType.error,
      );
      return;
    }

    wall = _normalizeWallDirection(wall);
    floorPlanController?.addWindowToSelected(wall);
  }

  void _handleRemoveWindowCommand(List<String> tokens) {
    if (selectedRoom == null) {
      MessageService.showMessage(
          floorManagerController.context, "Please select a room first",
          type: MessageType.error);
      return;
    }

    // Extract window number
    int? windowNumber;
    for (int i = 0; i < tokens.length; i++) {
      if (tokens[i] == "window" && i + 1 < tokens.length) {
        try {
          windowNumber = int.parse(tokens[i + 1]);
          break;
        } catch (e) {
          continue;
        }
      }
    }

    if (windowNumber == null) {
      MessageService.showMessage(floorManagerController.context,
          "Please specify which window to remove",
          type: MessageType.error);
      return;
    }

    String windowId = "${selectedRoom!.name}:w:$windowNumber";

    // First select the window
    floorPlanController?.selectWindow(selectedRoom!.name, windowId);

    // Then remove it
    floorPlanController?.removeWindow(selectedRoom!.name, windowId);
  }

  void _handleMoveWindowCommand(List<String> tokens) {
    if (floorPlanController?.selectedWindow == null) {
      MessageService.showMessage(
          floorManagerController.context, "Please select a window first",
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
          "Please specify where to move the window (e.g., 'move window to 3')",
          type: MessageType.error);
      return;
    }

    // Move the selected window
    floorPlanController?.moveWindow(newOffset);
  }

  void _handleSelectWindowCommand(List<String> tokens) {
    String? parentName;
    int? windowNumber;

    // Find window number
    for (int i = 0; i < tokens.length; i++) {
      if (tokens[i] == "window" && i + 1 < tokens.length) {
        windowNumber = int.tryParse(tokens[i + 1]);
        break;
      }
    }

    // Find parent (room or cutout) name
    if (floorPlanController?.selectedRoom != null) {
      parentName = floorPlanController?.selectedRoom?.name;
    } else if (floorPlanController?.selectedCutOut != null) {
      parentName = floorPlanController?.selectedCutOut?.name;
    } else {
      // Look for "in room X" or "in cutout X" pattern
      for (int i = 0; i < tokens.length - 2; i++) {
        if (tokens[i] == "in") {
          if (tokens[i + 1] == "room" || tokens[i + 1] == "cutout") {
            String type = tokens[i + 1];
            String number = tokens[i + 2];
            parentName = "$type $number";
            break;
          }
        }
      }
    }

    if (windowNumber == null) {
      MessageService.showMessage(
        floorManagerController.context,
        "Please specify which window to select (e.g., 'select window 1')",
        type: MessageType.error,
      );
      return;
    }

    if (parentName == null) {
      MessageService.showMessage(
        floorManagerController.context,
        "Please select a room/cutout first or specify which room/cutout (e.g., 'select window 1 in room 1' or 'select window 1 in cutout 1')",
        type: MessageType.error,
      );
      return;
    }

    String windowId = "$parentName:w:$windowNumber";
    floorPlanController?.selectWindow(parentName, windowId);
  }

  void _handleAddCutOutCommand(String command, List<String> tokens) {
    // Extract dimensions if provided
    Map<String, double> dimensions = {};
    if (tokens.contains("by") || tokens.contains("/")) {
      dimensions = extractMeasurements(command);
    }

    // Default dimensions if not specified
    double width = dimensions['width'] ?? 7.0; // 7 feet wide by default
    double height = dimensions['height'] ?? 4.0; // 4 feet long by default

    floorPlanController?.addCutOut(width, height);
  }

  void _handleSelectCutOutCommand(List<String> tokens) {
    String? cutOutName;
    for (int i = 0; i < tokens.length; i++) {
      if (tokens[i] == "cutout" && i + 1 < tokens.length) {
        cutOutName = tokens[i + 1];
        break;
      } else if ((tokens[i] == "cut" && tokens[i + 1] == "out") &&
          i + 2 < tokens.length) {
        cutOutName = tokens[i + 2];
        break;
      }
    }

    if (cutOutName == null) {
      MessageService.showMessage(
        floorManagerController.context,
        "Please specify which cutout to select (e.g., 'select cutout 1')",
        type: MessageType.error,
      );
      return;
    }

    if (!cutOutName.startsWith("cutout ")) {
      cutOutName = "cutout $cutOutName";
    }

    floorPlanController?.selectCutOut(cutOutName);
  }

  void _handleAddSpaceCommand(List<String> tokens) {
    String? wall;
    bool connectToAdjacent = tokens.contains("connect");

    // Extract wall
    for (int i = 0; i < tokens.length - 1; i++) {
      if (tokens[i] == "on") {
        wall = tokens[i + 1];
        break;
      }
    }

    if (wall == null) {
      MessageService.showMessage(
        floorManagerController.context,
        "Please specify which wall (e.g., 'add space on north')",
        type: MessageType.error,
      );
      return;
    }

    wall = _normalizeWallDirection(wall);
    floorPlanController?.addSpaceToSelected(wall, connectToAdjacent);
  }

  String _normalizeWallDirection(String wall) {
    switch (wall.toLowerCase()) {
      case "n":
      case "north":
      case "up":
        return "north";
      case "s":
      case "south":
      case "down":
        return "south";
      case "e":
      case "east":
      case "right":
        return "east";
      case "w":
      case "west":
      case "left":
        return "west";
      default:
        return wall;
    }
  }

  void _handleSelectSpaceCommand(List<String> tokens) {
    int? spaceNumber;
    for (int i = 0; i < tokens.length; i++) {
      if (tokens[i] == "space" && i + 1 < tokens.length) {
        spaceNumber = int.tryParse(tokens[i + 1]);
        break;
      }
    }

    if (spaceNumber == null) {
      MessageService.showMessage(
        floorManagerController.context,
        "Please specify which space to select (e.g., 'select space 1')",
        type: MessageType.error,
      );
      return;
    }

    // Check if we have a selected room or cutout
    if (floorPlanController?.selectedRoom != null) {
      String spaceId =
          "${floorPlanController!.selectedRoom!.name}:s:$spaceNumber";
      floorPlanController?.selectSpace(
        floorPlanController!.selectedRoom!.name,
        spaceId,
      );
    } else if (floorPlanController?.selectedCutOut != null) {
      String spaceId =
          "${floorPlanController!.selectedCutOut!.name}:s:$spaceNumber";
      floorPlanController?.selectSpace(
        floorPlanController!.selectedCutOut!.name,
        spaceId,
      );
    } else {
      MessageService.showMessage(
        floorManagerController.context,
        "Please select a room or cutout first",
        type: MessageType.error,
      );
    }
  }

  void _handleMoveSpaceCommand(List<String> tokens) {
    double? newOffset;
    if (tokens.contains("to")) {
      int toIndex = tokens.indexOf("to");
      if (toIndex + 1 < tokens.length) {
        newOffset = double.tryParse(tokens[toIndex + 1]);
      }
    }

    if (newOffset == null) {
      MessageService.showMessage(
        floorManagerController.context,
        "Please specify where to move the space (e.g., 'move space to 5')",
        type: MessageType.error,
      );
      return;
    }

    floorPlanController?.moveSpace(newOffset);
  }

  // void _handleRemoveSpaceCommand(List<String> tokens) {
  //   if (floorPlanController?.selectedSpace == null) {
  //     MessageService.showMessage(
  //       floorManagerController.context,
  //       "Please select a space first",
  //       type: MessageType.error,
  //     );
  //     return;
  //   }

  //   // Find parent (room or cutout) of selected space
  //   if (floorPlanController?.selectedRoom != null) {
  //     floorPlanController?.removeSpace(
  //       floorPlanController!.selectedRoom!.name,
  //       floorPlanController!.selectedSpace!.id,
  //     );
  //   } else if (floorPlanController?.selectedCutOut != null) {
  //     floorPlanController?.removeSpace(
  //       floorPlanController!.selectedCutOut!.name,
  //       floorPlanController!.selectedSpace!.id,
  //     );
  //   }
  // }

  void _handleRemoveSpaceCommand(List<String> tokens) {
    if (floorPlanController?.selectedSpace == null) {
      MessageService.showMessage(
          floorManagerController.context, "Please select a door first",
          type: MessageType.error);
      return;
    }

    floorPlanController?.removeSelectedSpace();
  }

  void _handleResizeDoorCommand(List<String> tokens) {
    if (floorPlanController?.selectedDoor == null) {
      MessageService.showMessage(
        floorManagerController.context,
        "Please select a door first",
        type: MessageType.error,
      );
      return;
    }

    // Extract new width
    double? newWidth;
    if (tokens.contains("to")) {
      int toIndex = tokens.indexOf("to");
      if (toIndex + 1 < tokens.length) {
        try {
          newWidth = double.parse(tokens[toIndex + 1]);
        } catch (e) {
          // Handle parsing error
        }
      }
    }

    if (newWidth == null) {
      MessageService.showMessage(
        floorManagerController.context,
        "Please specify the new width (e.g., 'resize door to 3')",
        type: MessageType.error,
      );
      return;
    }

    floorPlanController?.resizeDoor(newWidth);
  }

  void _handleResizeWindowCommand(List<String> tokens) {
    if (floorPlanController?.selectedWindow == null) {
      MessageService.showMessage(
        floorManagerController.context,
        "Please select a window first",
        type: MessageType.error,
      );
      return;
    }

    // Extract new width
    double? newWidth;
    if (tokens.contains("to")) {
      int toIndex = tokens.indexOf("to");
      if (toIndex + 1 < tokens.length) {
        try {
          newWidth = double.parse(tokens[toIndex + 1]);
        } catch (e) {
          // Handle parsing error
        }
      }
    }

    if (newWidth == null) {
      MessageService.showMessage(
        floorManagerController.context,
        "Please specify the new width (e.g., 'resize window to 3')",
        type: MessageType.error,
      );
      return;
    }

    floorPlanController?.resizeWindow(newWidth);
  }

  void _handleResizeSpaceCommand(List<String> tokens) {
    if (floorPlanController?.selectedSpace == null) {
      MessageService.showMessage(
        floorManagerController.context,
        "Please select a space first",
        type: MessageType.error,
      );
      return;
    }

    // Extract new width
    double? newWidth;
    if (tokens.contains("to")) {
      int toIndex = tokens.indexOf("to");
      if (toIndex + 1 < tokens.length) {
        try {
          newWidth = double.parse(tokens[toIndex + 1]);
        } catch (e) {
          // Handle parsing error
        }
      }
    }

    if (newWidth == null) {
      MessageService.showMessage(
        floorManagerController.context,
        "Please specify the new width (e.g., 'resize space to 3')",
        type: MessageType.error,
      );
      return;
    }

    floorPlanController?.resizeSpace(newWidth);
  }
}
