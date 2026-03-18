// lib/core/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/driver/driver_settings_screen.dart';
import '../services/auth_mock_service.dart';
import '../models/user.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/passenger/passenger_home_screen.dart';
import '../screens/passenger/profile_screen.dart';
import '../screens/passenger/ride_history_screen.dart';
import '../screens/driver/driver_home_screen.dart';
import '../screens/driver/driver_profile_screen.dart';
import '../screens/driver/driver_rides_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final user = AuthService().currentUser;
      final isLoggedIn = user != null;
      final isGoingToAuth = state.matchedLocation == '/login' ||
                           state.matchedLocation == '/register' ||
                           state.matchedLocation == '/';

      if (!isLoggedIn && !isGoingToAuth) return '/login';
       if (isLoggedIn && isGoingToAuth) {
        if (user.role == UserRole.admin) return '/admin/dashboard';
        return user.role == UserRole.driver ? '/driver/home' : '/passenger/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => RegisterScreen(initialRole: s.extra as UserRole?)),
      
      // Passageiro
      GoRoute(path: '/passenger/home', builder: (c, s) => const PassengerHomeScreen()),
      GoRoute(path: '/passenger/profile', builder: (c, s) => const PassengerProfileScreen()),
      GoRoute(path: '/passenger/rides', builder: (c, s) => const RideHistoryScreen()),
      
      // Motorista
      GoRoute(path: '/driver/home', builder: (c, s) => const DriverHomeScreen()),
      GoRoute(path: '/driver/profile', builder: (c, s) => const DriverProfileScreen()),
      GoRoute(path: '/driver/rides', builder: (c, s) => const DriverRidesScreen()),
      GoRoute(path: '/driver/settings', builder: (c, s) => const DriverSettingsScreen()),
      
         // ✅ Admin
      GoRoute(path: '/admin/dashboard', builder: (c, s) => const AdminDashboardScreen()),
      
      // Global
      GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),

    ],
  );
}