import 'package:flutter/material.dart';

class CompassWidget extends StatelessWidget {
  const CompassWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 80,
      height: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Compass circle with accent color stroke
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.tertiary, // Warm orange stroke
                width: 2,
              ),
            ),
          ),
          // Direction markers
          ...['N', 'E', 'S', 'W'].asMap().entries.map((entry) {
            final angle = entry.key * 90.0;
            final direction = entry.value;

            return Positioned.fill(
              child: Transform.rotate(
                angle: angle * 3.14159 / 180,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      direction,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: theme.colorScheme
                            .secondary, // Secondary color for all directions
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          // Center dot
          Center(
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary, // Secondary color for dot
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
