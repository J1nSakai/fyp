import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:saysketch_v2/controllers/floor_plan_controller.dart';
import 'package:saysketch_v2/controllers/command_controller.dart';
import 'package:saysketch_v2/services/speech_to_text_service.dart';
import 'floor_plan_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final FloorPlanController _floorPlanController = FloorPlanController();
  late final CommandController _commandController;
  final SpeechToTextService _speechService = SpeechToTextService();
  bool _isListening = false;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _commandController = CommandController(_floorPlanController);
  }

  void _onCommand(String command) {
    _commandController.handleCommand(command);
    setState(() {
      _isListening = false;
    });
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
