import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saysketch_v2/controllers/floor_manager_controller.dart';

class FloorSelectorView extends StatelessWidget {
  const FloorSelectorView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Consumer<FloorManagerController>(
      builder: (context, floorManager, child) {
        final currentFloor = (floorManager.activeFloor?.level ?? 0) + 1;
        final totalFloors = floorManager.floors.length;

        return SizedBox(
          width: 200,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
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
                    color: theme.colorScheme.primary
                        .withOpacity(isDarkMode ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    children: [
                      Semantics(
                        label: 'Current floor status',
                        value: 'Floor $currentFloor of $totalFloors',
                        child: Text(
                          'Floor $currentFloor of $totalFloors',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Floors: $totalFloors',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
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

                  return Semantics(
                    button: true,
                    selected: isActive,
                    label: 'Floor $floorNumber',
                    hint: isActive
                        ? 'Current floor'
                        : 'Click to switch to floor $floorNumber',
                    child: Tooltip(
                      message: isActive
                          ? 'Current floor'
                          : 'Switch to floor $floorNumber',
                      child: InkWell(
                        onTap: () =>
                            floorManager.switchToFloor(floorNumber - 1),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface
                                      .withOpacity(0.2),
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
                                  color: isActive
                                      ? Colors.white
                                      : theme.colorScheme.onSurface,
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
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
