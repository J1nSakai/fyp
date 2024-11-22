import 'package:flutter/material.dart';
import 'package:saysketch_v2/controllers/floor_manager_controller.dart';
import 'package:saysketch_v2/models/room_model.dart';
import 'package:saysketch_v2/models/door.dart';
import 'package:saysketch_v2/models/stairs.dart';
import 'package:saysketch_v2/models/window.dart';

import '../../models/cut_out.dart';
import '../../models/space.dart';
import 'info_row.dart';
import 'info_section.dart';
import 'simple_door_info_tile.dart';
import 'simple_window_info_tile.dart';
import 'simple_space_info_tile.dart';

class EntityInfoPanel extends StatelessWidget {
  final FloorManagerController floorManagerController;

  const EntityInfoPanel({
    super.key,
    required this.floorManagerController,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    var controller = floorManagerController.getActiveController();
    Room? selectedRoom = controller?.selectedRoom;
    Stairs? selectedStairs = controller?.selectedStairs;
    Door? selectedDoor = controller?.selectedDoor;
    Window? selectedWindow = controller?.selectedWindow;
    CutOut? selectedCutOut = controller?.selectedCutOut;
    Space? selectedSpace = controller?.selectedSpace;

    bool hasSelection = selectedRoom != null ||
        selectedStairs != null ||
        selectedDoor != null ||
        selectedWindow != null ||
        selectedCutOut != null ||
        selectedSpace != null;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      offset: Offset(hasSelection ? 0 : 1, 0),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: hasSelection ? 1.0 : 0.0,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              left: BorderSide(
                color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                  border: Border(
                    bottom: BorderSide(
                      color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getHeaderTitle(
                          selectedRoom,
                          selectedStairs,
                          selectedDoor,
                          selectedWindow,
                          selectedCutOut,
                          selectedSpace),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // MouseRegion(
                    //   cursor: SystemMouseCursors.click,
                    //   child: GestureDetector(
                    //     onTap: () {
                    //       if (selectedWindow != null) {
                    //         controller?.deselectWindow();
                    //       } else if (selectedDoor != null) {
                    //         controller?.deselectDoor();
                    //       } else if (selectedRoom != null) {
                    //         controller?.deselectRoom();
                    //       } else if (selectedStairs != null) {
                    //         controller?.deselectStairs();
                    //       } else if (selectedCutOut != null) {
                    //         controller?.deselectCutOut();
                    //       } else if (selectedSpace != null) {
                    //         controller?.deselectSpace();
                    //       }
                    //     },
                    //     child: const Icon(Icons.close, size: 20),
                    //   ),
                    // ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildContent(
                        context,
                        selectedRoom,
                        selectedStairs,
                        selectedDoor,
                        selectedWindow,
                        selectedCutOut,
                        selectedSpace),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getHeaderTitle(Room? room, Stairs? stairs, Door? door, Window? window,
      CutOut? cutOut, Space? space) {
    if (window != null) return 'Window Details';
    if (door != null) return 'Door Details';
    if (room != null) return 'Room Details';
    if (stairs != null) return 'Stairs Details';
    if (cutOut != null) return 'Cutout Details';
    if (space != null) return 'Space Details';
    return '';
  }

  Widget _buildContent(BuildContext context, Room? room, Stairs? stairs,
      Door? door, Window? window, CutOut? cutOut, Space? space) {
    if (window != null) {
      return _buildWindowDetails(context, window);
    } else if (door != null) {
      return _buildDoorDetails(context, door);
    } else if (room != null) {
      return _buildRoomDetails(context, room);
    } else if (stairs != null) {
      return _buildStairsDetails(context, stairs);
    } else if (cutOut != null) {
      return _buildCutOutDetails(context, cutOut);
    } else if (space != null) {
      return _buildSpaceDetails(context, space);
    }
    return const SizedBox.shrink();
  }

  Widget _buildRoomDetails(BuildContext context, Room room) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Room Properties
        InfoSection(
          title: 'Properties',
          children: [
            InfoRow(
                label: 'Name',
                value:
                    '${room.name[0].toUpperCase()}${room.name.substring(1)}'),
            InfoRow(label: 'Width', value: '${room.width}ft'),
            InfoRow(label: 'Height', value: '${room.height}ft'),
            InfoRow(
              label: 'Position',
              value: '(${room.position.dx}ft, ${room.position.dy}ft)',
            ),
          ],
        ),

        // Doors Section
        if (room.doors.isNotEmpty)
          InfoSection(
            title: 'Doors (${room.doors.length})',
            children: room.doors
                .map((door) => SimpleDoorInfoTile(door: door))
                .toList(),
          ),

        // Windows Section
        if (room.windows.isNotEmpty)
          InfoSection(
            title: 'Windows (${room.windows.length})',
            children: room.windows
                .map((window) => SimpleWindowInfoTile(window: window))
                .toList(),
          ),

        // Spaces Section
        if (room.spaces.isNotEmpty)
          InfoSection(
            title: 'Spaces (${room.spaces.length})',
            children: room.spaces
                .map((space) => SimpleSpaceInfoTile(space: space))
                .toList(),
          ),
      ],
    );
  }

  // New method for detailed door info
  Widget _buildDoorDetails(BuildContext context, Door door) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoSection(
          title: 'Door Properties',
          children: [
            InfoRow(label: 'Name', value: "Door ${door.id.split(':').last}"),
            InfoRow(label: 'Wall', value: door.wall),
            InfoRow(
                label: 'Width',
                value: '${double.parse(door.width.toStringAsFixed(2))}ft'),
            InfoRow(
                label: 'Offset',
                value:
                    '${double.parse(door.offsetFromWallStart.toStringAsFixed(2))}ft'),
            InfoRow(
                label: 'Swing', value: door.swingInward ? "Inward" : "Outward"),
            InfoRow(label: 'Opens', value: door.openLeft ? "Left" : "Right"),
            if (door.connectedDoor != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.link,
                        size: 16, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Connected Door',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStairsDetails(BuildContext context, Stairs stairs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoSection(
          title: 'Properties',
          children: [
            InfoRow(
                label: 'Name',
                value:
                    '${stairs.name[0].toUpperCase()}${stairs.name.substring(1)}'),
            InfoRow(
                label: 'Width',
                value: '${double.parse(stairs.width.toStringAsFixed(2))}ft'),
            InfoRow(
                label: 'Length',
                value: '${double.parse(stairs.length.toStringAsFixed(2))}ft'),
            InfoRow(
              label: 'Position',
              value: '(${stairs.position.dx}ft, ${stairs.position.dy}ft)',
            ),
            InfoRow(
              label: 'Direction',
              value: stairs.direction.toUpperCase(),
            ),
          ],
        ),
      ],
    );
  }

