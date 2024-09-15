import "package:fluttertoast/fluttertoast.dart";
import "package:speech_to_text/speech_to_text.dart";

class SpeechToTextService {
  final SpeechToText _speech = SpeechToText();

  Future<void> listen(void Function(String command) onCommandRecognized) async {
    bool available = await _speech.initialize();
    Fluttertoast.showToast(msg: "Started Listening.");

    if (available) {
      _speech.listen(
        listenOptions: SpeechListenOptions(partialResults: false),
        onResult: (result) {
          print(result.recognizedWords);
          onCommandRecognized(result.recognizedWords.toLowerCase());
        },
      );
    }
  }

  void stopListening() {
    _speech.stop();
  }
}
