import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// High-reliability multi-lingual Text-to-Speech service for Marathi, Hindi, and English.
/// Combines native Google TTS engine with an online streaming voice fallback (audioplayers)
/// to ensure crystal-clear voice instructions across all platforms (Android, Windows, Web, Emulator)
/// even when the host system lacks local Marathi or Hindi voice packs.
class TtsService {
  TtsService() {
    _initTts();
  }

  FlutterTts? _flutterTts;
  AudioPlayer? _audioPlayer;
  bool _isSpeaking = false;
  final ValueNotifier<bool> isSpeakingNotifier = ValueNotifier<bool>(false);
  bool _usingAudioPlayer = false;

  bool get isSpeaking => _isSpeaking;

  void _initTts() {
    try {
      _audioPlayer = AudioPlayer();
      _audioPlayer?.onPlayerComplete.listen((_) {
        _onSpeechEnded();
      });
      _audioPlayer?.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.playing) {
          _onSpeechStarted();
        } else if (state == PlayerState.completed || state == PlayerState.stopped) {
          _onSpeechEnded();
        }
      });
    } catch (e) {
      debugPrint('AudioPlayer init note: $e');
    }

    try {
      _flutterTts = FlutterTts();
      _flutterTts?.setStartHandler(() {
        if (!_usingAudioPlayer) {
          _onSpeechStarted();
        }
      });
      _flutterTts?.setCompletionHandler(() {
        if (!_usingAudioPlayer) {
          _onSpeechEnded();
        }
      });
      _flutterTts?.setCancelHandler(() {
        if (!_usingAudioPlayer) {
          _onSpeechEnded();
        }
      });
      _flutterTts?.setErrorHandler((msg) {
        debugPrint('FlutterTts Error: $msg');
        if (!_usingAudioPlayer) {
          _onSpeechEnded();
        }
      });

      // Default rate and volume for rural accessibility
      _flutterTts?.setSpeechRate(0.45);
      _flutterTts?.setVolume(1.0);
      _flutterTts?.setPitch(1.0);

      // Attempt to set Google Speech Services engine on Android
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        _configureAndroidEngine();
      }
    } catch (e) {
      debugPrint('FlutterTts init note: $e');
    }
  }

  Future<void> _configureAndroidEngine() async {
    try {
      final dynamic engines = await _flutterTts?.getEngines;
      if (engines is List && engines.contains('com.google.android.tts')) {
        await _flutterTts?.setEngine('com.google.android.tts');
      }
    } catch (_) {}
  }

  void _onSpeechStarted() {
    _isSpeaking = true;
    isSpeakingNotifier.value = true;
  }

  void _onSpeechEnded() {
    _isSpeaking = false;
    _usingAudioPlayer = false;
    isSpeakingNotifier.value = false;
  }

  /// Normalizes language code into standard BCP-47 tag.
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

  /// Builds a clean Google TTS stream URL for high-fidelity speech synthesis.
  String _buildStreamingTtsUrl(String text, String langCode) {
    final cleanLang = langCode.startsWith('mr')
        ? 'mr'
        : langCode.startsWith('hi')
            ? 'hi'
            : 'en';
    final encoded = Uri.encodeQueryComponent(text.trim());
    return 'https://translate.google.com/translate_tts?ie=UTF-8&tl=$cleanLang&client=tw-ob&q=$encoded';
  }

  /// Speaks the provided text in Marathi, Hindi, or English.
  /// Automatically selects the best available engine (native TTS or crystal-clear streaming voice).
  Future<void> speak(String text, {String? languageCode}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    await stop();

    final targetLang = languageCode?.toLowerCase() ?? 'en';
    final targetLocale = _mapLanguageCode(targetLang);

    // 0. Pre-recorded clip bundled with the app (Marathi / Hindi tour
    // narration, see tool/generate_tour_audio.py). Plays offline and does
    // not depend on the phone having a Marathi or Hindi voice installed.
    if (targetLang == 'mr' || targetLang == 'hi') {
      final played = await _playBundledClip(trimmed, targetLang);
      if (played) return;
    }

    // 1. If running on Windows desktop, Windows SAPI only has en-US voices installed by default.
    // Use the streaming voice provider for authentic Marathi and Hindi voices.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      if (targetLang == 'mr' || targetLang == 'hi') {
        final played = await _playViaStreamingVoice(trimmed, targetLang);
        if (played) return;
      }
    }

    // 2. Try native FlutterTts first (ideal for offline and devices with language packs)
    bool nativeSuccess = false;
    if (_flutterTts != null) {
      try {
        final dynamic available = await _flutterTts?.isLanguageAvailable(targetLocale);
        final bool isAvailable = available == true || available == 1;

        if (isAvailable || targetLang == 'en') {
          await _flutterTts?.setLanguage(targetLocale);
          await _flutterTts?.setSpeechRate(0.45);
          await _flutterTts?.setVolume(1.0);
          await _flutterTts?.setPitch(1.0);

          _usingAudioPlayer = false;
          _onSpeechStarted();
          final dynamic speakResult = await _flutterTts?.speak(trimmed);
          if (speakResult == 1 || speakResult == true) {
            nativeSuccess = true;
          }
        }
      } catch (e) {
        debugPrint('Native TTS attempt note: $e');
      }
    }

    // 3. If native engine was unable to speak the regional language, stream voice cleanly
    if (!nativeSuccess) {
      final played = await _playViaStreamingVoice(trimmed, targetLang);
      if (!played && _flutterTts != null) {
        // Last-resort fallback: attempt whatever native voice is configured
        try {
          await _flutterTts?.speak(trimmed);
        } catch (_) {}
      }
    }
  }

  /// FNV-1a 32-bit of the UTF-8 text; must match tool/generate_tour_audio.py.
  static String clipHash(String text) {
    var h = 0x811C9DC5;
    for (final b in utf8.encode(text)) {
      h ^= b;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }

  Future<bool> _playBundledClip(String text, String langCode) async {
    if (_audioPlayer == null) return false;
    final path = 'audio/tour/${langCode}_${clipHash(text)}.mp3';
    try {
      // Existence check: a missing asset throws here, before playback starts.
      await rootBundle.load('assets/$path');
    } catch (_) {
      return false;
    }
    try {
      _usingAudioPlayer = true;
      _onSpeechStarted();
      await _audioPlayer?.play(AssetSource(path));
      return true;
    } catch (e) {
      debugPrint('Bundled clip error: $e');
      _usingAudioPlayer = false;
      return false;
    }
  }

  Future<bool> _playViaStreamingVoice(String text, String langCode) async {
    if (_audioPlayer == null) return false;
    try {
      final url = _buildStreamingTtsUrl(text, langCode);
      _usingAudioPlayer = true;
      _onSpeechStarted();
      await _audioPlayer?.play(UrlSource(url));
      return true;
    } catch (e) {
      debugPrint('Streaming audio error: $e');
      _usingAudioPlayer = false;
      return false;
    }
  }

  /// Stops any speech output immediately (both native TTS and audio streams).
  Future<void> stop() async {
    try {
      await _flutterTts?.stop();
    } catch (_) {}

    try {
      await _audioPlayer?.stop();
    } catch (_) {}

    _onSpeechEnded();
  }

  void dispose() {
    stop();
    try {
      _audioPlayer?.dispose();
    } catch (_) {}
    isSpeakingNotifier.dispose();
  }
}
