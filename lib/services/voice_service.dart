// lib/services/voice_service.dart
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:async';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  String _lastWords = '';
  
  Function(String)? onVoiceResult;
  Function(bool)? onListeningChanged;

  // === INICIALIZAR ===
  Future<bool> initialize() async {
    try {
      bool available = await _speech.initialize(
        onError: (error) => print('Erro no reconhecimento de voz: $error'),
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            onListeningChanged?.call(false);
          } else if (status == 'listening') {
            _isListening = true;
            onListeningChanged?.call(true);
          }
        },
      );
      return available;
    } catch (e) {
      print('Erro ao inicializar voz: $e');
      return false;
    }
  }

  // === OUVIR COMANDO ===
  void startListening({
    Duration listenFor = const Duration(seconds: 5),
    Duration pauseFor = const Duration(seconds: 3),
  }) {
    if (_isListening) return;
    
    _speech.listen(
      onResult: (result) {
        _lastWords = result.recognizedWords.toLowerCase();
        print('🎤 Ouvindo: $_lastWords');
        
        // Detectar comandos
        if (_lastWords.contains('aceito') || 
            _lastWords.contains('sim') || 
            _lastWords.contains('aceitar')) {
          onVoiceResult?.call('accept');
        } else if (_lastWords.contains('não aceito') || 
                   _lastWords.contains('nao aceito') || 
                   _lastWords.contains('não') ||
                   _lastWords.contains('nao') ||
                   _lastWords.contains('recusar')) {
          onVoiceResult?.call('reject');
        }
      },
      listenFor: listenFor,
      pauseFor: pauseFor,
      localeId: 'pt_PT', // Português
      onSoundLevelChange: (level) {},
      cancelOnError: true,
      partialResults: true,
    );
    
    _isListening = true;
    onListeningChanged?.call(true);
  }

  // === PARAR DE OUVIR ===
  void stopListening() {
    _speech.stop();
    _isListening = false;
    onListeningChanged?.call(false);
  }

  // === STATUS ===
  bool get isListening => _isListening;
  bool get isAvailable => _speech.isAvailable;
  
  String get lastWords => _lastWords;

  // === PERMISSÕES ===
  Future<bool> requestPermissions() async {
    // As permissões são gerenciadas pelo speech_to_text
    return await initialize();
  }
}