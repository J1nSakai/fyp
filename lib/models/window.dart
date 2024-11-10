class Window {
  static const double defaultWidth = 3.0; // 3 feet, like doors
  static const double minDistanceFromCorner = 1.5; // 1.5 feet
  static const double minDistanceBetweenWindows = 3.0; // 3 feet
  static const double minDistanceFromDoors =
      2.0; // 2 feet minimum distance from doors

  final String id; // Format: "room_name:w:number" (e.g., "room1:w:1")
  double width;
  double offsetFromWallStart;
  String wall; // "north", "south", "east", "west"
  Window? connectedWindow; // For windows connecting rooms
  bool isHighlighted = false;

  Window({
    required this.id,
    this.width = defaultWidth,
    required this.offsetFromWallStart,
    required this.wall,
    this.connectedWindow,
    this.isHighlighted = false,
  });
}
