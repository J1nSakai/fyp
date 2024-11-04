import 'package:flutter/material.dart';

enum MessageType { info, success, error, warning }

class MessageService {
  static void showMessage(BuildContext context, String message,
      {MessageType type = MessageType.info}) {
    // Remove any existing SnackBar
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            _getIconForType(type),
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: _getColorForType(type),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height - 100, // Position from top
        right: 20,
        left: 20,
      ),
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      action: SnackBarAction(
        label: 'Dismiss',
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static IconData _getIconForType(MessageType type) {
    switch (type) {
      case MessageType.success:
        return Icons.check_circle_outline;
      case MessageType.error:
        return Icons.error_outline;
      case MessageType.warning:
        return Icons.warning_amber_rounded;
      case MessageType.info:
      default:
        return Icons.info_outline;
    }
  }

  static Color _getColorForType(MessageType type) {
    switch (type) {
      case MessageType.success:
        return Colors.green.withOpacity(0.9);
      case MessageType.error:
        return Colors.red.withOpacity(0.9);
      case MessageType.warning:
        return Colors.orange.withOpacity(0.9);
      case MessageType.info:
      default:
        return Colors.blue.withOpacity(0.9);
    }
  }
}
