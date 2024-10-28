import 'package:saysketch_v2/models/opening.dart';

class Door extends Opening {
  final bool isEntrance; // true if it's a main entrance door
  final bool opensInward; // swing direction

  Door({
    required super.position,
    required super.width,
    required super.length,
    required super.angle,
    this.isEntrance = false,
    this.opensInward = true,
  });
}
