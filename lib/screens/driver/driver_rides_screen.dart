// lib/screens/driver/driver_rides_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_mock_service.dart';
import '../../models/ride_model.dart';
import '../../models/driver.dart';

class DriverRidesScreen extends StatefulWidget {
  const DriverRidesScreen({super.key});

  @override
  State<DriverRidesScreen> createState() => _DriverRidesScreenState();
}

class _DriverRidesScreenState extends State<DriverRidesScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  List<RideModel> _rides = [];
  bool _isLoading = true;
  late TabController _tabController;
  
  String _selectedPeriod = 'today'; // today, week, month, all

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadRides();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRides() async {
    final user = _authService.currentUser;
    if (user != null) {
      // Mock: carrega corridas do histórico do passageiro
      // Em produção, seria uma query específica para o driver
      final rides = await _authService.getRideHistory(user.id);
      
      // Filtra apenas corridas concluídas ou em andamento
      final driverRides = rides.where((ride) => 
        ride.status == RideStatus.completed || 
        ride.status == RideStatus.in_progress ||
        ride.status == RideStatus.accepted
      ).toList();
      
      setState(() {
        _rides = driverRides.reversed.toList();
        _isLoading = false;
      });
    }
  }

  double get _totalEarnings {
    return _rides
        .where((r) => r.status == RideStatus.completed && r.fare != null)
        .fold(0.0, (sum, ride) => sum + (ride.fare ?? 0));
  }

  int get _completedRides {
    return _rides.where((r) => r.status == RideStatus.completed).length;
  }

  @override
  Widget build(BuildContext context) {
    final driver = _authService.currentUser as DriverModel?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Corridas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Todas'),
            Tab(text: 'Concluídas'),
            Tab(text: 'Em Curso'),
            Tab(text: 'Canceladas'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Card de Resumo
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.amber[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  Icons.attach_money,
                  'Ganhos',
                  'CV\$ ${_totalEarnings.toStringAsFixed(2)}',
                  Colors.green,
                ),
                _buildSummaryItem(
                  Icons.check_circle,
                  'Corridas',
                  '$_completedRides',
                  Colors.blue,
                ),
                _buildSummaryItem(
                  Icons.star,
                  'Avaliação',
                  '${driver?.rating ?? '4.8'}',
                  Colors.amber,
                ),
              ],
            ),
          ),
          
          // Filtro de Período
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Período: ', style: TextStyle(fontWeight: FontWeight.w500)),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedPeriod,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'today', child: Text('Hoje')),
                      DropdownMenuItem(value: 'week', child: Text('Esta Semana')),
                      DropdownMenuItem(value: 'month', child: Text('Este Mês')),
                      DropdownMenuItem(value: 'all', child: Text('Todos')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedPeriod = value!);
                      _loadRides();
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Lista de Corridas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRideList(_rides), // Todas
                      _buildRideList(_rides.where((r) => r.status == RideStatus.completed).toList()),
                      _buildRideList(_rides.where((r) => r.status == RideStatus.in_progress || r.status == RideStatus.accepted).toList()),
                      _buildRideList(_rides.where((r) => r.status == RideStatus.cancelled).toList()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildRideList(List<RideModel> rides) {
    if (rides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhuma corrida',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rides.length,
      itemBuilder: (context, index) => _buildRideCard(rides[index]),
    );
  }

  Widget _buildRideCard(RideModel ride) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isCompleted = ride.status == RideStatus.completed;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isCompleted ? 2 : 4,
      color: isCompleted ? null : Colors.blue[50],
      child: InkWell(
        onTap: () => _showRideDetails(ride),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(
                      ride.statusLabel,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: ride.statusColor,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  Text(
                    dateFormat.format(ride.requestedAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Informação do Passageiro
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.amber[100],
                    child: Icon(Icons.person, size: 18, color: Colors.amber[800]),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Passageiro',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        Text(
                          ride.passengerId.substring(0, 12), // Mock ID
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  if (isCompleted && ride.fare != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'CV\$ ${ride.fare!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        if (ride.rating != null)
                          Row(
                            children: [
                              Icon(Icons.star, size: 14, color: Colors.amber[600]),
                              Text('${ride.rating}', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                      ],
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Localização
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${ride.pickupLat.toStringAsFixed(4)}, ${ride.pickupLng.toStringAsFixed(4)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              
              if (isCompleted) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Método: ${ride.paymentMethod ?? 'Dinheiro'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (ride.notes != null)
                      Icon(Icons.note, size: 16, color: Colors.grey[600]),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showRideDetails(RideModel ride) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Detalhes da Corrida',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(ride.statusLabel),
                  backgroundColor: ride.statusColor.withOpacity(0.2),
                  labelStyle: TextStyle(color: ride.statusColor, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const Divider(height: 32),
            
            _buildDetailRow('Data', DateFormat('dd/MM/yyyy HH:mm').format(ride.requestedAt)),
            _buildDetailRow('Passageiro', ride.passengerId.substring(0, 15)),
            _buildDetailRow('Pickup', '${ride.pickupLat}, ${ride.pickupLng}'),
            if (ride.dropoffLat != null)
              _buildDetailRow('Dropoff', '${ride.dropoffLat}, ${ride.dropoffLng}'),
            
            const Divider(height: 24),
            
            if (ride.fare != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Valor Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    'CV\$ ${ride.fare!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            
            if (ride.rating != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('Avaliação: ${ride.rating}/5'),
                ],
              ),
            ],
            
            if (ride.notes != null) ...[
              const SizedBox(height: 8),
              const Text('Observações:', style: TextStyle(fontWeight: FontWeight.w500)),
              Text(ride.notes!),
            ],
            
            const SizedBox(height: 16),
            
            if (ride.status == RideStatus.accepted || ride.status == RideStatus.in_progress)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _authService.updateRideStatus(
                      ride.id,
                      ride.status == RideStatus.accepted 
                          ? RideStatus.in_progress 
                          : RideStatus.completed,
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      _loadRides();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ride.status == RideStatus.accepted
                                ? 'Corrida iniciada! '
                                : 'Corrida concluída! 💰',
                          ),
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    ride.status == RideStatus.accepted 
                        ? Icons.play_arrow 
                        : Icons.check,
                  ),
                  label: Text(
                    ride.status == RideStatus.accepted 
                        ? 'Iniciar Corrida' 
                        : 'Concluir Corrida',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}