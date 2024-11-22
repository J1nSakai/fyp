import 'package:flutter/material.dart';

class CommandDetails {
  final String command;
  final String description;
  final List<String>? variations;
  final String? imagePath;

  CommandDetails({
    required this.command,
    required this.description,
    this.variations,
    this.imagePath,
  });
}

class VoiceCommandsDialog extends StatefulWidget {
  const VoiceCommandsDialog({super.key});

  @override
  State<VoiceCommandsDialog> createState() => _VoiceCommandsDialogState();
}

class _VoiceCommandsDialogState extends State<VoiceCommandsDialog> {
  CommandDetails? _selectedCommand;
  final List<CommandDetails> baseCommands = [
    CommandDetails(
      command: 'create base',
      description:
          'Creates a new floor base with default dimensions. This is typically the first command you\'ll use when starting a new floor plan.',
      variations: ['new base', 'add base', 'create base'],
    ),
    // Add more commands...
  ];

  Widget _buildCommandCategory(String title, IconData icon,
      {bool isSelected = false}) {
    return Container(
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        selected: isSelected,
        onTap: () {
          // Handle category selection
        },
      ),
    );
  }

  Widget _buildCommandDetailsView(CommandDetails command) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          if (command.imagePath != null) ...[
            Text(
              'Example',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Image.asset(
              command.imagePath!,
              fit: BoxFit.contain,
              height: 200,
            ),
            const SizedBox(height: 24),
          ],
          const SizedBox(height: 8),
          Text(
            command.description,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          if (command.variations != null && command.variations!.isNotEmpty) ...[
            Text(
              'Variations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            ...command.variations!.map(
              (variation) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• "$variation"',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 800,
        height: 600,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              // Dialog Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Row(
                  children: [
                    if (_selectedCommand != null)
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        onPressed: () =>
                            setState(() => _selectedCommand = null),
                      ),
                    Text(
                      _selectedCommand?.command ?? 'Voice Commands',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Main Content
              Expanded(
                child: Row(
                  children: [
                    // Left Navigation Panel (Categories)
                    Container(
                      width: 250,
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      child: ListView(
                        children: [
                          _buildCommandCategory(
                            'Base Commands',
                            Icons.home,
                            isSelected: true,
                          ),
                          _buildCommandCategory(
                            'Room Commands',
                            Icons.square_outlined,
                          ),
                          _buildCommandCategory(
                            'Stairs Commands',
                            Icons.stairs,
                          ),
                          _buildCommandCategory(
                            'Door Commands',
                            Icons.door_front_door,
                          ),
                          _buildCommandCategory(
                            'Window Commands',
                            Icons.window,
                          ),
                          _buildCommandCategory(
                            'Space Commands',
                            Icons.space_bar,
                          ),
                          _buildCommandCategory(
                            'Cutout Commands',
                            Icons.cut,
                          ),
                          // ... other categories
                        ],
                      ),
                    ),
                    // Right Content Panel
                    Expanded(
                      child: _selectedCommand == null
                          ? Container(
                              color: Theme.of(context).colorScheme.surface,
                              child: ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  Text(
                                    'This category of commands will help you manage entities in your floor plan.',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Commands',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ...baseCommands.map((cmd) => InkWell(
                                        onTap: () => setState(
                                            () => _selectedCommand = cmd),
                                        child: Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surface,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .dividerColor,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.chevron_right,
                                                size: 20,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(cmd.command),
                                            ],
                                          ),
                                        ),
                                      )),
                                ],
                              ),
                            )
                          : _buildCommandDetailsView(_selectedCommand!),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
