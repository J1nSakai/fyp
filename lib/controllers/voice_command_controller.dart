// import 'dart:ui';

// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:saysketch_v2/controllers/floor_plan_controller.dart';

class VoiceCommandController {
  Map<String, double> extractMeasurements(String command) {
    RegExp regExp = RegExp(
        r'(\d+)\s*(feet|meters|foot)?\s*by\s*(\d+)\s*(feet|meters|foot)?');
    var match = regExp.firstMatch(command);

    if (match != null) {
      double width = double.parse(match.group(1)!);
      double height = double.parse(match.group(3)!);

      return {'width': width, 'height': height};
    }

    return {};
  }

  // void handleCommand(String command) {
  //   FloorPlanController floorPlanController = FloorPlanController();
  //   List tokens = command.split(" ");
  //   if (tokens.contains("base") && !tokens.contains("by")) {
  //     floorPlanController.setDefaultBase();
  //   } else if (tokens.contains("base") && tokens.contains("by")) {
  //     Map<String, double> dimensions = extractMeasurements(command);
  //     if (dimensions.isNotEmpty) {
  //       floorPlanController.setBase(
  //         dimensions['width']!,
  //         dimensions['height']!,
  //         const Offset(100, 100),
  //       );
  //     } else {
  //       print("Cannot extract dimensions from the command.");
  //     }
  //   } else if (tokens.contains("room") && !tokens.contains("by")) {
  //     floorPlanController.addDefaultRoom();
  //   } else if (tokens.contains("remove")) {
  //     print("I am here!");
  //     if (tokens.contains("base")) {
  //       print("I am here! 2");
  //       floorPlanController.removeBase();
  //     } else if (tokens.contains("rooms")) {
  //       floorPlanController.removeAllRooms();
  //     } else {
  //       Fluttertoast.showToast(msg: "Please specify what you want to remove.");
  //     }
  //   } else {
  //     print("Invalid Command");
  //   }
  // }
}
