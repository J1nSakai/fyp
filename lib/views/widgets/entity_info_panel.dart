import 'package:flutter/material.dart';
import 'package:saysketch_v2/controllers/floor_manager_controller.dart';
import 'package:saysketch_v2/models/room_model.dart';
import 'package:saysketch_v2/models/door.dart';
import 'package:saysketch_v2/models/stairs.dart';

class EntityInfoPanel extends StatelessWidget {
  final FloorManagerController floorManagerController;

  const EntityInfoPanel({
    super.key,
    required this.floorManagerController,
  });

  @override
  Widget build(BuildContext context) {
    Room? selectedRoom =
        floorManagerController.getActiveController()?.selectedRoom;
    Stairs? selectedStairs =
        floorManagerController.getActiveController()?.selectedStairs;

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
                  selectedRoom != null ? 'Room Details' : 'Stairs Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      if (selectedRoom != null) {
                        floorManagerController
                            .getActiveController()
                            ?.deselectRoom();
                        print(selectedRoom);
                      } else if (selectedStairs != null) {
                        floorManagerController
                            .getActiveController()
                            ?.deselectStairs();
                      }
                    },
                    child: const Icon(Icons.close, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: selectedRoom != null
                    ? _buildRoomDetails(context, selectedRoom)
                    : _buildStairsDetails(context, selectedStairs!),
              ),
            ),
          ),
        ],
      ),
    );
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
            children:
                room.doors.map((door) => DoorInfoTile(door: door)).toList(),
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

class InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const InfoSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class DoorInfoTile extends StatelessWidget {
  final Door door;

  const DoorInfoTile({
    super.key,
    required this.door,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(label: 'ID', value: door.id),
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
    );
  }
}
