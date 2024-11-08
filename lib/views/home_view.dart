import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saysketch_v2/controllers/floor_manager_controller.dart';
import 'package:saysketch_v2/controllers/command_controller.dart';
import 'package:saysketch_v2/services/speech_to_text_service.dart';
import 'package:saysketch_v2/views/floor_selector_view.dart';
import 'package:saysketch_v2/views/widgets/entity_info_panel.dart';
import 'floor_plan_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final FloorManagerController _floorManager;
  late final CommandController _commandController;
  final SpeechToTextService _speechService = SpeechToTextService();
  bool _isListening = false;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _floorManager = FloorManagerController(context);
    _commandController = CommandController(_floorManager);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    setState(() {});
  }

  void _onCommand(String command) {
    _commandController.handleCommand(command, context);
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
  }

  void _handleTextCommand(String text) {
    if (text.isNotEmpty) {
      _onCommand(text.trim());
      _focusNode.requestFocus();
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
    return ListenableProvider<FloorManagerController>.value(
      value: _floorManager,
      child: Scaffold(
        body: Column(
          children: [
            // Modern App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text(
                    "SaySketch",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.help_outline, color: Colors.white),
                    onPressed: () => _showCommandsDialog(context),
                  ),
                ],
              ),
            ),
            // Main Content
            Expanded(
              child: Row(
                children: [
                  // Left Sidebar
                  Container(
                    width: 250,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            "Floor Plans",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const FloorSelectorView(),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton.icon(
                            onPressed: () => _floorManager
                                .getActiveController()
                                ?.addNextRoom(),
                            icon: const Icon(Icons.add),
                            label: const Text("Add Next Room"),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(45),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Main Floor Plan View
                  Expanded(
                    child: Row(
                      children: [
                        // Main Floor Plan View (now with reduced width to accommodate info panel)
                        Expanded(
                          flex:
                              4, // Takes 80% of the space when info panel is shown
                          child: Consumer<FloorManagerController>(
                            builder: (context, floorManager, _) =>
                                FloorPlanView(
                              controller: floorManager.getActiveController()!,
                            ),
                          ),
                        ),
                        // Info Panel
                        if (_floorManager.getActiveController()?.selectedRoom !=
                                null ||
                            _floorManager
                                    .getActiveController()
                                    ?.selectedStairs !=
                                null)
                          Expanded(
                            flex: 1, // Takes 20% of the space
                            child: EntityInfoPanel(
                              floorManagerController: _floorManager,
                            ),
                          ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            // Command Input Bar at Bottom
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Icon(Icons.keyboard, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: const InputDecoration(
                                hintText: "Type your command here...",
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 16),
                              ),
                              onSubmitted: _handleTextCommand,
                              focusNode: _focusNode,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isListening ? Icons.mic_off : Icons.mic,
                              color:
                                  _isListening ? Colors.red : Colors.grey[600],
                            ),
                            onPressed:
                                _isListening ? _stopListening : _startListening,
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommandsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Available Commands"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommandItem(
                command: "create base", description: "Create a new floor base"),
            CommandItem(command: "add room", description: "Add a new room"),
            CommandItem(
                command: "another room", description: "Add another room"),
            CommandItem(
                command: "remove base", description: "Remove the floor base"),
            CommandItem(
                command: "remove rooms", description: "Remove all rooms"),
            CommandItem(
                command: "remove last room",
                description: "Remove the last room"),
            CommandItem(
                command: "add new floor", description: "Add a new floor"),
            CommandItem(
                command: "switch to floor X",
                description: "Switch to specified floor"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}

class CommandItem extends StatelessWidget {
  final String command;
  final String description;

  const CommandItem({
    super.key,
    required this.command,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "• $command",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "- $description",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}
