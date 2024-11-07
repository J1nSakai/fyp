import 'package:flutter/material.dart';

enum MessageType { info, success, error, warning }

class MessageService {
  static void showMessage(BuildContext context, String message,
      {MessageType type = MessageType.info}) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    final snackBar = SnackBar(
      content: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _getGradientForType(type),
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Icon with subtle animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Icon(
                    _getIconForType(type),
                    color: Colors.white,
                    size: 24,
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            // Message text
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Dismiss button
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              icon: const Icon(
                Icons.close,
                color: Colors.white70,
                size: 20,
              ),
              label: const Text(
                'Dismiss',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: _getColorForType(type),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        bottom: MediaQuery.sizeOf(context).height - 80, // Adjusted position
        right: 20,
        left: 20,
      ),
      elevation: 6, // Added shadow
      duration: const Duration(seconds: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      animation: CurvedAnimation(
        parent: const AlwaysStoppedAnimation(1),
        curve: Curves.easeOutCubic,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static IconData _getIconForType(MessageType type) {
    switch (type) {
      case MessageType.success:
        return Icons.check_circle_rounded; // Changed to rounded icons
      case MessageType.error:
        return Icons.error_rounded;
      case MessageType.warning:
        return Icons.warning_rounded;
      case MessageType.info:
      default:
        return Icons.info_rounded;
    }
  }

  static Color _getColorForType(MessageType type) {
    switch (type) {
      case MessageType.success:
        return const Color(0xFF2E7D32); // Material Design colors
      case MessageType.error:
        return const Color(0xFFD32F2F);
      case MessageType.warning:
        return const Color(0xFFF57C00);
      case MessageType.info:
      default:
        return const Color(0xFF1976D2);
    }
  }

  // Helper method for gradient backgrounds (optional)
  static List<Color> _getGradientForType(MessageType type) {
    final baseColor = _getColorForType(type);
    return [
      baseColor,
      baseColor.withOpacity(0.8),
    ];
  }
}
