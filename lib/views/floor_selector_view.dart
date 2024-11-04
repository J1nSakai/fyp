import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saysketch_v2/controllers/floor_manager_controller.dart';

class FloorSelectorView extends StatelessWidget {
  const FloorSelectorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FloorManagerController>(
      builder: (context, floorManager, child) {
        final currentFloor = (floorManager.activeFloor?.level ?? 0) + 1;
        final totalFloors = floorManager.floors.length;

        return Positioned(
          top: 20,
          right: 20,
          child: SizedBox(
            width: 200,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Floor $currentFloor of $totalFloors',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total Floors: $totalFloors',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // List of all floors
                  ...List.generate(totalFloors, (index) {
                    final floorNumber = totalFloors - index;
                    final isActive = floorNumber == currentFloor;

                    return GestureDetector(
                      onTap: () => floorManager.switchToFloor(floorNumber - 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.blue : Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isActive ? Colors.blue : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Text(
                              'Floor $floorNumber',
                              style: TextStyle(
                                color: isActive ? Colors.white : Colors.black87,
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (isActive)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 16,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
