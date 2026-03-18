// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:async'; // ✅ Necessário para StreamController
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/driver.dart';
import '../models/ride_model.dart';

class AuthService {
  // === CONSTANTES ===
  static const String _userKey = 'taxi_app_current_user';
  static const String _ridesKey = 'taxi_app_rides';
  
  // === SINGLETON ===
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // === STREAM NATIVO (Substitui implementação manual) ===
  final _userStreamController = StreamController<UserModel?>.broadcast();
  Stream<UserModel?> get userStream => _userStreamController.stream;
  
  // Cache do usuário atual
  UserModel? _currentUserCache;
  UserModel? get currentUser => _currentUserCache;

  // === INICIALIZAÇÃO ===
  Future<void> init() async {
    final user = await getCurrentUser();
    _currentUserCache = user;
    _userStreamController.add(user);
  }

  // === AUTH: REGISTER ===
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    String? vehicleModel,
    String? licensePlate,
    String? color,
    int? year,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simular rede
    
    if (email.isEmpty || password.length < 6) return false;
    
    final user = role == UserRole.driver
        ? DriverModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: name, 
            email: email, 
            phone: phone,
            vehicleModel: vehicleModel ?? 'Toyota Corolla',
            licensePlate: licensePlate ?? 'CV-00-00',
            color: color ?? 'Amarelo', 
            year: year ?? 2020,
          )
        : UserModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: name, 
            email: email, 
            phone: phone, 
            role: role,
          );
    
    await _saveUser(user);
    return true;
  }

  // === AUTH: LOGIN ===
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

  // === AUTH: LOGOUT ===
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    _currentUserCache = null;
    _userStreamController.add(null);
  }

  // === AUTH: GET CURRENT USER ===
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

  // === AUTH: SAVE USER (PRIVADO) ===
  Future<void> _saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toMap()));
    
    // Atualiza cache e notifica stream
    _currentUserCache = user;
    _userStreamController.add(user);
  }

  // === AUTH: UPDATE PROFILE ===
  Future<void> updateProfile(UserModel updatedUser) async {
    await _saveUser(updatedUser);
  }

  // === RIDES: GET HISTORY ===
  Future<List<RideModel>> getRideHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final ridesJson = prefs.getStringList('${_ridesKey}_$userId') ?? [];
    
    return ridesJson
        .map((json) => RideModel.fromMap(jsonDecode(json)))
        .toList();
  }

  // === RIDES: SAVE RIDE ===
  Future<void> saveRide(RideModel ride) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_ridesKey}_${ride.passengerId}';
    final ridesJson = prefs.getStringList(key) ?? [];
    
    ridesJson.add(jsonEncode(ride.toMap()));
    await prefs.setStringList(key, ridesJson);
  }

  // === RIDES: UPDATE STATUS ===
  Future<void> updateRideStatus(
    String rideId, 
    RideStatus newStatus, {
    String? userId,
  }) async {
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

  // === MOCK: DRIVERS PARA MAPA ===
  List<DriverModel> getMockDrivers() {
    return [
      DriverModel(
        id: 'mock_1', 
        name: 'João Silva', 
        email: 'joao@taxi.cv',
        phone: '+238 991 2345', 
        vehicleModel: 'Toyota Corolla',
        licensePlate: 'CV-12-34', 
        color: 'Amarelo', 
        year: 2019,
        isAvailable: true, 
        latitude: 16.7430, 
        longitude: -22.9355,
        rating: 4.9, 
        totalRides: 234,
      ),
      DriverModel(
        id: 'mock_2', 
        name: 'Maria Santos', 
        email: 'maria@taxi.cv',
        phone: '+238 992 3456', 
        vehicleModel: 'Hyundai Accent',
        licensePlate: 'CV-56-78', 
        color: 'Branco', 
        year: 2021,
        isAvailable: true, 
        latitude: 16.7415, 
        longitude: -22.9340,
        rating: 4.7, 
        totalRides: 156,
      ),
      DriverModel(
        id: 'mock_3', 
        name: 'Carlos Mendes', 
        email: 'carlos@taxi.cv',
        phone: '+238 993 4567', 
        vehicleModel: 'Kia Rio',
        licensePlate: 'CV-90-12', 
        color: 'Preto', 
        year: 2020,
        isAvailable: false, 
        latitude: 16.7425, 
        longitude: -22.9330,
        rating: 4.8, 
        totalRides: 189,
      ),
    ];
  }

  // === CLEANUP: Fechar stream (boa prática) ===
  void dispose() {
    _userStreamController.close();
  }
}

// === EXTENSÃO ÚTIL (Opcional) ===
extension StringExtension on String {
  String? get firstOrNull => length > 0 ? this[0].toString() : null;
}