class Space {
  static const double defaultWidth = 3.0; // 3 feet, like doors
  static const double minDistanceFromCorner = 1.5; // 1.5 feet
  static const double minDistanceBetweenSpaces = 3.0; // 3 feet
  static const double minDistanceFromDoors =
      2.0; // 2 feet minimum distance from doors
  static const double minDistanceFromWindows =
      2.0; // 2 feet minimum distance from windows

  final String id; // Format: "cutout_name:s:number" (e.g., "cutout1:s:1")
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
}
