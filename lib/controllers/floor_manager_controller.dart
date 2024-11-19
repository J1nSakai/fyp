import 'package:flutter/material.dart';
import 'package:saysketch_v2/controllers/floor_plan_controller.dart';
import 'package:saysketch_v2/models/floor_model.dart';
import 'package:saysketch_v2/services/message_service.dart';
import 'dart:convert';
import 'dart:html' as html;

class FloorManagerController extends ChangeNotifier {
  final List<Floor> _floors = [];
  Floor? _activeFloor;
  final BuildContext context;

  FloorManagerController(this.context) {
    // Create first floor by default
    Floor firstFloor = Floor(
      level: 0, // Level 0 represents first floor
      controller: FloorPlanController(),
      isActive: true, // First floor is active by default
    );

    _floors.add(firstFloor);
    _activeFloor = firstFloor;
    notifyListeners(); // Notify listeners after initialization
  }

  Floor? get activeFloor => _activeFloor;
  List<Floor> get floors =>
      List.unmodifiable(_floors); // Return unmodifiable list

  void addNewFloor() {
    int newLevel = _floors.length;
    Floor newFloor = Floor(
      level: newLevel,
      controller: FloorPlanController(),
      isActive: true,
    );

    // Deactivate current floor
    if (_activeFloor != null) {
      _activeFloor!.isActive = false;
    }

    _floors.add(newFloor);
    _activeFloor = newFloor;

    MessageService.showMessage(
      context,
      "Floor ${newLevel + 1} created and activated",
      type: MessageType.success,
    );

    notifyListeners(); // Notify after floor addition
  }

  void switchToFloor(int level) {
    if (level < 0 || level >= _floors.length) {
      MessageService.showMessage(
        context,
        "Floor ${level + 1} does not exist",
        type: MessageType.error,
      );
      return;
    }

    // Only switch if it's a different floor
    if (_activeFloor?.level != level) {
      if (_activeFloor != null) {
        _activeFloor!.isActive = false;
      }

      _activeFloor = _floors[level];
      _activeFloor!.isActive = true;

      MessageService.showMessage(
        context,
        "Switched to Floor ${level + 1}",
        type: MessageType.info,
      );
      notifyListeners(); // Notify after floor switch
    } else {
      MessageService.showMessage(
        context,
        "Already on Floor ${level + 1}",
        type: MessageType.warning,
      );
    }
  }

  FloorPlanController? getActiveController() {
    return _activeFloor?.controller;
  }

  void saveToFile() async {
    try {
      // Capture context early
      final currentContext = context;

      TextEditingController fileNameController =
          TextEditingController(text: 'floorplan.json');

      // Show a dialog to get the file name
      String? fileName = await showDialog<String>(
        context: currentContext, // Use captured context
        builder: (BuildContext context) {
          return Dialog(
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    children: [
                      Text(
                        'Save As',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        onPressed: () => Navigator.pop(context),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // File name input
                  TextField(
                    controller: fileNameController,
                    decoration: InputDecoration(
                      labelText: 'File name',
                      labelStyle: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                      hintText: 'Enter file name',
                      hintStyle: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // File extension hint
                  Text(
                    '*.json',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          String tempFileName = fileNameController.text;
                          if (!tempFileName.toLowerCase().endsWith('.json')) {
                            tempFileName += '.json';
                          }
                          Navigator.pop(context, tempFileName);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );

      // If user cancelled the dialog
      if (fileName == null) {
        return;
      }

      // Create a JSON representation of all floors
      final data = {
        'floors': _floors
            .map((floor) => {
                  'level': floor.level,
                  'floorData': floor.controller.toJson(),
                })
            .toList(),
      };

      // Convert to JSON string
      final jsonString = jsonEncode(data);

      // Create blob and download link
      final bytes = utf8.encode(jsonString);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Chain the download operations
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();

      // Clean up
      html.Url.revokeObjectUrl(url);

      MessageService.showMessage(
        currentContext, // Use captured context
        "Floor plan saved successfully as '$fileName'",
        type: MessageType.success,
      );
    } catch (e) {
      MessageService.showMessage(
        context,
        "Error saving floor plan: $e",
        type: MessageType.error,
      );
    }
  }

  void loadFromFile() {
    // Capture context early
    final currentContext = context;

    try {
      // Create file input element
      final uploadInput = html.FileUploadInputElement();
      uploadInput.accept = '.json';
      uploadInput.click();

      uploadInput.onChange.listen((event) {
        final file = uploadInput.files!.first;
        final reader = html.FileReader();

        reader.onLoad.listen((event) {
          try {
            final jsonString = reader.result as String;
            final data = jsonDecode(jsonString);

            // Clear existing floors
            _floors.clear();
            _activeFloor = null;

            // Load floors from file
            for (var floorData in data['floors']) {
              final controller =
                  FloorPlanController.fromJson(floorData['floorData']);
              final floor = Floor(
                level: floorData['level'],
                controller: controller,
                isActive: false,
              );
              _floors.add(floor);
            }

            // Activate first floor
            if (_floors.isNotEmpty) {
              _activeFloor = _floors.first;
              _activeFloor!.isActive = true;
            }

            notifyListeners();

            MessageService.showMessage(
              currentContext, // Use captured context
              "Floor plan loaded successfully",
              type: MessageType.success,
            );
          } catch (e) {
            MessageService.showMessage(
              currentContext, // Use captured context
              "Error parsing floor plan file: $e",
              type: MessageType.error,
            );
          }
        });

        reader.readAsText(file);
      });
    } catch (e) {
      MessageService.showMessage(
        currentContext, // Use captured context
        "Error loading floor plan: $e",
        type: MessageType.error,
      );
    }
  }
}
