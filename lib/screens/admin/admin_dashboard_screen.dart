// lib/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import '../../models/driver.dart';
import '../../models/ride_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AuthService _authService = AuthService();
  
  // Dados
  List<UserModel> _passengers = [];
  List<DriverModel> _drivers = [];
  List<RideModel> _allRides = [];
  
  // Estatísticas
  int _totalUsers = 0;
  int _totalDrivers = 0;
  int _totalRides = 0;
  double _totalRevenue = 0;
  
  bool _isLoading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // ✅ Carregar todos os usuários (simulado - em produção seria uma query)
      // Aqui vamos usar dados mock + usuário atual
      final currentUser = _authService.currentUser;
      
      // Mock de dados para demonstração
      _passengers = [
        UserModel(
          id: 'pass_1', name: 'João Silva', email: 'joao@email.com',
          phone: '+238991234567', role: UserRole.passenger,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        UserModel(
          id: 'pass_2', name: 'Maria Santos', email: 'maria@email.com',
          phone: '+238992345678', role: UserRole.passenger,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ];
      
      _drivers = _authService.getMockDrivers();
      
      // Mock de corridas
      _allRides = [
        RideModel(
          id: 'ride_1', passengerId: 'pass_1', driverId: 'mock_1',
          driverName: 'João Silva', vehicleInfo: 'Toyota Corolla - CV-12-34',
          pickupLat: 16.7421, pickupLng: -22.9349,
          status: RideStatus.completed, fare: 250.0,
          requestedAt: DateTime.now().subtract(const Duration(hours: 2)),
          completedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        RideModel(
          id: 'ride_2', passengerId: 'pass_2', driverId: 'mock_2',
          driverName: 'Maria Santos', vehicleInfo: 'Hyundai Accent - CV-56-78',
          pickupLat: 16.7430, pickupLng: -22.9355,
          status: RideStatus.in_progress, fare: 180.0,
          requestedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      ];
      
      // Calcular estatísticas
      setState(() {
        _totalUsers = _passengers.length + 1; // +1 usuário atual
        _totalDrivers = _drivers.length;
        _totalRides = _allRides.length;
        _totalRevenue = _allRides.where((r) => r.isCompleted).fold(
          0.0, (sum, ride) => sum + (ride.fare ?? 0),
        );
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar dados: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Admin'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
            tooltip: 'Atualizar dados',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              if (mounted) context.go('/login');
            },
            tooltip: 'Sair',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ✅ Cards de Estatísticas
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.purple[50],
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard('👥 Usuários', '$_totalUsers', Colors.blue),
                      _buildStatCard('🚕 Motoristas', '$_totalDrivers', Colors.amber),
                      _buildStatCard('📊 Corridas', '$_totalRides', Colors.green),
                      _buildStatCard('💰 Receita', 'CV\$ ${_totalRevenue.toStringAsFixed(0)}', Colors.purple),
                    ],
                  ),
                ),
                
                // ✅ Tabs
                TabBar(
                  tabs: const [
                    Tab(text: '👥 Passageiros'),
                    Tab(text: '🚕 Motoristas'),
                    Tab(text: '📊 Corridas'),
                  ],
                  onTap: (index) => setState(() => _selectedTab = index),
                  labelColor: Colors.purple[700],
                  unselectedLabelColor: Colors.grey,
                ),
                
                // ✅ Lista baseada na tab selecionada
                Expanded(
                  child: IndexedStack(
                    index: _selectedTab,
                    children: [
                      _buildPassengersList(),
                      _buildDriversList(),
                      _buildRidesList(),
                    ],
                  ),
                ),
              ],
            ),
      drawer: _buildDrawer(),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengersList() {
    if (_passengers.isEmpty) {
      return const Center(child: Text('Nenhum passageiro cadastrado'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _passengers.length,
      itemBuilder: (context, index) {
        final passenger = _passengers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.person, color: Colors.blue[700]),
            ),
            title: Text(passenger.name),
            subtitle: Text(passenger.email),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(passenger.phone, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(
                  'Desde ${passenger.createdAt.day}/${passenger.createdAt.month}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDriversList() {
    if (_drivers.isEmpty) {
      return const Center(child: Text('Nenhum motorista cadastrado'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _drivers.length,
      itemBuilder: (context, index) {
        final driver = _drivers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: driver.isAvailable ? Colors.green[100] : Colors.grey[100],
              child: Icon(Icons.directions_car, color: driver.isAvailable ? Colors.green[700] : Colors.grey[700]),
            ),
            title: Text(driver.name),
            subtitle: Text('${driver.vehicleModel} - ${driver.licensePlate}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: driver.isAvailable ? Colors.green[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    driver.isAvailable ? '🟢 Online' : '🔴 Offline',
                    style: TextStyle(fontSize: 10, color: driver.isAvailable ? Colors.green[700] : Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 12, color: Colors.amber[600]),
                    Text('${driver.rating}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildRidesList() {
    if (_allRides.isEmpty) {
      return const Center(child: Text('Nenhuma corrida registrada'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allRides.length,
      itemBuilder: (context, index) {
        final ride = _allRides[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Chip(
                      label: Text(ride.statusLabel, style: const TextStyle(color: Colors.white, fontSize: 12)),
                      backgroundColor: ride.statusColor,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    Text(
                      'CV\$ ${ride.fare?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Motorista: ${ride.driverName ?? 'N/A'}', style: TextStyle(fontWeight: FontWeight.w500)),
                Text('Veículo: ${ride.vehicleInfo ?? 'N/A'}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(
                  'Data: ${ride.requestedAt.day}/${ride.requestedAt.month} ${ride.requestedAt.hour}:${ride.requestedAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.purple[700]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.admin_panel_settings, color: Colors.purple[700], size: 30),
                ),
                const SizedBox(height: 8),
                const Text('Administrador', style: TextStyle(color: Colors.white, fontSize: 18)),
                Text(_authService.currentUser?.email ?? '', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Passageiros'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedTab = 0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.directions_car),
            title: const Text('Motoristas'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedTab = 1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Corridas'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedTab = 2);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configurações'),
            onTap: () {},
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
    );
  }
}