  // Add new method for window details
  Widget _buildWindowDetails(BuildContext context, Window window) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoSection(
          title: 'Window Properties',
          children: [
            InfoRow(
                label: 'Name', value: "Window ${window.id.split(':').last}"),
            InfoRow(label: 'Wall', value: window.wall),
            InfoRow(
                label: 'Width',
                value: '${double.parse(window.width.toStringAsFixed(2))}ft'),
            InfoRow(
                label: 'Offset',
                value:
                    '${double.parse(window.offsetFromWallStart.toStringAsFixed(2))}ft'),
            if (window.connectedWindow != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.link, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Connected Window',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  // Add new method for cutout details
  Widget _buildCutOutDetails(BuildContext context, CutOut cutOut) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cutout Properties
        InfoSection(
          title: 'Properties',
          children: [
            InfoRow(
                label: 'Name',
                value:
                    '${cutOut.name[0].toUpperCase()}${cutOut.name.substring(1)}'),
            InfoRow(
                label: 'Width',
                value: '${double.parse(cutOut.width.toStringAsFixed(2))}ft'),
            InfoRow(
                label: 'Height',
                value: '${double.parse(cutOut.height.toStringAsFixed(2))}ft'),
            InfoRow(
              label: 'Position',
              value: '(${cutOut.position.dx}ft, ${cutOut.position.dy}ft)',
            ),
          ],
        ),

        // Doors Section
        if (cutOut.doors.isNotEmpty)
          InfoSection(
            title: 'Doors (${cutOut.doors.length})',
            children: cutOut.doors
                .map((door) => SimpleDoorInfoTile(door: door))
                .toList(),
          ),

        // Windows Section
        if (cutOut.windows.isNotEmpty)
          InfoSection(
            title: 'Windows (${cutOut.windows.length})',
            children: cutOut.windows
                .map((window) => SimpleWindowInfoTile(window: window))
                .toList(),
          ),

        // Spaces Section
        if (cutOut.spaces.isNotEmpty)
          InfoSection(
            title: 'Spaces (${cutOut.spaces.length})',
            children: cutOut.spaces
                .map((space) => SimpleSpaceInfoTile(space: space))
                .toList(),
          ),
      ],
    );
  }

  // Add method for detailed space info
  Widget _buildSpaceDetails(BuildContext context, Space space) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoSection(
          title: 'Space Properties',
          children: [
            InfoRow(label: 'Name', value: "Space ${space.id.split(':').last}"),
            InfoRow(label: 'Wall', value: space.wall),
            InfoRow(
                label: 'Width',
                value: '${double.parse(space.width.toStringAsFixed(2))}ft'),
            InfoRow(
                label: 'Offset',
                value:
                    '${double.parse(space.offsetFromWallStart.toStringAsFixed(2))}ft'),
            if (space.connectedSpace != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.link, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Connected Space',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
