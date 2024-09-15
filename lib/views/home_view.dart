import 'package:flutter/material.dart';
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
  final FloorPlanController _controller = FloorPlanController();
  final SpeechToTextService _speechService = SpeechToTextService();

  // AnimationController? _animationController;
  // Animation<double>? _fadeAnimation;

  void _onCommandRecognized(String command) {
    Map<String, double> dimensions =
        VoiceCommandController.extractMeasurements(command);

    if (dimensions.isNotEmpty) {
      setState(() {
        _controller.addRoom(
          dimensions['width']!,
          dimensions['height']!,
          const Offset(100, 100),
        );
      });
    } else {
      print("Cannot extract dimensions from the command.");
    }
  }

  void _onCommand(String command) {
    if (command.contains("base") && !command.contains("by")) {
      setState(() {
        _controller.setDefaultBase();
      });
    } else if (command.contains("base") && command.contains("by")) {
      Map<String, double> dimensions =
          VoiceCommandController.extractMeasurements(command);

      if (dimensions.isNotEmpty) {
        setState(() {
          _controller.setBase(
            dimensions['width']!,
            dimensions['height']!,
            const Offset(100, 100),
          );
        });
      } else {
        print("Cannot extract dimensions from the command.");
      }
    } else {
      print("Invalid Command");
    }
  }

  void _startListening() {
    _speechService.listen(_onCommand);
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
        title: const Text("Floor Plan App"),
      ),
      body: Column(
        children: [
          Expanded(child: FloorPlanView(controller: _controller)),
          ElevatedButton(
              onPressed: _startListening, child: const Text("Start Listening")),
        ],
      ),
    );
  }
}
