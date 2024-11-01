import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:saysketch_v2/controllers/floor_plan_controller.dart';
import 'package:saysketch_v2/controllers/command_controller.dart';
import 'package:saysketch_v2/models/room_model.dart';
import 'package:saysketch_v2/services/speech_to_text_service.dart';
import 'floor_plan_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final FloorPlanController _floorPlanController = FloorPlanController();
  final SpeechToTextService _speechService = SpeechToTextService();
  bool _isListening = false;
  final _controller = TextEditingController();
  Room? selectedRoom;

  void _onCommand(String command) {
    // Convert command to lowercase for easier comparison
    command = command.toLowerCase();
    List<String> tokens = command.split(" ");

    print("Recognized command: $command"); // Debug print

    // Handle remove commands
    if (tokens.contains("remove")) {
      _handleRemoveCommand(tokens);
    }
    // Handle base creation commands
    else if (tokens.contains("base")) {
      _handleBaseCommand(command, tokens);
    } else if (tokens.contains("select")) {
      _handleSelectCommand(tokens);
    } else if (tokens.contains("deselect")) {
      selectedRoom = null;
      _floorPlanController.deselectRoom();
    } else if (tokens.contains("rename")) {
      if (tokens.length != 1) {
        if (tokens.contains("to")) {
          _handleRenameRoomCommand(tokens.sublist(2));
        } else {
          _handleRenameRoomCommand(tokens.sublist(1));
        }
      } else {
        if (selectedRoom == null) {
          Fluttertoast.showToast(
            msg: "Please select a room first.",
          );
        } else {
          Fluttertoast.showToast(
            msg: "Please specify the new name for the selected room.",
          );
        }
      }
    } else if (tokens.contains("move")) {
      if (selectedRoom == null) {
        Fluttertoast.showToast(msg: "Please select a room first");
        return;
      }

      // Handle predefined positions (center, topleft, etc.)
      if (tokens.contains("to")) {
        for (String position in [
          "center",
          "topleft",
          "topright",
          "bottomleft",
          "bottomright"
        ]) {
          if (tokens.contains(position)) {
            _floorPlanController.moveRoomToPosition(position);
            return;
          }
        }

        // Handle "move to the <direction> of room X"
        int roomIndex = _findReferenceRoomIndex(tokens);
        if (roomIndex != -1) {
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
              _floorPlanController.moveRoomRelativeToOther(
                  roomIndex, direction);
              return;
            }
          }
        }
      }

      // Handle relative movements with units
      // e.g., "move 5 feet to the right", "move 2 meters north"
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
            _floorPlanController.moveRoomRelative(distance, direction);
            return;
          }
        }
      }

      // Handle absolute coordinates
      try {
        int xIndex = tokens.indexOf("x");
        int yIndex = tokens.indexOf("y");

        if (xIndex != -1 &&
            yIndex != -1 &&
            xIndex + 1 < tokens.length &&
            yIndex + 1 < tokens.length) {
          double x = double.parse(tokens[xIndex + 1]);
          double y = double.parse(tokens[yIndex + 1]);
          _floorPlanController.moveRoom(x, y);
          return;
        }
      } catch (e) {
        // Handle parsing errors
      }

      Fluttertoast.showToast(
          msg:
              "Invalid move command. Try: 'move to center', 'move 5 feet right', 'move to the right of room 1'");
    }
    // Handle room commands
    else if (tokens.contains("room") || tokens.contains("rooms")) {
      _handleRoomCommand(command, tokens);
    } else {
      Fluttertoast.showToast(msg: "Invalid Command: $command");
    }

    setState(() {
      _isListening = false;
    });
  }

  double? _extractDistance(List<String> tokens) {
    for (int i = 0; i < tokens.length - 1; i++) {
      try {
        double value = double.parse(tokens[i]);
        String unit = tokens[i + 1];
        return _floorPlanController.convertToMetricUnits(value, unit);
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  int _findReferenceRoomIndex(List<String> tokens) {
    for (int i = 0; i < tokens.length; i++) {
      if (tokens[i] == "room" && i + 1 < tokens.length) {
        try {
          int roomNumber = int.parse(tokens[i + 1]);
          return roomNumber - 1; // Convert to 0-based index
        } catch (e) {
          continue;
        }
      }
    }
    return -1;
  }

  void _handleRemoveCommand(List tokens) {
    if (selectedRoom == null) {
      if (tokens.contains("base")) {
        setState(() {
          _floorPlanController.removeBase();
          Fluttertoast.showToast(msg: "Base removed");
        });
      } else if (tokens.contains("rooms") || tokens.contains("all")) {
        setState(() {
          _floorPlanController.removeAllRooms();
          Fluttertoast.showToast(msg: "All rooms removed");
        });
      } else if (tokens.contains("last") &&
          (tokens.contains("room") || tokens.contains("rooms"))) {
        setState(() {
          _floorPlanController.removeLastAddedRoom();
          Fluttertoast.showToast(msg: "Last room removed");
        });
      } else {
        Fluttertoast.showToast(
            msg: "Please specify what to remove (base, rooms, or last room)");
      }
    } else {
      _floorPlanController.removeSelectedRoom();
      selectedRoom = null;
    }
  }

  void _handleSelectCommand(List tokens) {
    if (tokens.length == 1) {
      Fluttertoast.showToast(
          msg: "Please specify the room name to select that room.");
      return;
    }

    selectedRoom = null;

    String roomName = "";
    for (int i = 1; i < tokens.length; i++) {
      roomName += tokens[i] + " ";
    }

    selectedRoom = _floorPlanController.selectRoom(roomName.trim());
  }

  void _handleRenameRoomCommand(List tokens) {
    if (selectedRoom != null) {
      String roomName = "";
      for (int i = 0; i < tokens.length; i++) {
        roomName += tokens[i] + " ";
      }
      _floorPlanController.renameRoom(roomName.trim());
    } else {
      Fluttertoast.showToast(msg: "Please select a room first.");
    }
  }

  void _handleBaseCommand(String command, List tokens) {
    if (tokens.contains("by") || tokens.contains("/")) {
      Map<String, double> dimensions =
          CommandController().extractMeasurements(command);
      if (dimensions.isNotEmpty) {
        setState(() {
          _floorPlanController.setBase(
            dimensions['width']!,
            dimensions['height']!,
            const Offset(100, 100),
          );
          Fluttertoast.showToast(msg: "Base created with custom dimensions");
        });
      } else {
        Fluttertoast.showToast(msg: "Could not understand dimensions");
      }
    } else {
      setState(() {
        _floorPlanController.setDefaultBase();
        Fluttertoast.showToast(msg: "Default base created");
      });
    }
  }

  // HomeView.dart
  void _handleRoomCommand(String command, List tokens) {
    if (_floorPlanController.getBase() == null) {
      Fluttertoast.showToast(msg: "Please create a base first");
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
      Map<String, double> dimensions =
          CommandController().extractMeasurements(command);
      if (dimensions.isNotEmpty) {
        setState(() {
          _floorPlanController.addNextRoomWithDimensions(
              width: dimensions['width']!, height: dimensions['height']!);
          Fluttertoast.showToast(msg: "Added room with custom dimensions");
        });
      } else {
        Fluttertoast.showToast(msg: "Could not understand room dimensions");
      }
    }
    // Handle "another room" or "next room" or "add room" commands
    else if (tokens.contains("another") ||
        tokens.contains("next") ||
        (tokens.contains("add") && tokens.contains("room"))) {
      setState(() {
        _floorPlanController.addNextRoom();
        Fluttertoast.showToast(msg: "Added new room");
      });
    }
    // Handle default room command
    else if (tokens.contains("room") || tokens.contains("rooms")) {
      setState(() {
        _floorPlanController.addDefaultRoom();
        Fluttertoast.showToast(msg: "Added default room");
      });
    }
  }

  void _startListening() async {
    await _speechService.listen(_onCommand);
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() {
    _speechService.stopListening();
    setState(() {
      _isListening = false;
    });
    Fluttertoast.showToast(msg: "Stopped listening");
  }

  void _handleTextCommand(String text) {
    if (text.isNotEmpty) {
      _onCommand(text);
      _controller.clear();
    }
  }

  void _handleRelativeRoomCommand(String command, List tokens) {
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

    // Find room number (e.g., "room 1" or "room1")
    for (int i = 0; i < tokens.length; i++) {
      if (tokens[i] == "room") {
        if (i + 1 < tokens.length) {
          referenceRoomIndex = int.tryParse(tokens[i + 1]);
          if (referenceRoomIndex != null) {
            referenceRoomIndex -= 1; // Convert to 0-based index
          }
        }
      } else if (tokens[i].startsWith("room")) {
        String numStr = tokens[i].substring(4);
        referenceRoomIndex = int.tryParse(numStr);
        if (referenceRoomIndex != null) {
          referenceRoomIndex -= 1; // Convert to 0-based index
        }
      }
    }

    if (referenceRoomIndex == null || position == null) {
      Fluttertoast.showToast(
          msg: "Please specify a valid room number and position");
      return;
    }

    // Handle dimensions
    if (tokens.contains("by") || tokens.contains("/")) {
      Map<String, double> dimensions =
          CommandController().extractMeasurements(command);
      if (dimensions.isNotEmpty) {
        setState(() {
          _floorPlanController.addRoomRelativeTo(dimensions['width']!,
              dimensions['height']!, referenceRoomIndex!, position!);
          Fluttertoast.showToast(
              msg: "Added room $position room ${referenceRoomIndex + 1}");
        });
      } else {
        Fluttertoast.showToast(msg: "Could not understand room dimensions");
      }
    } else {
      // Use default dimensions
      setState(() {
        _floorPlanController.addRoomRelativeTo(
            10, // default width
            10, // default height
            referenceRoomIndex!,
            position!);
        Fluttertoast.showToast(
            msg: "Added default room $position room ${referenceRoomIndex + 1}");
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text("Floor Plan App")),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: FloorPlanView(controller: _floorPlanController)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _isListening ? _stopListening : _startListening,
                    child: Text(
                        _isListening ? "Stop Listening" : "Start Listening"),
                  ),
                  ElevatedButton(
                    onPressed: () => _floorPlanController.addNextRoom(),
                    child: const Text("Add Next Room"),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Enter command here...",
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: _handleTextCommand,
                  autofocus: true,
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Commands: 'create base', 'add room', 'another room', 'remove base', 'remove rooms', 'remove last room'",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
