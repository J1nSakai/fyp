import 'package:saysketch_v2/models/opening.dart';

class Window extends Opening {
  final bool hasWindowSill;

  Window({
    required super.position,
    required super.width,
    required super.length,
    required super.angle,
    this.hasWindowSill = true,
  });
}
