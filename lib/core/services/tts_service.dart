import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Text-to-Speech service delivering voice instructions in Marathi, Hindi, and English.
/// Configured with a comfortable, slow speech rate tailored for rural listeners.
class TtsService {
  TtsService() {
    _initTts();
  }

  FlutterTts? _flutterTts;
  bool _isSpeaking = false;
  final ValueNotifier<bool> isSpeakingNotifier = ValueNotifier<bool>(false);

  bool get isSpeaking => _isSpeaking;

  void _initTts() {
    try {
      _flutterTts = FlutterTts();
      _flutterTts?.setStartHandler(() {
        _isSpeaking = true;
        isSpeakingNotifier.value = true;
      });
      _flutterTts?.setCompletionHandler(() {
        _isSpeaking = false;
        isSpeakingNotifier.value = false;
      });
      _flutterTts?.setCancelHandler(() {
        _isSpeaking = false;
        isSpeakingNotifier.value = false;
      });
      _flutterTts?.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        _isSpeaking = false;
        isSpeakingNotifier.value = false;
      });

      // Standard rural accessibility parameters
      _flutterTts?.setSpeechRate(0.45);
      _flutterTts?.setVolume(1.0);
      _flutterTts?.setPitch(1.0);
    } catch (e) {
      debugPrint('TTS initialization note: $e');
    }
  }

  /// Maps language codes to TTS locale identifiers.
  String _mapLanguageCode(String? languageCode) {
    switch (languageCode?.toLowerCase()) {
      case 'mr':
        return 'mr-IN';
      case 'hi':
        return 'hi-IN';
      case 'en':
      default:
        return 'en-IN';
    }
  }

  /// Speaks the provided text in the requested language (mr, hi, or en).
  Future<void> speak(String text, {String? languageCode}) async {
    if (_flutterTts == null || text.trim().isEmpty) return;

    try {
      await stop();

      final targetLocale = _mapLanguageCode(languageCode);
      // Attempt to set locale
      try {
        await _flutterTts?.setLanguage(targetLocale);
      } catch (_) {
        // Fallback to Hindi or default if specific locale unavailable
        await _flutterTts?.setLanguage('hi-IN');
      }

      await _flutterTts?.setSpeechRate(0.45);
      await _flutterTts?.setVolume(1.0);
      await _flutterTts?.setPitch(1.0);

      _isSpeaking = true;
      isSpeakingNotifier.value = true;
      await _flutterTts?.speak(text);
    } catch (e) {
      debugPrint('TTS Speak Error: $e');
      _isSpeaking = false;
      isSpeakingNotifier.value = false;
    }
  }

  /// Stops current speech output.
  Future<void> stop() async {
    if (_flutterTts == null) return;
    try {
      await _flutterTts?.stop();
    } catch (e) {
      debugPrint('TTS Stop Error: $e');
    } finally {
      _isSpeaking = false;
      isSpeakingNotifier.value = false;
    }
  }

  void dispose() {
    stop();
    isSpeakingNotifier.dispose();
  }
}
