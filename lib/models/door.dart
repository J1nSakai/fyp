class Door {
  static const double defaultWidth = 3.0; // 3 feet
  static const double minDistanceFromCorner = 1.5; // 1.5 feet
  static const double minDistanceBetweenDoors = 3.0; // 3 feet

  final String id; // Format: "room_name:wall:number" (e.g., "room1:north:1")
  double width;
  double offsetFromWallStart;
  String wall; // "north", "south", "east", "west"
  bool swingInward;
  bool openLeft;
  Door? connectedDoor; // For doors connecting rooms
  bool isHighlighted = false;

  Door({
    required this.id,
    this.width = defaultWidth,
    required this.offsetFromWallStart,
    required this.wall,
    this.swingInward = true,
    this.openLeft = true,
    this.connectedDoor,
    this.isHighlighted = false,
  });
}
