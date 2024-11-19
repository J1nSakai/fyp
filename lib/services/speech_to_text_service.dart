import "package:fluttertoast/fluttertoast.dart";
import "package:speech_to_text/speech_to_text.dart";

class SpeechToTextService {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;

  Future<void> listen(void Function(String command) onCommandRecognized) async {
    bool available = await _speech.initialize();

    if (available) {
      _isListening = true;
      Fluttertoast.showToast(msg: "Started continuous listening mode");

      // Function to start listening again after each recognition
      void startListening() {
        if (!_isListening) return;

        _speech.listen(
          listenOptions: SpeechListenOptions(
              partialResults: false,
              cancelOnError: false,
              listenMode: ListenMode.confirmation,
              onDevice: true),
          onResult: (result) {
            String command = result.recognizedWords.toLowerCase().trim();
            print("Recognized: $command");

            // Check if the command is to stop listening
            if (command == "stop listening" || command == "halt") {
              stopListening();
              Fluttertoast.showToast(msg: "Stopped listening");
              return;
            }

            // Process the command
            if (command.isNotEmpty) {
              onCommandRecognized(command);
            }
          },
          onSoundLevelChange: (level) {
            // Optional: Handle sound level changes
          },
        );

        // When the current listening session ends, start a new one if still active
        _speech.statusListener = (status) {
          if (status == SpeechToText.doneStatus && _isListening) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_isListening) startListening();
            });
          }
        };
      }

      // Start the initial listening session
      startListening();
    } else {
      Fluttertoast.showToast(msg: "Speech recognition not available");
    }
  }

  void stopListening() {
    _isListening = false;
    _speech.stop();
  }

  bool get isListening => _isListening;
}
