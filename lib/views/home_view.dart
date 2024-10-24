import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:saysketch_v2/controllers/floor_plan_controller.dart';
import 'package:saysketch_v2/controllers/voice_command_controller.dart';
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

  void _onCommand(String command) {
    // Convert command to lowercase for easier comparison
    command = command.toLowerCase();
    List tokens = command.split(" ");

    print("Recognized command: $command"); // Debug print

    // Handle remove commands
    if (tokens.contains("remove")) {
      _handleRemoveCommand(tokens);
    }
    // Handle base creation commands
    else if (tokens.contains("base")) {
      _handleBaseCommand(command, tokens);
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

  void _handleRemoveCommand(List tokens) {
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
  }

  void _handleBaseCommand(String command, List tokens) {
    if (tokens.contains("by") || tokens.contains("/")) {
      Map<String, double> dimensions =
          VoiceCommandController().extractMeasurements(command);
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
    // Check if base exists first
    if (_floorPlanController.getBase() == null) {
      Fluttertoast.showToast(msg: "Please create a base first");
      return;
    }

    // Handle room with specific dimensions
    if (tokens.contains("by") || tokens.contains("/")) {
      Map<String, double> dimensions =
          VoiceCommandController().extractMeasurements(command);
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
      body: Column(
        children: [
          Expanded(child: FloorPlanView(controller: _floorPlanController)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _isListening ? _stopListening : _startListening,
                child:
                    Text(_isListening ? "Stop Listening" : "Start Listening"),
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
    );
  }
}
