import 'dart:async';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum VoiceState { idle, listening, thinking, speaking, error }

class VoiceService extends GetxService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  final Rx<VoiceState> state = VoiceState.idle.obs;
  final RxBool isListening = false.obs;
  final RxBool isSpeaking = false.obs;
  final RxString transcript = ''.obs;
  final RxDouble audioLevel = 0.0.obs;
  final RxString lastError = ''.obs;

  Function(String)? onTranscriptComplete;
  Function()? onSpeechStart;

  Future<VoiceService> init() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setCompletionHandler(() {
        isSpeaking.value = false;
        if (state.value == VoiceState.speaking) {
          state.value = VoiceState.idle;
        }
      });

      _tts.setErrorHandler((msg) {
        lastError.value = 'TTS: $msg';
        isSpeaking.value = false;
      });
    } catch (e) {
      lastError.value = 'TTS init: $e';
    }
    return this;
  }

  Future<bool> get isAvailable async {
    try {
      return await _speech.initialize(
        onStatus: (status) => _handleStatus(status),
        onError: (error) => _handleError(error),
      );
    } catch (e) {
      lastError.value = 'STT init: $e';
      return false;
    }
  }

  Future<void> startListening() async {
    if (isListening.value) return;

    final available = await isAvailable;
    if (!available) {
      lastError.value = 'Speech recognition not available';
      return;
    }

    transcript.value = '';
    state.value = VoiceState.listening;
    isListening.value = true;

    await _speech.listen(
      onResult: (result) {
        transcript.value = result.recognizedWords;
        if (result.finalResult) {
          _onSpeechComplete(result.recognizedWords);
        }
      },
      listenMode: ListenMode.confirmation,
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      onSoundLevelChange: (level) {
        audioLevel.value = (level + 10) / 20; // normalize 0-1
      },
    );
  }

  Future<void> stopListening() async {
    isListening.value = false;
    audioLevel.value = 0.0;
    await _speech.stop();
  }

  void _onSpeechComplete(String text) {
    isListening.value = false;
    audioLevel.value = 0.0;
    if (text.trim().isNotEmpty && onTranscriptComplete != null) {
      onTranscriptComplete!(text);
    }
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await stopSpeaking();
    state.value = VoiceState.speaking;
    isSpeaking.value = true;
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    isSpeaking.value = false;
  }

  void _handleStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      isListening.value = false;
      audioLevel.value = 0.0;
    }
  }

  void _handleError(dynamic error) {
    lastError.value = error.toString();
    isListening.value = false;
    state.value = VoiceState.error;
  }

  void setOnTranscriptComplete(Function(String) callback) {
    onTranscriptComplete = callback;
  }

  void setOnSpeechStart(Function() callback) {
    onSpeechStart = callback;
  }

  @override
  void onClose() {
    _speech.cancel();
    _tts.stop();
    super.onClose();
  }
}