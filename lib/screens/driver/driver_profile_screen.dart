// lib/screens/driver/driver_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_mock_service.dart';
import '../../models/driver.dart';
import './driver_rides_screen.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final AuthService _authService = AuthService();
  DriverModel? _driver;
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadDriver();
  }

  void _loadDriver() {
    final user = _authService.currentUser;
    if (user is DriverModel) {
      setState(() {
        _driver = user;
        _isAvailable = user.isAvailable;
      });
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    if (_driver == null) return;
    
    final updated = _driver!.copyWith(isAvailable: value);
    await _authService.updateProfile(updated);
    
    setState(() {
      _driver = updated;
      _isAvailable = value;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? '🟢 Você está ONLINE para corridas' : '🔴 Você está OFFLINE'),
        backgroundColor: value ? Colors.green[700] : Colors.grey[700],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_driver == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do Motorista'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/driver/edit-profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Card de Status
            Card(
              color: _isAvailable ? Colors.green[50] : Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.amber[100],
                      child: Icon(Icons.directions_car, size: 30, color: Colors.amber[800]),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_driver!.name, 
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(_driver!.vehicleFullInfo,
                            style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Icon(Icons.star, color: Colors.amber[600]),
                        Text('${_driver!.rating}', 
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Toggle de Disponibilidade
            Card(
              child: ListTile(
                title: const Text('Disponível para corridas'),
                subtitle: Text(_isAvailable 
                  ? '✅ Recebendo solicitações' 
                  : '❌ Não receberá novas corridas'),
                trailing: Switch(
                  value: _isAvailable,
                  onChanged: _toggleAvailability,
                  activeColor: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Informações do Veículo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🚗 Informações do Veículo',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Divider(),
                    _buildInfoRow('Modelo', _driver!.vehicleModel),
                    _buildInfoRow('Placa', _driver!.licensePlate),
                    _buildInfoRow('Cor', _driver!.color),
                    _buildInfoRow('Ano', _driver!.year.toString()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Estatísticas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📊 Estatísticas',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('Corridas', '${_driver!.totalRides}'),
                        _buildStat('Avaliação', '${_driver!.rating} ⭐'),
                        _buildStat('Online', _isAvailable ? 'Sim' : 'Não'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Menu de Ações
            ListTile(
              leading: Icon(Icons.history, color: Colors.blue[700]),
              title: const Text('Histórico de Corridas'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/driver/rides'),
            ),
            ListTile(
              leading: Icon(Icons.account_balance_wallet, color: Colors.green[700]),
              title: const Text('Ganhos'),
              trailing: const Text('CV\$ 12.450', 
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.settings, color: Colors.grey[700]),
              title: const Text('Configurações'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings'),
            ),
            
            const SizedBox(height: 24),
            
            // Botão Sair
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await _authService.logout();
                  if (mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Sair da Conta', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}