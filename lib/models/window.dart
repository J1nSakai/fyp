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
  bool isHighlighted;

  Window({
    required this.id,
    this.width = defaultWidth,
    required this.offsetFromWallStart,
    required this.wall,
    this.connectedWindow,
    this.isHighlighted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'width': width,
      'offsetFromWallStart': offsetFromWallStart,
      'wall': wall,
      'isHighlighted': isHighlighted,
      'connectedWindowId':
          connectedWindow?.id, // Store only the ID of connected window
    };
  }

  factory Window.fromJson(Map<String, dynamic> json) {
    return Window(
      id: json['id'],
      width: json['width'] ?? defaultWidth,
      offsetFromWallStart: json['offsetFromWallStart'],
      wall: json['wall'],
      isHighlighted: json['isHighlighted'] ?? false,
    );
  }

  // Helper method to restore connected windows after all windows are created
  void restoreConnectedWindow(Map<String, Window> allWindows) {
    final connectedWindowId = allWindows[id]?.connectedWindow?.id;
    if (connectedWindowId != null &&
        allWindows.containsKey(connectedWindowId)) {
      connectedWindow = allWindows[connectedWindowId];
    }
  }

  // Optional: Create a copy of the window
  Window copy() {
    return Window(
      id: id,
      width: width,
      offsetFromWallStart: offsetFromWallStart,
      wall: wall,
      isHighlighted: isHighlighted,
    );
  }
}
