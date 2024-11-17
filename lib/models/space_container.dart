import 'dart:ui';

import 'space.dart';

abstract class SpaceContainer {
  String get name;
  List<Space> get spaces;
  double get width;
  double get height;
  Offset get position;
}
