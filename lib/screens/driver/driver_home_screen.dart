// lib/screens/driver/driver_home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ Para kDebugMode
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/location_simulation_service.dart';
import '../../services/voice_service.dart';
import '../../services/driver_notification_service.dart';
import '../../models/user.dart';
import '../../models/driver.dart';
import '../../models/ride_model.dart';
import './driver_profile_screen.dart';
import './driver_rides_screen.dart';
import './driver_settings_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final AuthService _authService = AuthService();
  final LocationSimulationService _locationService = LocationSimulationService();
  final VoiceService _voiceService = VoiceService();
  final DriverNotificationService _notificationService = DriverNotificationService();

  GoogleMapController? _mapController;
  DriverModel? _driver;
  
  // ✅ Estados de carregamento e erro
  bool _isLoading = true;
  String? _errorMessage;
  
  static const LatLng _centerLocation = LatLng(16.7421003, -22.9349121);
  LatLng _currentLocation = _centerLocation;
  
  bool _isAvailable = false;
  bool _isToggling = false;
  
  Timer? _locationUpdateTimer;
  Timer? _voiceListeningTimer;
  
  RideModel? _pendingRide;
  RideModel? _activeRide;
  bool _isListeningForVoice = false;

  @override
  void initState() {
    super.initState();
    // ✅ Inicializa sem await para não travar a UI
    _initializeDriver();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _voiceListeningTimer?.cancel();
    _notificationService.dispose();
    _voiceService.stopListening();
    _locationService.stopAllSimulations();
    super.dispose();
  }

  // ✅ Inicialização ROBUSTA com tratamento de erro visível
  Future<void> _initializeDriver() async {
    try {
      print('🔍 [DEBUG] Iniciando driver...');
      
      // ✅ Timeout de 5 segundos para evitar travamento infinito
      final user = await _authService.getCurrentUser().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('❌ [DEBUG] Timeout ao carregar usuário');
          return null;
        },
      );
      
      print('🔍 [DEBUG] Usuário carregado: ${user?.runtimeType}');
      
      if (user == null) {
        throw Exception('Usuário não encontrado. Faça login novamente.');
      }
      
      if (user is! DriverModel) {
        print('❌ [DEBUG] Usuário não é DriverModel: ${user.role}');
        throw Exception('Conta não é de motorista. Role: ${user.role}');
      }
      
      // ✅ Atualiza estado com dados do driver
      if (mounted) {
        setState(() {
          _driver = user;
          _currentLocation = LatLng(user.latitude, user.longitude);
          _isAvailable = user.isAvailable;
          _isLoading = false; // ✅ Para de mostrar loading
          _errorMessage = null;
        });
        print('✅ [DEBUG] Driver carregado com sucesso: ${user.name}');
      }
      
      // ✅ Inicia serviços em background (sem await para não bloquear)
      _setupVoiceService();
      _setupNotificationService();
      
      // ✅ Se estava online, retoma atualizações
      if (_isAvailable && mounted) {
        _startLocationUpdates();
      }
      
    } catch (e, stack) {
      print('❌ [DEBUG] Erro ao inicializar: $e');
      print('❌ [DEBUG] Stack: $stack');
      
      if (mounted) {
        setState(() {
          _isLoading = false; // ✅ Para loading mesmo com erro
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _setupVoiceService() async {
    try {
      print('🎤 [DEBUG] Setup voice service...');
      final available = await _voiceService.initialize();
      print('🎤 [DEBUG] Voice available: $available');
      
      if (!available) {
        print('⚠️ [DEBUG] Reconhecimento de voz não disponível');
        return;
      }
      
      _voiceService.onVoiceResult = (command) {
        print('🎤 [DEBUG] Comando recebido: $command');
        if (_pendingRide != null && _isListeningForVoice) {
          if (command == 'accept') {
            print('✅ [DEBUG] Executando accept');
            _acceptRide();
          } else if (command == 'reject') {
            print('❌ [DEBUG] Executando reject');
            _rejectRide();
          }
        }
      };
      
      _voiceService.onListeningChanged = (isListening) {
        if (mounted) {
          setState(() => _isListeningForVoice = isListening);
        }
      };
    } catch (e) {
      print('❌ [DEBUG] Erro no voice service: $e');
    }
  }

  void _setupNotificationService() {
    _notificationService.onNewRideRequest = (ride) {
      print('🔔 [DEBUG] Nova corrida: ${ride.passengerId}');
      if (mounted && _isAvailable && _pendingRide == null) {
        _showRideRequestDialog(ride);
      }
    };
  }

  // ✅ Toggle Online/Offline com feedback visual
  Future<void> _toggleAvailability() async {
    if (_isToggling || _driver == null) return;
    
    setState(() => _isToggling = true);
    
    try {
      final newStatus = !_isAvailable;
      final updated = _driver!.copyWith(isAvailable: newStatus);
      
      await _authService.updateProfile(updated);
      
      if (mounted) {
        setState(() {
          _driver = updated;
          _isAvailable = newStatus;
        });
      }
      
      if (newStatus) {
        _startLocationUpdates();
        _startAutoVoiceListening();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('🟢 Online!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        _stopLocationUpdates();
        _voiceService.stopListening();
        _locationService.stopAllSimulations();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔴 Offline'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erro ao alterar status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  void _startLocationUpdates() {
    _stopLocationUpdates();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!_isAvailable || _driver == null || !mounted) {
        timer.cancel();
        return;
      }
      try {
        final newLat = _currentLocation.latitude + (DateTime.now().second % 10 - 5) * 0.00005;
        final newLng = _currentLocation.longitude + (DateTime.now().second % 10 - 5) * 0.00005;
        
        if ((newLat - _currentLocation.latitude).abs() > 0.00001 ||
            (newLng - _currentLocation.longitude).abs() > 0.00001) {
          setState(() {
            _currentLocation = LatLng(newLat, newLng);
            _driver!.latitude = newLat;
            _driver!.longitude = newLng;
          });
          _authService.updateProfile(_driver!).catchError((e) => print('Erro salvar loc: $e'));
        }
      } catch (e) {
        print('Erro atualização localização: $e');
      }
    });
  }

  void _stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
  }

  void _startAutoVoiceListening() {
    _voiceListeningTimer?.cancel();
    _voiceListeningTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isAvailable || _pendingRide == null || !mounted) return;
      try {
        _voiceService.startListening(listenFor: const Duration(seconds: 5));
        Future.delayed(const Duration(seconds: 5), () => _voiceService.stopListening());
      } catch (e) {
        print('Erro ao ouvir voz: $e');
      }
    });
  }

  void _showRideRequestDialog(RideModel ride) {
    _notificationService.stopNotification();
    setState(() => _pendingRide = ride);
    try {
      _voiceService.startListening(listenFor: const Duration(seconds: 10));
    } catch (e) {
      print('Erro ao iniciar voz: $e');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.local_taxi, color: Colors.amber[700], size: 32),
            const SizedBox(width: 8),
            const Expanded(child: Text('Nova Corrida!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isListeningForVoice ? Colors.green[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isListeningForVoice ? Icons.mic : Icons.mic_off,
                    color: _isListeningForVoice ? Colors.green : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isListeningForVoice 
                        ? '🎤 Diga "Aceito" ou "Não aceito"' 
                        : 'Ouvindo...',
                    style: TextStyle(
                      color: _isListeningForVoice ? Colors.green[700] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person, 'Passageiro', ride.passengerId.substring(0, 12)),
            _buildInfoRow(Icons.location_on, 'Origem', 
                '${ride.pickupLat.toStringAsFixed(4)}, ${ride.pickupLng.toStringAsFixed(4)}'),
            const SizedBox(height: 16),
            const Text(
              '⚠️ Não use o celular enquanto dirige!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isToggling ? null : _rejectRide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.close, size: 32),
                      SizedBox(height: 4),
                      Text('NÃO ACEITO', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isToggling ? null : _acceptRide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.check, size: 32),
                      SizedBox(height: 4),
                      Text('ACEITO', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // ✅ Botões de debug para teste sem voz
          if (kDebugMode) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _acceptRide,
                  child: const Text('🎯 [DEBUG] Aceitar'),
                ),
                TextButton(
                  onPressed: _rejectRide,
                  child: const Text('🎯 [DEBUG] Recusar'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey[600])),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  void _acceptRide() {
    if (_pendingRide == null) return;
    try {
      _voiceService.stopListening();
      if (mounted) Navigator.pop(context);
      setState(() {
        _activeRide = _pendingRide!.copyWith(status: RideStatus.accepted);
        _pendingRide = null;
      });
      _authService.saveRide(_activeRide!);
      _authService.updateRideStatus(_activeRide!.id, RideStatus.accepted);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Corrida aceita!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Erro ao aceitar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao aceitar corrida')),
        );
      }
    }
  }

  void _rejectRide() {
    if (_pendingRide == null) return;
    try {
      _voiceService.stopListening();
      if (mounted) Navigator.pop(context);
      setState(() => _pendingRide = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Corrida recusada'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Erro ao rejeitar: $e');
    }
  }

  void _openNavigation(double lat, double lng) async {
    try {
      final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o navegador')),
        );
      }
    } catch (e) {
      print('Erro ao navegar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao abrir navegação')),
        );
      }
    }
  }

  void _completeRide() async {
    if (_activeRide == null) return;
    try {
      await _authService.updateRideStatus(_activeRide!.id, RideStatus.completed);
      if (mounted) {
        setState(() => _activeRide = _activeRide!.copyWith(status: RideStatus.completed));
        _showPassengerRatingDialog();
      }
    } catch (e) {
      print('Erro ao concluir: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao concluir corrida')),
        );
      }
    }
  }

  void _showPassengerRatingDialog() {
    int selectedRating = 5;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Avaliar Passageiro'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Como foi a experiência?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(Icons.star, color: index < selectedRating ? Colors.amber : Colors.grey, size: 40),
                  onPressed: () => setDialogState(() => selectedRating = index + 1),
                )),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _activeRide = null);
              },
              child: const Text('Pular'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _activeRide = null);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('⭐ Avaliação enviada!')),
                  );
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Tela de ERRO com botão de retry
  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Motorista'), backgroundColor: Colors.red),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Erro ao carregar',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Erro desconhecido',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _initializeDriver(); // ✅ Tenta novamente
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar Novamente'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await _authService.logout();
                  if (mounted) context.go('/login');
                },
                child: const Text('Voltar ao Login'),
              ),
              // ✅ Mostra stack trace em debug mode
              if (kDebugMode && _errorMessage != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Debug: $_errorMessage',
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Mostra loading apenas enquanto carrega
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Carregando perfil do motorista...'),
            ],
          ),
        ),
      );
    }

    // ✅ Mostra tela de erro se houve falha
    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    // ✅ Previne build se driver ainda é null (fallback de segurança)
    if (_driver == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Dados do motorista não encontrados'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await _authService.logout();
                  if (mounted) context.go('/login');
                },
                child: const Text('Fazer Login Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ UI Principal do Motorista
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motorista'),
        backgroundColor: _isAvailable ? Colors.green[700] : Colors.grey[700],
        actions: [
          _isToggling
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(
                  icon: Icon(_isAvailable ? Icons.check_circle : Icons.cancel),
                  onPressed: _toggleAvailability,
                  tooltip: _isAvailable ? 'Ficar Offline' : 'Ficar Online',
                ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/driver/settings'),
          ),
          // ✅ Botão de debug para simular corrida
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report, color: Colors.purple),
              onPressed: _simulateIncomingRide,
              tooltip: 'Simular corrida (DEBUG)',
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _currentLocation, zoom: 15),
            markers: {
              Marker(
                markerId: const MarkerId('driver_location'),
                position: _currentLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  _isAvailable ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange,
                ),
                infoWindow: InfoWindow(
                  title: _isAvailable ? '🟢 Online' : '🔴 Offline',
                  snippet: _driver?.vehicleFullInfo,
                ),
              ),
              if (_activeRide != null)
                Marker(
                  markerId: const MarkerId('passenger_location'),
                  position: LatLng(_activeRide!.pickupLat, _activeRide!.pickupLng),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  infoWindow: const InfoWindow(title: '📍 Passageiro', snippet: 'Destino'),
                ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),
          Positioned(
            top: 16, left: 16, right: 16,
            child: Card(
              color: _isAvailable ? Colors.green[50] : Colors.grey[100],
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isAvailable ? Colors.green[200] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.directions_car, color: _isAvailable ? Colors.green[800] : Colors.grey[600]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isAvailable ? '🟢 Online para corridas' : '🔴 Offline',
                            style: TextStyle(fontWeight: FontWeight.bold, color: _isAvailable ? Colors.green[800] : Colors.grey[600]),
                          ),
                          Text(_driver?.vehicleFullInfo ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    if (_isListeningForVoice)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green[200], borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Icon(Icons.mic, color: Colors.green[700], size: 16),
                            const SizedBox(width: 4),
                            Text('Ouvindo', style: TextStyle(fontSize: 10, color: Colors.green[700])),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_activeRide != null)
            Positioned(
              bottom: 100, left: 16, right: 16,
              child: Card(
                color: Colors.amber[50],
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.directions_car, color: Colors.amber[700]),
                          const SizedBox(width: 8),
                          Text(_activeRide!.statusLabel, style: TextStyle(fontWeight: FontWeight.bold, color: _activeRide!.statusColor, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _openNavigation(_activeRide!.pickupLat, _activeRide!.pickupLng),
                              icon: const Icon(Icons.navigation),
                              label: const Text('Navegar'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _activeRide!.status == RideStatus.accepted
                                  ? () {
                                      _authService.updateRideStatus(_activeRide!.id, RideStatus.in_progress);
                                      setState(() => _activeRide = _activeRide!.copyWith(status: RideStatus.in_progress));
                                    }
                                  : _completeRide,
                              icon: Icon(_activeRide!.status == RideStatus.accepted ? Icons.play_arrow : Icons.check),
                              label: Text(_activeRide!.status == RideStatus.accepted ? 'Iniciar' : 'Concluir'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _activeRide!.status == RideStatus.accepted ? Colors.green : Colors.amber[700],
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            right: 16, bottom: 20,
            child: FloatingActionButton(
              heroTag: 'center_map',
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () => _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation, 16)),
              child: Icon(Icons.my_location, color: Colors.amber[700]),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.amber[700]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Icon(Icons.directions_car, color: Colors.amber[700], size: 30)),
                  const SizedBox(height: 8),
                  Text(_driver?.name ?? 'Motorista', style: const TextStyle(color: Colors.white, fontSize: 18)),
                  Text(_driver?.vehicleFullInfo ?? '', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                ],
              ),
            ),
            ListTile(leading: const Icon(Icons.person), title: const Text('Perfil'), onTap: () { Navigator.pop(context); context.push('/driver/profile'); }),
            ListTile(leading: const Icon(Icons.history), title: const Text('Corridas'), onTap: () { Navigator.pop(context); context.push('/driver/rides'); }),
            ListTile(leading: const Icon(Icons.account_balance_wallet), title: const Text('Ganhos'), onTap: () {}),
            ListTile(leading: const Icon(Icons.settings), title: const Text('Configurações'), onTap: () { Navigator.pop(context); context.push('/driver/settings'); }),
            ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Sair', style: TextStyle(color: Colors.red)), onTap: () async { await _authService.logout(); if (mounted) context.go('/login'); }),
          ],
        ),
      ),
    );
  }

  // ✅ Método para simular corrida (apenas em debug)
  void _simulateIncomingRide() {
    if (!kDebugMode) return;
    final mockRide = RideModel(
      passengerId: 'debug_passenger_${DateTime.now().millisecond}',
      pickupLat: _currentLocation.latitude + 0.001,
      pickupLng: _currentLocation.longitude + 0.001,
      status: RideStatus.requested,
    );
    _showRideRequestDialog(mockRide);
  }
}