// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../core/constants.dart';

class RegisterScreen extends StatefulWidget {
  final UserRole? initialRole;
  
  const RegisterScreen({super.key, this.initialRole});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _adminCodeController = TextEditingController();
  
  // Controllers para motorista
  final _vehicleController = TextEditingController();
  final _plateController = TextEditingController();
  final _colorController = TextEditingController();
  final _yearController = TextEditingController();
  
  // Estado
  bool _isLoading = false;
  bool _acceptTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscureAdminCode = true;
  UserRole _selectedRole = UserRole.passenger;
  bool _showAdminCodeField = false;
  
  List<String> _errors = [];

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole ?? UserRole.passenger;
    _yearController.text = DateTime.now().year.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _adminCodeController.dispose();
    _vehicleController.dispose();
    _plateController.dispose();
    _colorController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _toggleAdminCodeField() {
    setState(() {
      _showAdminCodeField = !_showAdminCodeField;
      if (!_showAdminCodeField) {
        _adminCodeController.clear();
      }
    });
  }

 // ANTES (com Riverpod):
// final authState = ref.watch(authProvider);
// final success = await ref.read(authProvider.notifier).register(...);

// DEPOIS (sem Riverpod):
Future<void> _handleRegister() async {
  if (!_formKey.currentState!.validate()) return;
  if (!_acceptTerms) {
    setState(() {
      _errors = ['Você deve aceitar os termos de uso'];
    });
    return;
  }

  // ✅ Validar código admin se for registrar como admin
  if (_selectedRole == UserRole.admin) {
    if (_adminCodeController.text != AppConstants.adminSecretCode) {
      setState(() {
        _errors = ['Código de administrador inválido'];
      });
      return;
    }
  }

  setState(() {
    _isLoading = true;
    _errors = [];
  });

  try {
    // ✅ Usar AuthService diretamente (sem Riverpod)
    final result = await AuthService().register(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      role: _selectedRole,
      vehicleModel: _selectedRole == UserRole.driver ? _vehicleController.text : null,
      licensePlate: _selectedRole == UserRole.driver ? _plateController.text : null,
      color: _selectedRole == UserRole.driver ? _colorController.text : null,
      year: _selectedRole == UserRole.driver ? int.tryParse(_yearController.text) : null,
      acceptTerms: _acceptTerms,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[300]),
              SizedBox(width: 8),
              Text('Cadastro realizado com sucesso!'),
            ],
          ),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 3),
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          if (_selectedRole == UserRole.admin) {
            context.go('/admin/dashboard');
          } else if (_selectedRole == UserRole.driver) {
            context.go('/driver/home');
          } else {
            context.go('/passenger/home');
          }
        }
      });
    } else {
      setState(() {
        _errors = List<String>.from(result['errors'] ?? []);
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _errors = ['Erro inesperado: ${e.toString()}'];
      });
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final isDriver = _selectedRole == UserRole.driver;
    final isAdmin = _selectedRole == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Conta'),
        backgroundColor: isAdmin ? Colors.purple[700] : Colors.amber[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ✅ Seleção de Tipo de Conta (3 opções)
              Card(
                color: isAdmin ? Colors.purple[50] : Colors.amber[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Tipo de Conta',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<UserRole>(
                        segments: const [
                          ButtonSegment(
                            value: UserRole.passenger,
                            label: Text('Passageiro'),
                            icon: Icon(Icons.person),
                          ),
                          ButtonSegment(
                            value: UserRole.driver,
                            label: Text('Motorista'),
                            icon: Icon(Icons.directions_car),
                          ),
                          ButtonSegment(
                            value: UserRole.admin,
                            label: Text('Admin'),
                            icon: Icon(Icons.admin_panel_settings),
                          ),
                        ],
                        selected: {_selectedRole},
                        onSelectionChanged: (Set<UserRole> newSelection) {
                          setState(() {
                            _selectedRole = newSelection.first;
                            _showAdminCodeField = isAdmin;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isAdmin 
                            ? '🔐 Requer código de administrador' 
                            : isDriver 
                                ? '🚕 Cadastro de veículo necessário' 
                                : '👤 Cadastro simples e rápido',
                        style: TextStyle(
                          fontSize: 12, 
                          color: isAdmin ? Colors.purple[700] : Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ✅ Dados Pessoais
              const Text(
                '📋 Dados Pessoais',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome Completo *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().length < 3) {
                    return 'Nome deve ter pelo menos 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email é obrigatório';
                  if (!v.contains('@') || !v.contains('.')) return 'Email inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone *',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                  hintText: '+238 XXX XXXX',
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Telefone é obrigatório';
                  final clean = v.replaceAll(RegExp(r'\D'), '');
                  if (clean.length < 8) return 'Telefone inválido (mínimo 8 dígitos)';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // ✅ Código Admin (APENAS ADMIN)
              if (_showAdminCodeField) ...[
                Card(
                  color: Colors.purple[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.admin_panel_settings, color: Colors.purple[700]),
                            const SizedBox(width: 8),
                            const Text(
                              '🔐 Código de Administrador',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _adminCodeController,
                          decoration: InputDecoration(
                            labelText: 'Código Secreto *',
                            prefixIcon: Icon(Icons.lock, color: Colors.purple[700]),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureAdminCode ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscureAdminCode = !_obscureAdminCode),
                            ),
                          ),
                          obscureText: _obscureAdminCode,
                          validator: (v) {
                            if (isAdmin && (v == null || v.isEmpty)) {
                              return 'Código é obrigatório';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '💡 Dica: ADMIN2026CV',
                          style: TextStyle(fontSize: 12, color: Colors.purple[600], fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ✅ Dados do Veículo (APENAS MOTORISTA)
              if (isDriver) ...[
                const Text(
                  '🚗 Dados do Veículo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _vehicleController,
                  decoration: const InputDecoration(
                    labelText: 'Modelo do Veículo *',
                    prefixIcon: Icon(Icons.directions_car),
                    border: OutlineInputBorder(),
                    hintText: 'Ex: Toyota Corolla',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) {
                    if (isDriver && (v == null || v.trim().isEmpty)) {
                      return 'Modelo é obrigatório para motoristas';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _plateController,
                        decoration: const InputDecoration(
                          labelText: 'Placa *',
                          prefixIcon: Icon(Icons.credit_card),
                          border: OutlineInputBorder(),
                          hintText: 'CV-00-00',
                        ),
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z-]')),
                        ],
                        validator: (v) {
                          if (isDriver && (v == null || v.trim().isEmpty)) {
                            return 'Placa é obrigatória';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _colorController,
                        decoration: const InputDecoration(
                          labelText: 'Cor *',
                          prefixIcon: Icon(Icons.color_lens),
                          border: OutlineInputBorder(),
                          hintText: 'Ex: Amarelo',
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) {
                          if (isDriver && (v == null || v.trim().isEmpty)) {
                            return 'Cor é obrigatória';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _yearController,
                  decoration: const InputDecoration(
                    labelText: 'Ano *',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                    hintText: 'Ex: 2020',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (v) {
                    if (isDriver) {
                      if (v == null || v.isEmpty) return 'Ano é obrigatório';
                      final year = int.tryParse(v);
                      if (year == null || year < 1990 || year > DateTime.now().year + 1) {
                        return 'Ano inválido (1990-${DateTime.now().year + 1})';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
              ],

              // ✅ Senha
              const Text(
                '🔐 Segurança',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Senha *',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Senha é obrigatória';
                  if (v.length < 6) return 'Senha deve ter pelo menos 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirmar Senha *',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Confirme sua senha';
                  if (v != _passwordController.text) return 'Senhas não coincidem';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // ✅ Termos de Uso
              CheckboxListTile(
                value: _acceptTerms,
                onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                title: const Text('Aceito os Termos de Uso e Política de Privacidade'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),

              // ✅ Erros
              if (_errors.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _errors.map((error) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700], size: 16),
                          SizedBox(width: 8),
                          Expanded(child: Text(error, style: TextStyle(color: Colors.red[700]))),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ✅ Botão Cadastrar
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAdmin ? Colors.purple[700] : Colors.amber[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          isAdmin ? 'Cadastrar Admin' : 'Cadastrar',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ Link para Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Já tem conta?'),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Fazer Login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}