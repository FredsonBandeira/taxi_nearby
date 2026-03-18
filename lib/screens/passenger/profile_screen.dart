// lib/screens/passenger/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_mock_service.dart';
import '../../models/user.dart';
import './ride_history_screen.dart';

class PassengerProfileScreen extends StatefulWidget {
  const PassengerProfileScreen({super.key});

  @override
  State<PassengerProfileScreen> createState() => _PassengerProfileScreenState();
}

class _PassengerProfileScreenState extends State<PassengerProfileScreen> {
  final AuthService _authService = AuthService();
  UserModel? _user;
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    setState(() {
      _user = _authService.currentUser;
      _nameController = TextEditingController(text: _user?.name);
      _emailController = TextEditingController(text: _user?.email);
      _phoneController = TextEditingController(text: _user?.phone);
      _addressController = TextEditingController(text: _user?.address);
      _cityController = TextEditingController(text: _user?.city);
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _user == null) return;
    
    final updatedUser = _user!.copyWith(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
    );
    
    await _authService.updateProfile(updatedUser);
    setState(() {
      _user = updatedUser;
      _isEditing = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Perfil atualizado com sucesso!')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Perfil' : 'Meu Perfil'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _loadUser();
                setState(() => _isEditing = false);
              },
            ),
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: _saveProfile,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.amber[100],
                      child: Icon(Icons.person, size: 50, color: Colors.amber[800]),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.amber[700],
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                            onPressed: () {},
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Campos do Formulário
              _buildTextField(_nameController, 'Nome completo', Icons.person, enabled: _isEditing),
              const SizedBox(height: 12),
              _buildTextField(_emailController, 'Email', Icons.email, 
                enabled: _isEditing, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _buildTextField(_phoneController, 'Telefone', Icons.phone, 
                enabled: _isEditing, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildTextField(_addressController, 'Endereço', Icons.home, enabled: _isEditing),
              const SizedBox(height: 12),
              _buildTextField(_cityController, 'Cidade', Icons.location_city, enabled: _isEditing),
              
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // Menu de Ações
              ListTile(
                leading: Icon(Icons.history, color: Colors.blue[700]),
                title: const Text('Histórico de Corridas'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/passenger/rides'),
              ),
              ListTile(
                leading: Icon(Icons.payment, color: Colors.green[700]),
                title: const Text('Métodos de Pagamento'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Em desenvolvimento')),
                ),
              ),
              ListTile(
                leading: Icon(Icons.settings, color: Colors.grey[700]),
                title: const Text('Configurações'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings'),
              ),
              ListTile(
                leading: Icon(Icons.help_outline, color: Colors.purple[700]),
                title: const Text('Ajuda e Suporte'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              
              const SizedBox(height: 24),
              
              // Botão Sair
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await _authService.logout();
                    if (mounted) {
                      context.go('/login');
                    }
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
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: enabled ? Colors.amber[700] : Colors.grey),
        border: const OutlineInputBorder(),
        filled: !enabled,
        fillColor: Colors.grey[100],
      ),
      validator: (v) {
        if (label == 'Nome completo' && (v?.isEmpty ?? true)) return 'Campo obrigatório';
        if (label == 'Email' && (v?.isEmpty ?? true)) return 'Campo obrigatório';
        return null;
      },
    );
  }
}