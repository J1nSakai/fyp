import 'package:flutter/material.dart';

class CommandHistoryPanel extends StatelessWidget {
  final List<CommandEntry> commands;
  final VoidCallback onClose;

  const CommandHistoryPanel({
    super.key,
    required this.commands,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final reversedCommands = commands.reversed.toList();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Material(
      elevation: 8,
      color: theme.colorScheme.surface,
      child: Container(
        width: 300,
        height: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            left: BorderSide(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    'Command History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Semantics(
                    button: true,
                    enabled: true,
                    label: "close",
                    child: IconButton(
                      icon: Icon(
                        Icons.close,
                        color: theme.colorScheme.onSurface,
                      ),
                      onPressed: onClose,
                      tooltip: 'Close',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Scrollbar(
                thickness: 8,
                radius: const Radius.circular(4),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: reversedCommands.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  ),
                  itemBuilder: (context, index) {
                    final command = reversedCommands[index];
                    return Semantics(
                      label: "Command: ${command.text}",
                      hint: command.isVoice ? "Voice command" : "Text command",
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          command.isVoice ? Icons.mic : Icons.keyboard,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          size: 20,
                        ),
                        title: Text(
                          command.text,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  },
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommandEntry {
  final String text;
  final bool isVoice;

  CommandEntry({
    required this.text,
    required this.isVoice,
  });
}
