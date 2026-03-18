// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/driver.dart';
import '../models/ride_model.dart';

class AuthService {
  static const String _userKey = 'taxi_app_current_user';
  static const String _ridesKey = 'taxi_app_rides';
  
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _userStreamController = StreamController<UserModel?>.broadcast();
  Stream<UserModel?> get userStream => _userStreamController.stream;
  
  UserModel? _currentUserCache;
  UserModel? get currentUser => _currentUserCache;

  Future<void> init() async {
    final user = await getCurrentUser();
    _currentUserCache = user;
    _userStreamController.add(user);
  }

  // === AUTH: REGISTER (COMPLETO COM VALIDAÇÃO) ===
Future<Map<String, dynamic>> register({
  required String name,
  required String email,
  required String phone,
  required String password,
  required String confirmPassword,
  required UserRole role,
  String? vehicleModel,
  String? licensePlate,
  String? color,
  int? year,
  bool acceptTerms = false,
}) async {
  await Future.delayed(const Duration(milliseconds: 500)); // Simular rede
  
  // ✅ Validações
  final errors = <String>[];
  
  // Nome
  if (name.trim().length < 3) {
    errors.add('Nome deve ter pelo menos 3 caracteres');
  }
  
  // Email
  if (!email.contains('@') || !email.contains('.')) {
    errors.add('Email inválido');
  }
  
  // Telefone (formato Cabo Verde: +238 XXX XXXX)
  final phoneClean = phone.replaceAll(RegExp(r'\D'), '');
  if (phoneClean.length < 8) {
    errors.add('Telefone inválido (mínimo 8 dígitos)');
  }
  
  // Senha
  if (password.length < 6) {
    errors.add('Senha deve ter pelo menos 6 caracteres');
  }
  
  // Confirmar senha
  if (password != confirmPassword) {
    errors.add('Senhas não coincidem');
  }
  
  // Termos
  if (!acceptTerms) {
    errors.add('Você deve aceitar os termos de uso');
  }
  
  // Validações específicas para motorista
  if (role == UserRole.driver) {
    if (vehicleModel == null || vehicleModel.trim().isEmpty) {
      errors.add('Modelo do veículo é obrigatório');
    }
    if (licensePlate == null || licensePlate.trim().isEmpty) {
      errors.add('Placa do veículo é obrigatória');
    }
    if (color == null || color.trim().isEmpty) {
      errors.add('Cor do veículo é obrigatória');
    }
    if (year == null || year < 1990 || year > DateTime.now().year + 1) {
      errors.add('Ano do veículo inválido');
    }
  }
  
  // Se houver erros, retorna
  if (errors.isNotEmpty) {
    return {'success': false, 'errors': errors};
  }
  
  // ✅ Criar usuário
  final user = role == UserRole.driver
      ? DriverModel(
          id: 'driver_${DateTime.now().millisecondsSinceEpoch}',
          name: name.trim(),
          email: email.toLowerCase().trim(),
          phone: phoneClean,
          vehicleModel: vehicleModel!.trim(),
          licensePlate: licensePlate!.trim().toUpperCase(),
          color: color!.trim(),
          year: year!,
          isAvailable: false,
          latitude: 16.7421003,
          longitude: -22.9349121,
        )
      : UserModel(
          id: 'passenger_${DateTime.now().millisecondsSinceEpoch}',
          name: name.trim(),
          email: email.toLowerCase().trim(),
          phone: phoneClean,
          role: UserRole.passenger,
        );
  
  // ✅ Salvar no SharedPreferences
  await _saveUser(user);
  
  return {'success': true, 'user': user};
}

  Future<bool> login({
    required String email,
    required String password,
    UserRole role = UserRole.passenger,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (password.length < 6) return false;
    
    final user = UserModel(
      id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      name: email.split('@').firstOrNull ?? 'Usuário',
      email: email,
      phone: '+238 9XX XXXX',
      role: role,
    );
    
    await _saveUser(user);
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    _currentUserCache = null;
    _userStreamController.add(null);
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData == null) return null;
    try {
      final map = jsonDecode(userData);
      return map['role'] == 'driver' 
          ? DriverModel.fromMap(map) 
          : UserModel.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toMap()));
    _currentUserCache = user;
    _userStreamController.add(user);
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    await _saveUser(updatedUser);
  }

  Future<List<RideModel>> getRideHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final ridesJson = prefs.getStringList('${_ridesKey}_$userId') ?? [];
    return ridesJson.map((json) => RideModel.fromMap(jsonDecode(json))).toList();
  }

  Future<void> saveRide(RideModel ride) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_ridesKey}_${ride.passengerId}';
    final ridesJson = prefs.getStringList(key) ?? [];
    ridesJson.add(jsonEncode(ride.toMap()));
    await prefs.setStringList(key, ridesJson);
  }

  Future<void> updateRideStatus(String rideId, RideStatus newStatus, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = userId ?? currentUser?.id;
    if (currentUserId == null) return;
    
    final key = '${_ridesKey}_$currentUserId';
    final ridesJson = prefs.getStringList(key) ?? [];
    
    final updatedRides = ridesJson.map((json) {
      final map = jsonDecode(json);
      if (map['id'] == rideId) {
        map['status'] = newStatus.toString().split('.').last;
        if (newStatus == RideStatus.completed) {
          map['completedAt'] = DateTime.now().toIso8601String();
          map['fare'] = (20 + DateTime.now().second % 30).toDouble();
        }
      }
      return jsonEncode(map);
    }).toList();
    
    await prefs.setStringList(key, updatedRides);
  }

  List<DriverModel> getMockDrivers() {
    return [
      DriverModel(
        id: 'mock_1', name: 'João Silva', email: 'joao@taxi.cv',
        phone: '+238 991 2345', vehicleModel: 'Toyota Corolla',
        licensePlate: 'CV-12-34', color: 'Amarelo', year: 2019,
        isAvailable: true, latitude: 16.7430, longitude: -22.9355,
        rating: 4.9, totalRides: 234,
      ),
      DriverModel(
        id: 'mock_2', name: 'Maria Santos', email: 'maria@taxi.cv',
        phone: '+238 992 3456', vehicleModel: 'Hyundai Accent',
        licensePlate: 'CV-56-78', color: 'Branco', year: 2021,
        isAvailable: true, latitude: 16.7415, longitude: -22.9340,
        rating: 4.7, totalRides: 156,
      ),
      DriverModel(
        id: 'mock_3', name: 'Carlos Mendes', email: 'carlos@taxi.cv',
        phone: '+238 993 4567', vehicleModel: 'Kia Rio',
        licensePlate: 'CV-90-12', color: 'Preto', year: 2020,
        isAvailable: false, latitude: 16.7425, longitude: -22.9330,
        rating: 4.8, totalRides: 189,
      ),
    ];
  }

  void dispose() {
    _userStreamController.close();
  }
}

extension StringExtension on String {
  String? get firstOrNull => length > 0 ? this[0].toString() : null;
}