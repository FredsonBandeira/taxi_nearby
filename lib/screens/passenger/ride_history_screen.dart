// lib/screens/passenger/ride_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_mock_service.dart';
import '../../models/ride_model.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  final AuthService _authService = AuthService();
  List<RideModel> _rides = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides() async {
    final userId = _authService.currentUser?.id;
    if (userId != null) {
      final rides = await _authService.getRideHistory(userId);
      setState(() {
        _rides = rides.reversed.toList(); // Mais recentes primeiro
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Corridas'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rides.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rides.length,
                  itemBuilder: (context, index) => _buildRideCard(_rides[index]),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhuma corrida ainda',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Sua primeira corrida aparecerá aqui',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(RideModel ride) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
              if (ride.driverName != null) ...[
                Row(
                  children: [
                    const Icon(Icons.directions_car, size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${ride.driverName} • ${ride.vehicleInfo}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Pickup: ${ride.pickupLat.toStringAsFixed(4)}, ${ride.pickupLng.toStringAsFixed(4)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              if (ride.fare != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total:',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      'CV\$ ${ride.fare!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
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
                width: 40, height: 4,
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
                Text(
                  'Detalhes da Corrida',
                  style: Theme.of(context).textTheme.titleLarge,
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
            if (ride.driverName != null) ...[
              _buildDetailRow('Motorista', ride.driverName!),
              _buildDetailRow('Veículo', ride.vehicleInfo ?? '-'),
            ],
            _buildDetailRow('Pickup', '${ride.pickupLat}, ${ride.pickupLng}'),
            if (ride.dropoffLat != null)
              _buildDetailRow('Dropoff', '${ride.dropoffLat}, ${ride.dropoffLng}'),
            if (ride.fare != null)
              _buildDetailRow('Valor', 'CV\$ ${ride.fare!.toStringAsFixed(2)}', 
                isHighlighted: true),
            if (ride.rating != null)
              _buildDetailRow('Avaliação', '⭐ ${ride.rating}'),
            if (ride.notes != null) ...[
              const SizedBox(height: 8),
              Text('Observações:', style: TextStyle(fontWeight: FontWeight.w500)),
              Text(ride.notes!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
              color: isHighlighted ? Colors.green[700] : null,
            ),
          ),
        ],
      ),
    );
  }
}