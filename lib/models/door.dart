class Door {
  static const double defaultWidth = 3.0; // 3 feet
  static const double minWidth = 1.0; // 1 feet
  static const double minDistanceFromCorner = 1.0; // 1 feet
  static const double minDistanceBetweenDoors = 1.0; // 1 feet
  static const double minDistanceFromWindows = 1.0; // 1 feet
  static const double minDistanceFromSpaces = 1.0; // 1 feet

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'width': width,
      'offsetFromWallStart': offsetFromWallStart,
      'wall': wall,
      'swingInward': swingInward,
      'openLeft': openLeft,
      'isHighlighted': isHighlighted,
      'connectedDoorId':
          connectedDoor?.id, // Store only the ID of connected door
    };
  }

  factory Door.fromJson(Map<String, dynamic> json) {
    return Door(
      id: json['id'],
      width: json['width'] ?? defaultWidth,
      offsetFromWallStart: json['offsetFromWallStart'],
      wall: json['wall'],
      swingInward: json['swingInward'] ?? true,
      openLeft: json['openLeft'] ?? true,
      isHighlighted: json['isHighlighted'] ?? false,
    );
  }

  // Helper method to restore connected doors after all doors are created
  void restoreConnectedDoor(Map<String, Door> allDoors) {
    final connectedDoorId = allDoors[id]?.connectedDoor?.id;
    if (connectedDoorId != null && allDoors.containsKey(connectedDoorId)) {
      connectedDoor = allDoors[connectedDoorId];
    }
  }

  // Optional: Create a copy of the door
  Door copy() {
    return Door(
      id: id,
      width: width,
      offsetFromWallStart: offsetFromWallStart,
      wall: wall,
      swingInward: swingInward,
      openLeft: openLeft,
      isHighlighted: isHighlighted,
    );
  }
}
