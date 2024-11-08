import 'package:flutter/material.dart';
import 'package:saysketch_v2/controllers/floor_manager_controller.dart';
import 'package:saysketch_v2/models/room_model.dart';
import 'package:saysketch_v2/models/door.dart';
import 'package:saysketch_v2/models/stairs.dart';

import 'info_row.dart';
import 'info_section.dart';
import 'simple_door_info_tile.dart';

class EntityInfoPanel extends StatelessWidget {
  final FloorManagerController floorManagerController;

  const EntityInfoPanel({
    super.key,
    required this.floorManagerController,
  });

  @override
  Widget build(BuildContext context) {
    var controller = floorManagerController.getActiveController();
    Room? selectedRoom = controller?.selectedRoom;
    Stairs? selectedStairs = controller?.selectedStairs;
    Door? selectedDoor = controller?.selectedDoor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(
            color: Colors.grey[300]!,
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
              color: Colors.grey[100],
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getHeaderTitle(selectedRoom, selectedStairs, selectedDoor),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      if (selectedDoor != null) {
                        controller?.deselectDoor();
                      } else if (selectedRoom != null) {
                        controller?.deselectRoom();
                      } else if (selectedStairs != null) {
                        controller?.deselectStairs();
                      }
                    },
                    child: const Icon(Icons.close, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildContent(
                    context, selectedRoom, selectedStairs, selectedDoor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getHeaderTitle(Room? room, Stairs? stairs, Door? door) {
    if (door != null) return 'Door Details';
    if (room != null) return 'Room Details';
    if (stairs != null) return 'Stairs Details';
    return '';
  }

  Widget _buildContent(
      BuildContext context, Room? room, Stairs? stairs, Door? door) {
    if (door != null) {
      return _buildDoorDetails(context, door);
    } else if (room != null) {
      return _buildRoomDetails(context, room);
    } else if (stairs != null) {
      return _buildStairsDetails(context, stairs);
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

        // Doors Section (simplified when no door is selected)
        if (room.doors.isNotEmpty)
          InfoSection(
            title: 'Doors (${room.doors.length})',
            children: room.doors
                .map((door) => SimpleDoorInfoTile(door: door))
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
            InfoRow(label: 'Name', value: "door ${door.id.split(':').last}"),
            InfoRow(label: 'Wall', value: door.wall),
            InfoRow(label: 'Width', value: '${door.width}ft'),
            InfoRow(label: 'Offset', value: '${door.offsetFromWallStart}ft'),
            InfoRow(
                label: 'Swing', value: door.swingInward ? "Inward" : "Outward"),
            InfoRow(label: 'Opens', value: door.openLeft ? "Left" : "Right"),
            if (door.connectedDoor != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.link, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Connected Door',
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
            InfoRow(label: 'Width', value: '${stairs.width}ft'),
            InfoRow(label: 'Length', value: '${stairs.length}ft'),
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
}
