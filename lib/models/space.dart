class Space {
  static const double defaultWidth = 3.0; // 3 feet, like doors
  static const double minWidth = 1.0; // 1 feet
  static const double minDistanceFromCorner = 1.0; // 1 feet
  static const double minDistanceBetweenSpaces = 1.0; // 1 feet
  static const double minDistanceFromDoors = 1.0; // 1 feet
  static const double minDistanceFromWindows = 1.0; // 1 feet
  static const double minDistanceFromSpaces = 1.0; // 1 feet

  String id; // Format: "cutout_name:s:number" (e.g., "cutout1:s:1")
  double width;
  double offsetFromWallStart;
  String wall; // "north", "south", "east", "west"
  Space? connectedSpace; // For spaces connecting cutouts or rooms
  bool isHighlighted;

  Space({
    required this.id,
    this.width = defaultWidth,
    required this.offsetFromWallStart,
    required this.wall,
    this.connectedSpace,
    this.isHighlighted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'width': width,
      'offsetFromWallStart': offsetFromWallStart,
      'wall': wall,
      'isHighlighted': isHighlighted,
      'connectedSpaceId': connectedSpace?.id,
    };
  }

  factory Space.fromJson(Map<String, dynamic> json) {
    return Space(
      id: json['id'],
      width: json['width'] ?? defaultWidth,
      offsetFromWallStart: json['offsetFromWallStart'],
      wall: json['wall'],
      isHighlighted: json['isHighlighted'] ?? false,
    );
  }

  void restoreConnectedSpace(Map<String, Space> allSpaces) {
    final connectedSpaceId = allSpaces[id]?.connectedSpace?.id;
    if (connectedSpaceId != null && allSpaces.containsKey(connectedSpaceId)) {
      connectedSpace = allSpaces[connectedSpaceId];
    }
  }

  Space copy() {
    return Space(
      id: id,
      width: width,
      offsetFromWallStart: offsetFromWallStart,
      wall: wall,
      isHighlighted: isHighlighted,
    );
  }

  void updateRoomName(String oldRoomName, String newRoomName) {
    if (id.startsWith(oldRoomName)) {
      // Create new ID with updated room name
      final parts = id.split(':');
      parts[0] = newRoomName;
      final newId = parts.join(':');

      // Update this space's ID
      id = newId;

      // Update connected space if it exists and belongs to the same room
      if (connectedSpace != null &&
          connectedSpace!.id.startsWith(oldRoomName)) {
        connectedSpace!.updateRoomName(oldRoomName, newRoomName);
      }
    }
  }
}
