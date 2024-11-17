import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:saysketch_v2/controllers/floor_manager_controller.dart';
import 'package:saysketch_v2/controllers/command_controller.dart';
import 'package:saysketch_v2/services/speech_to_text_service.dart';
import 'package:saysketch_v2/views/floor_selector_view.dart';
import 'package:saysketch_v2/views/widgets/entity_info_panel.dart';
import 'floor_plan_view.dart';
import 'widgets/command_history_panel.dart';
import 'widgets/compass_widget.dart';

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
  final List<CommandEntry> _commandHistory = [];
  bool _showCommandHistory = false;
  bool _showTextField = false;
  bool _showSettings = false;
  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _floorManager = FloorManagerController(context);
    _commandController = CommandController(_floorManager);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onCommand(String command) {
    _commandController.handleCommand(command, context);
    setState(() {
      _commandHistory.add(CommandEntry(
        text: command,
        isVoice: _isListening,
      ));
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
      _commandController.handleCommand(text.trim(), context);
      setState(() {
        _commandHistory.add(CommandEntry(
          text: text.trim(),
          isVoice: false,
        ));
      });
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
    return ChangeNotifierProvider<FloorManagerController>.value(
      value: _floorManager,
      child: Scaffold(
        body: Column(
          children: [
            // Modern App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Row(
                children: [
                  Row(
                    children: [
                      Semantics(
                        label: "V-Architect Logo",
                        image: true,
                        child: SvgPicture.asset(
                          'app_icon/new_icon.svg',
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "V-Architect",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Settings and other action buttons
                  Row(
                    children: [
                      _buildActionButton(
                        icon: _showSettings
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        label: _showSettings
                            ? 'hide more options'
                            : 'show more options',
                        onPressed: () =>
                            setState(() => _showSettings = !_showSettings),
                        isActive: _showSettings,
                      ),
                      Container(
                        height: 24,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: VerticalDivider(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                          thickness: 1,
                        ),
                      ),
                      _buildActionButton(
                        icon: Icons.history,
                        label: 'history',
                        onPressed: () => setState(
                            () => _showCommandHistory = !_showCommandHistory),
                        isActive: _showCommandHistory,
                      ),
                      Container(
                        height: 24,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: VerticalDivider(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                          thickness: 1,
                        ),
                      ),
                      _buildActionButton(
                        icon: Icons.help_outline,
                        label: 'help',
                        onPressed: () => _showCommandsDialog(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Settings Shutter
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _showSettings ? 64 : 0,
              curve: Curves.easeInOut,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.95),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Theme Toggle
                      _buildSettingsButton(
                        icon: _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        label: _isDarkMode ? 'light mode' : 'dark mode',
                        onPressed: () =>
                            Provider.of<VoidCallback>(context, listen: false)(),
                      ),
                      const SizedBox(width: 16),
                      // Save Button
                      _buildSettingsButton(
                        icon: Icons.save,
                        label: 'save',
                        onPressed: () => _floorManager.saveToFile(),
                      ),
                      const SizedBox(width: 16),
                      // Load Button
                      _buildSettingsButton(
                        icon: Icons.file_upload,
                        label: 'load',
                        onPressed: () => _floorManager.loadFromFile(),
                      ),
                    ],
                  ),
                ),
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
                    child: const Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            "Floor Plans",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        FloorSelectorView(),
                      ],
                    ),
                  ),
                  // Main Floor Plan View
                  Expanded(
                    child: Row(
                      children: [
                        // Main Floor Plan View (now with reduced width to accommodate info panel)
                        Expanded(
                          flex: 4,
                          child: Stack(
                            children: [
                              Consumer<FloorManagerController>(
                                builder: (context, floorManager, _) =>
                                    FloorPlanView(
                                  controller:
                                      floorManager.getActiveController()!,
                                ),
                              ),
                              // Add Compass in top-right corner
                              Positioned(
                                top: 16,
                                right: 16,
                                child: Semantics(
                                  label:
                                      "Compass showing North, East, South, and West directions",
                                  child: const CompassWidget(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Info Panel with Animation
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: _shouldShowInfoPanel()
                              ? MediaQuery.of(context).size.width * 0.2
                              : 0,
                          curve: Curves.easeInOut,
                          child: OverflowBox(
                            alignment: Alignment.centerRight,
                            maxWidth: MediaQuery.of(context).size.width * 0.2,
                            child: EntityInfoPanel(
                              floorManagerController: _floorManager,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _showCommandHistory ? 300 : 0,
                    curve: Curves.easeInOut,
                    child: OverflowBox(
                      alignment: Alignment.topRight,
                      minWidth: 0,
                      maxWidth: 300,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _showCommandHistory ? 1.0 : 0.0,
                        child: CommandHistoryPanel(
                          commands: _commandHistory,
                          onClose: () =>
                              setState(() => _showCommandHistory = false),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Command Input Bar at Bottom
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Buttons Container with Animation
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    transform: Matrix4.translationValues(
                      _showTextField ? 0 : 0, // Slide from center to right
                      0,
                      0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Keyboard Toggle Button
                        if (!_showTextField)
                          Semantics(
                            button: true,
                            label: "Show text input",
                            child: Tooltip(
                              message: "Use text commands",
                              child: Material(
                                elevation: 4,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  height: 64,
                                  width: 64,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.keyboard,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: 28,
                                    ),
                                    onPressed: () {
                                      setState(() => _showTextField = true);
                                      Future.delayed(
                                          const Duration(milliseconds: 50), () {
                                        _focusNode.requestFocus();
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 24),
                        // Microphone Button
                        Semantics(
                          button: true,
                          enabled: true,
                          label: _isListening ? "stop listening" : "listen",
                          hint: _isListening
                              ? "Click to stop voice input"
                              : "Click to start voice input",
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 64,
                              width: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: _isListening
                                      ? [
                                          Theme.of(context).colorScheme.error,
                                          Theme.of(context)
                                              .colorScheme
                                              .error
                                              .withRed(255),
                                        ]
                                      : [
                                          Theme.of(context)
                                              .colorScheme
                                              .tertiary,
                                          Theme.of(context)
                                              .colorScheme
                                              .tertiary
                                              .withRed(255),
                                        ],
                                ),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  _isListening ? Icons.mic_off : Icons.mic,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                onPressed: _isListening
                                    ? _stopListening
                                    : _startListening,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Text Field with Animation
                  if (_showTextField)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      right: 32,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Close Text Field Button
                          Semantics(
                            button: true,
                            label: "Hide text input",
                            child: IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: () =>
                                  setState(() => _showTextField = false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Text Field
                          Container(
                            width: 300,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: TextField(
                              controller: _controller,
                              decoration: InputDecoration(
                                hintText: "Type your command here...",
                                hintStyle: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.5),
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 15,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.8),
                              ),
                              onSubmitted: (text) {
                                _handleTextCommand(text);
                                _controller.clear();
                                _focusNode.requestFocus();
                              },
                              focusNode: _focusNode,
                            ),
                          ),
                          const SizedBox(width: 24),
                        ],
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
          Semantics(
            button: true,
            label: "Close",
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Semantics(
      button: true,
      enabled: true,
      label: label,
      child: Tooltip(
        message: label,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: IconButton(
            icon: Icon(
              icon,
              color: isActive
                  ? Theme.of(context).colorScheme.tertiary
                  : Colors.white.withOpacity(0.9),
            ),
            onPressed: onPressed,
            hoverColor: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: label,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white.withOpacity(0.9)),
        label: Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  bool _shouldShowInfoPanel() {
    final controller = _floorManager.getActiveController();
    return controller?.selectedRoom != null ||
        controller?.selectedStairs != null ||
        controller?.selectedDoor != null ||
        controller?.selectedWindow != null ||
        controller?.selectedCutOut != null ||
        controller?.selectedSpace != null;
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
