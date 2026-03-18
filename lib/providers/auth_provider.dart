// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:riverpod/riverpod.dart';
import '../models/user.dart';
import '../services/auth_mock_service.dart';

// Provider do serviço
final authServiceProvider = Provider((ref) => AuthService());

// Provider do estado de autenticação
final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final service = ref.watch(authServiceProvider);
  return AuthNotifier(service);
});

// Estado da autenticação
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Notifier para gerenciar o estado
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthNotifier(this._service) : super(AuthState()) {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    final user = await _service.getCurrentUser();
    state = state.copyWith(user: user);
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    String? vehicleModel,
    String? licensePlate,
    String? color,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final success = await _service.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
        vehicleModel: vehicleModel,
        licensePlate: licensePlate,
        color: color,
      );
      
      if (success) {
        await _checkCurrentUser();
      } else {
        state = state.copyWith(error: 'Falha no registro. Verifique os dados.');
      }
      return success;
    } catch (e) {
      state = state.copyWith(error: 'Erro: ${e.toString()}');
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> login(String email, String password) async {
  state = state.copyWith(isLoading: true, error: null);

  try {
    final success = await _service.login(email: email, password: password);

    if (success) {
      await _checkCurrentUser();
      return true;
    } else {
      state = state.copyWith(error: 'Email ou senha inválidos');
      return false;
    }
  } catch (e) {
    state = state.copyWith(error: 'Erro: ${e.toString()}');
    return false;
  } finally {
    state = state.copyWith(isLoading: false);
  }
}

  Future<void> logout() async {
    await _service.logout();
    state = AuthState();
  }
}