// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_mock_service.dart';
import '../models/user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.passenger;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() { _isLoading = true; _error = null; });
    
    final success = await AuthService().login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
    );
    
    if (!mounted) return;
    
    if (success) {
      final user = AuthService().currentUser;
      if (user?.role == UserRole.driver) {
        context.go('/driver/home');
      } else {
        context.go('/passenger/home');
      }
    } else {
      setState(() {
        _isLoading = false;
        _error = 'Email ou senha inválidos';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_taxi, size: 80, color: Colors.amber[700]),
                const SizedBox(height: 16),
                Text('Taxi Nearby',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber[700])),
                const SizedBox(height: 32),
                
                SegmentedButton<UserRole>(
                  segments: const [
                    ButtonSegment(value: UserRole.passenger, label: Text('Passageiro'), icon: Icon(Icons.person)),
                    ButtonSegment(value: UserRole.driver, label: Text('Motorista'), icon: Icon(Icons.directions_car)),
                  ],
                  selected: {_selectedRole},
                  onSelectionChanged: (s) => setState(() => _selectedRole = s.first),
                ),
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v?.isEmpty ?? true ? 'Digite seu email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                  obscureText: true,
                  validator: (v) => (v?.length ?? 0) < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700], foregroundColor: Colors.white),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Entrar', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.push('/register', extra: _selectedRole),
                  child: const Text('Não tem conta? Registre-se'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}