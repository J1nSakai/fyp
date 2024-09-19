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

  // AnimationController? _animationController;
  // Animation<double>? _fadeAnimation;

  // void _onCommandRecognized(String command) {
  //   Map<String, double> dimensions =
  //       VoiceCommandController.extractMeasurements(command);
  //   if (dimensions.isNotEmpty) {
  //     setState(() {
  //       _controller.addRoom(
  //         dimensions['width']!,
  //         dimensions['height']!,
  //         const Offset(100, 100),
  //       );
  //     });
  //   } else {
  //     print("Cannot extract dimensions from the command.");
  //   }
  // }

  void _onCommand(String command) {
    List tokens = command.split(" ");
    if (tokens.contains("remove")) {
      if (tokens.contains("base")) {
        setState(() {
          _floorPlanController.removeBase();
        });
      } else if (tokens.contains("rooms")) {
        setState(() {
          _floorPlanController.removeAllRooms();
        });
      } else {
        Fluttertoast.showToast(msg: "Please specify what you want to remove.");
      }
    } else if (tokens.contains("base") && tokens.contains("by")) {
      Map<String, double> dimensions =
          VoiceCommandController().extractMeasurements(command);
      if (dimensions.isNotEmpty) {
        setState(() {
          _floorPlanController.setBase(
            dimensions['width']!,
            dimensions['height']!,
            const Offset(100, 100),
          );
        });
      } else {
        Fluttertoast.showToast(
            msg: "Cannot extract dimensions from the command.");
      }
    } else if (tokens.contains("base") && !tokens.contains("by")) {
      setState(() {
        _floorPlanController.setDefaultBase();
      });
    } else if (tokens.contains("room") && !tokens.contains("by")) {
      setState(() {
        _floorPlanController.addDefaultRoom();
      });
    } else {
      Fluttertoast.showToast(msg: "Invalid Command.");
    }
    _isListening = false;
    setState(() {});
  }

  // void _onCommandRecognized(String command) {
  //   _voiceCommandController.handleCommand(command);
  //   setState(() {});
  // }

  void _startListening() {
    _isListening = true;
    setState(() {});
    _speechService.listen(_onCommand);
    if (_isListening) {
    } else {
      Fluttertoast.showToast(msg: "Cannot listen due to an error");
    }
  }

  void _stopListening() {
    _speechService.stopListening();
    setState(() {
      _isListening = false;
    });
    Fluttertoast.showToast(msg: "Stopped listening, manually.");
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // _animationController = AnimationController(duration: const Duration(seconds: 2),vsync: this,);
    // _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_animationController);
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
          ElevatedButton(
            onPressed: _isListening ? _stopListening : _startListening,
            child: _isListening
                ? const Text("Stop Listening")
                : const Text("Start Listening"),
          ),
        ],
      ),
    );
  }
}
