// lib/screens/passenger/passenger_home_screen.dart
import 'dart:async'; // ✅ ADICIONE ESTA LINHA
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/location_simulation_service.dart';
import '../../models/user.dart';
import '../../models/driver.dart';
import '../../models/ride_model.dart';
import 'profile_screen.dart';
import 'ride_history_screen.dart';
class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  final AuthService _authService = AuthService();
  final LocationSimulationService _locationService = LocationSimulationService();
  
  GoogleMapController? _mapController;
  UserModel? _user;
  
  // Localização central (Cabo Verde)
  static const LatLng _centerLocation = LatLng(16.7421003, -22.9349121);
  
  // Táxis e markers
  List<DriverModel> _nearbyTaxis = [];
  Set<Marker> _taxiMarkers = {};
  BitmapDescriptor? _taxiIcon;
  
  // Localização do passageiro
  LatLng _passengerLocation = _centerLocation;
  
  // Corrida ativa
  RideModel? _activeRide;
  DriverModel? _assignedDriver;
  Timer? _rideStatusTimer;

  @override
  void initState() {
    super.initState();
    _user = _authService.currentUser;
    _loadNearbyTaxis();
    _loadCustomMarkerIcon();
    _checkForActiveRide();
  }

  @override
  void dispose() {
    _rideStatusTimer?.cancel();
    super.dispose();
  }

  void _loadCustomMarkerIcon() async {
    _taxiIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/taxi_marker.png', // Ou use ícone padrão
    );
  }

  void _loadNearbyTaxis() {
    setState(() {
      _nearbyTaxis = _authService.getMockDrivers();
      _updateTaxiMarkers();
    });

    // Inicia simulação de movimento para cada táxi disponível
    for (final taxi in _nearbyTaxis.where((t) => t.isAvailable)) {
      _locationService.startDriverSimulation(
        taxi.id,
        startLat: taxi.latitude,
        startLng: taxi.longitude,
        onUpdate: (lat, lng) {
          if (mounted) {
            setState(() {
              taxi.latitude = lat;
              taxi.longitude = lng;
              _updateTaxiMarkers();
            });
          }
        },
        interval: const Duration(seconds: 2),
      );
    }
  }

  void _updateTaxiMarkers() {
    _taxiMarkers = _nearbyTaxis.map((taxi) {
      return Marker(
        markerId: MarkerId(taxi.id),
        position: LatLng(taxi.latitude, taxi.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          taxi.isAvailable 
              ? BitmapDescriptor.hueAzure 
              : BitmapDescriptor.hueOrange,
        ),
        infoWindow: InfoWindow(
          title: '🚕 ${taxi.name}',
          snippet: '${taxi.vehicleModel} - ${taxi.licensePlate}\n'
              '${taxi.isAvailable ? "✅ Disponível" : "❌ Ocupado"}',
          onTap: () => _showTaxiDetails(taxi),
        ),
      );
    }).toSet();

    // Marker do passageiro
    _taxiMarkers.add(
      Marker(
        markerId: const MarkerId('passenger_location'),
        position: _passengerLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(
          title: '📍 Sua Localização',
          snippet: 'Você está aqui',
        ),
      ),
    );

    // Marker do táxi atribuído (se houver corrida ativa)
    if (_assignedDriver != null) {
      _taxiMarkers.add(
        Marker(
          markerId: const MarkerId('assigned_taxi'),
          position: LatLng(_assignedDriver!.latitude, _assignedDriver!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: '🚖 Seu Táxi',
            snippet: '${_assignedDriver!.name} está a caminho!',
          ),
        ),
      );
    }
  }

  void _checkForActiveRide() {
    // Verifica se há corrida ativa no histórico
    // Em produção, seria uma query específica
  }

  void _showTaxiDetails(DriverModel taxi) {
    if (_activeRide != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você já tem uma corrida ativa!')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.amber[100],
                  child: Icon(Icons.person, size: 30, color: Colors.amber[800]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(taxi.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(taxi.isAvailable ? '✅ Disponível' : '❌ Ocupado',
                        style: TextStyle(
                          color: taxi.isAvailable ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        )),
                    ],
                  ),
                ),
                Icon(Icons.star, color: Colors.amber[600], size: 28),
                const Text('4.8', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow(Icons.directions_car, 'Veículo', '${taxi.vehicleModel} - ${taxi.color}'),
            _buildInfoRow(Icons.credit_card, 'Placa', taxi.licensePlate),
            _buildInfoRow(Icons.phone, 'Telefone', taxi.phone),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: taxi.isAvailable ? () => _requestRide(taxi) : null,
                icon: const Icon(Icons.directions_car),
                label: Text(taxi.isAvailable ? 'Solicitar Corrida' : 'Indisponível'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Text('$label: ', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _requestRide(DriverModel taxi) async {
    Navigator.pop(context);

    // Criar corrida
    _activeRide = RideModel(
      passengerId: _user?.id ?? 'unknown',
      driverId: taxi.id,
      pickupLat: _passengerLocation.latitude,
      pickupLng: _passengerLocation.longitude,
      status: RideStatus.requested,
    );

    // Salvar corrida
    await _authService.saveRide(_activeRide!);

    // Mostrar dialog de aguardando
    _showRideRequestDialog(taxi);

    // Simular aceitação após 3 segundos
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      // Atualizar status para accepted
      await _authService.updateRideStatus(_activeRide!.id, RideStatus.accepted);
      
      Navigator.pop(context); // Fecha dialog
      
      // Atribuir driver
      setState(() {
        _assignedDriver = taxi;
        _activeRide = _activeRide!.copyWith(
          status: RideStatus.accepted,
          driverId: taxi.id,
          driverName: taxi.name,
          vehicleInfo: '${taxi.vehicleModel} - ${taxi.licensePlate}',
        );
      });

      // Iniciar simulação de movimento do táxi até o passageiro
      _locationService.simulateMovementToDestination(
        id: taxi.id,
        startLat: taxi.latitude,
        startLng: taxi.longitude,
        endLat: _passengerLocation.latitude,
        endLng: _passengerLocation.longitude,
        onProgress: (lat, lng, arrived) {
          if (mounted) {
            setState(() {
              taxi.latitude = lat;
              taxi.longitude = lng;
              _updateTaxiMarkers();
            });

            if (arrived) {
              _completeRide();
            }
          }
        },
        totalDuration: const Duration(seconds: 20),
      );

      // Mostrar notificação de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[300]),
              const SizedBox(width: 8),
              Text('${taxi.name} aceitou a corrida! 🎉'),
            ],
          ),
          backgroundColor: Colors.green[800],
          duration: const Duration(seconds: 4),
        ),
      );

      // Iniciar timer para atualizar status
      _startRideStatusTimer();
    }
  }

  void _showRideRequestDialog(DriverModel taxi) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.local_taxi, color: Colors.amber[700]),
            const SizedBox(width: 8),
            const Text('Solicitando Corrida'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Motorista: ${taxi.name}'),
            Text('Veículo: ${taxi.vehicleModel}'),
            Text('Placa: ${taxi.licensePlate}'),
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            const Text(
              'Aguardando confirmação do motorista...',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _activeRide = null;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Solicitação cancelada')),
              );
            },
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _startRideStatusTimer() {
    _rideStatusTimer?.cancel();
    _rideStatusTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_activeRide == null) {
        timer.cancel();
        return;
      }

      // Atualizar status baseado no tempo
      final rideAge = DateTime.now().difference(_activeRide!.requestedAt);
      
      if (rideAge.inSeconds > 10 && _activeRide!.status == RideStatus.accepted) {
        await _authService.updateRideStatus(_activeRide!.id, RideStatus.in_progress);
        setState(() {
          _activeRide = _activeRide!.copyWith(status: RideStatus.in_progress);
        });
      }
    });
  }

  Future<void> _completeRide() async {
    if (_activeRide == null) return;

    await _authService.updateRideStatus(_activeRide!.id, RideStatus.completed);
    
    setState(() {
      _activeRide = _activeRide!.copyWith(status: RideStatus.completed);
      _assignedDriver = null;
    });

    _locationService.stopDriverSimulation(_activeRide!.driverId ?? '');

    if (mounted) {
      // Mostrar dialog de conclusão
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Corrida Concluída!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Valor: CV\$ ${_activeRide!.fare?.toStringAsFixed(2) ?? '25.00'}'),
              const SizedBox(height: 16),
              const Text('Como foi sua experiência?'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(Icons.star, color: Colors.amber[600], size: 32),
                  onPressed: () => Navigator.pop(context),
                )),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _activeRide = null);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _centerOnMyLocation() {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_passengerLocation, 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Taxi Nearby'),
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNearbyTaxis,
            tooltip: 'Atualizar táxis',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/passenger/profile'),
            tooltip: 'Perfil',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _centerLocation,
              zoom: 15,
            ),
            markers: _taxiMarkers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
          ),
          
          // Card de status da corrida ativa
          if (_activeRide != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.amber[50],
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _activeRide!.statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.directions_car,
                          color: _activeRide!.statusColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _activeRide!.statusLabel,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _activeRide!.statusColor,
                              ),
                            ),
                            if (_assignedDriver != null)
                              Text(
                                '${_assignedDriver!.name} • ${_assignedDriver!.vehicleModel}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                          ],
                        ),
                      ),
                      if (_activeRide!.status == RideStatus.completed)
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _activeRide = null),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Botão de localização
          Positioned(
            right: 16,
            bottom: 120,
            child: FloatingActionButton(
              heroTag: 'location_btn',
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _centerOnMyLocation,
              child: Icon(Icons.my_location, color: Colors.amber[700]),
            ),
          ),
          
          // Botão solicitar (flutuante)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_nearbyTaxis.where((t) => t.isAvailable).length} táxis disponíveis',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Toque no mapa para ver detalhes',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _activeRide != null ? null : () {
                        final available = _nearbyTaxis.where((t) => t.isAvailable).toList();
                        if (available.isNotEmpty) {
                          _showTaxiDetails(available.first);
                        }
                      },
                      icon: const Icon(Icons.directions_car),
                      label: const Text('Solicitar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
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
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.amber[700], size: 30),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _user?.name ?? 'Usuário',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    _user?.email ?? '',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.pop(context);
                context.push('/passenger/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Histórico de Corridas'),
              onTap: () {
                Navigator.pop(context);
                context.push('/passenger/rides');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configurações'),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sair', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await _authService.logout();
                if (mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}