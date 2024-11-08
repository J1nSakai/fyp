// New widget for simplified door info
import 'package:flutter/material.dart';
import 'package:saysketch_v2/models/door.dart';

import 'info_row.dart';

class SimpleDoorInfoTile extends StatelessWidget {
  final Door door;

  const SimpleDoorInfoTile({
    super.key,
    required this.door,
  });

  @override
  Widget build(BuildContext context) {
    final doorNumber = door.id.split(':').last;
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
          InfoRow(label: 'Name', value: "door $doorNumber"),
          InfoRow(label: 'Wall', value: door.wall),
        ],
      ),
    );
  }
}
