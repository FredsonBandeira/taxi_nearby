// lib/services/location_simulation_service.dart
import 'dart:async';
import 'dart:math';
import '../models/driver.dart';

class LocationSimulationService {
  static final LocationSimulationService _instance = 
      LocationSimulationService._internal();
  factory LocationSimulationService() => _instance;
  LocationSimulationService._internal();

  final _random = Random();
  final _activeSimulations = <String, Timer>{};
  final _locationCallbacks = <String, Function(double, double)>{};

  // === INICIAR SIMULAÇÃO PARA UM DRIVER ===
  void startDriverSimulation(
    String driverId, {
    required double startLat,
    required double startLng,
    required Function(double lat, double lng) onUpdate,
    Duration interval = const Duration(seconds: 3),
  }) {
    // Cancela simulação existente se houver
    stopDriverSimulation(driverId);

    double currentLat = startLat;
    double currentLng = startLng;

    _locationCallbacks[driverId] = onUpdate;

    _activeSimulations[driverId] = Timer.periodic(interval, (timer) {
      // Simula movimento aleatório (5-15 metros por atualização)
      final moveLat = (_random.nextDouble() - 0.5) * 0.0002;
      final moveLng = (_random.nextDouble() - 0.5) * 0.0002;

      currentLat += moveLat;
      currentLng += moveLng;

      // Notifica callback
      onUpdate(currentLat, currentLng);
    });
  }

  // === PARAR SIMULAÇÃO ===
  void stopDriverSimulation(String driverId) {
    _activeSimulations[driverId]?.cancel();
    _activeSimulations.remove(driverId);
    _locationCallbacks.remove(driverId);
  }

  // === PARAR TODAS ===
  void stopAllSimulations() {
    for (final timer in _activeSimulations.values) {
      timer.cancel();
    }
    _activeSimulations.clear();
    _locationCallbacks.clear();
  }

  // === SIMULAR MOVIMENTO EM DIREÇÃO A UM DESTINO ===
  void simulateMovementToDestination({
    required String id,
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required Function(double lat, double lng, bool arrived) onProgress,
    Duration totalDuration = const Duration(seconds: 30),
  }) {
    stopDriverSimulation(id);

    const steps = 30;
    final latStep = (endLat - startLat) / steps;
    final lngStep = (endLng - startLng) / steps;
    
    double currentLat = startLat;
    double currentLng = startLng;
    int currentStep = 0;

    final interval = totalDuration.inMilliseconds ~/ steps;

    _activeSimulations[id] = Timer.periodic(
      Duration(milliseconds: interval),
      (timer) {
        currentStep++;
        currentLat += latStep;
        currentLng += lngStep;

        final arrived = currentStep >= steps;
        onProgress(currentLat, currentLng, arrived);

        if (arrived) {
          timer.cancel();
          _activeSimulations.remove(id);
        }
      },
    );
  }

  // === CALCULAR DISTÂNCIA ENTRE DOIS PONTOS (Haversine) ===
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000; // metros
    
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  // === OBTER TEMPO ESTIMADO DE CHEGADA ===
  String getEstimatedArrival(double distanceMeters) {
    // Assume velocidade média de 30 km/h em cidade
    const avgSpeedKmh = 30.0;
    final timeMinutes = (distanceMeters / 1000) / avgSpeedKmh * 60;
    
    if (timeMinutes < 1) {
      return 'Chegando agora!';
    } else if (timeMinutes < 60) {
      return '${timeMinutes.round()} min';
    } else {
      final hours = timeMinutes ~/ 60;
      final mins = timeMinutes.remainder(60).round();
      return '${hours}h ${mins}min';
    }
  }
}