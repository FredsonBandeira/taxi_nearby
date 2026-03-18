// lib/services/driver_notification_service.dart
import 'dart:async';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/ride_model.dart';

class DriverNotificationService {
  static final DriverNotificationService _instance = 
      DriverNotificationService._internal();
  factory DriverNotificationService() => _instance;
  DriverNotificationService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  Function(RideModel)? onNewRideRequest;
  
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _voiceEnabled = true;

  // === NOTIFICAR NOVA CORRIDA ===
  Future<void> notifyNewRide(RideModel ride) async {
    print('🔔 Nova corrida solicitada!');
    
    // Vibração (padrão de notificação)
    if (_vibrationEnabled) {
      await _vibrate();
    }
    
    // Som de notificação
    if (_soundEnabled) {
      await _playNotificationSound();
    }
    
    // Callback para mostrar UI
    onNewRideRequest?.call(ride);
  }

  // === VIBRAR ===
  Future<void> _vibrate() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        // Padrão: vibrar 3 vezes
        await Vibration.vibrate(
          pattern: [0, 500, 200, 500, 200, 500],
          intensities: [0, 128, 0, 128, 0, 128],
        );
      }
    } catch (e) {
      print('Erro na vibração: $e');
    }
  }

  // === TOCAR SOM ===
  Future<void> _playNotificationSound() async {
    try {
      // Som de notificação (usando URL ou asset)
      await _audioPlayer.play(
        AssetSource('sounds/notification.mp3'), // Adicione este arquivo
        volume: 1.0,
      );
    } catch (e) {
      print('Erro ao tocar som: $e');
      // Fallback: beep simples
      await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
    }
  }

  // === CONFIGURAÇÕES ===
  void setSoundEnabled(bool enabled) => _soundEnabled = enabled;
  void setVibrationEnabled(bool enabled) => _vibrationEnabled = enabled;
  void setVoiceEnabled(bool enabled) => _voiceEnabled = enabled;
  
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get voiceEnabled => _voiceEnabled;

  // === LIMPAR ===
  void stopNotification() {
    _audioPlayer.stop();
    Vibration.cancel();
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}