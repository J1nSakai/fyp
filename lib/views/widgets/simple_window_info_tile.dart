import 'package:flutter/material.dart';
import 'package:saysketch_v2/models/window.dart';

class SimpleWindowInfoTile extends StatelessWidget {
  final Window window;

  const SimpleWindowInfoTile({super.key, required this.window});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        children: [
          Icon(
            Icons.window,
            size: 16,
            color: theme.colorScheme.onSurface,
          ),
          const SizedBox(width: 8),
          Text(
            "Window ${window.id.split(':').last}",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Text(
            window.wall,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: 12,
            ),
          ),
          if (window.connectedWindow != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                Icons.link,
                size: 14,
                color: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}
