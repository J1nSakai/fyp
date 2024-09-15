class VoiceCommandController {
  static Map<String, double> extractMeasurements(String command) {
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
}
