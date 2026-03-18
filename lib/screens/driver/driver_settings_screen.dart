// lib/screens/driver/driver_settings_screen.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/driver_notification_service.dart';
import '../../services/voice_service.dart';
import 'package:go_router/go_router.dart';

class DriverSettingsScreen extends StatefulWidget {
  const DriverSettingsScreen({super.key});

  @override
  State<DriverSettingsScreen> createState() => _DriverSettingsScreenState();
}

class _DriverSettingsScreenState extends State<DriverSettingsScreen> {
  final AuthService _authService = AuthService();
  final DriverNotificationService _notificationService = DriverNotificationService();
  final VoiceService _voiceService = VoiceService();
  
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _voiceEnabled = true;
  bool _autoAcceptEnabled = false;
  String _maxDistance = '10';
  String _minFare = '50';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _soundEnabled = _notificationService.soundEnabled;
      _vibrationEnabled = _notificationService.vibrationEnabled;
      _voiceEnabled = _voiceService.isAvailable;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // === NOTIFICAÇÕES ===
          const Text('🔔 NOTIFICAÇÕES', 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Som de Notificação'),
                  subtitle: const Text('Tocar som quando chegar corrida'),
                  value: _soundEnabled,
                  onChanged: (v) {
                    setState(() => _soundEnabled = v);
                    _notificationService.setSoundEnabled(v);
                  },
                ),
                SwitchListTile(
                  title: const Text('Vibração'),
                  subtitle: const Text('Vibrar quando chegar corrida'),
                  value: _vibrationEnabled,
                  onChanged: (v) {
                    setState(() => _vibrationEnabled = v);
                    _notificationService.setVibrationEnabled(v);
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // === COMANDO DE VOZ ===
          const Text('🎤 COMANDO DE VOZ', 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Ativar Comando de Voz'),
                  subtitle: const Text('Diga "Aceito" ou "Não aceito"'),
                  value: _voiceEnabled,
                  onChanged: (v) async {
                    if (v) {
                      final available = await _voiceService.initialize();
                      if (!available && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reconhecimento de voz não disponível')),
                        );
                      }
                    }
                    setState(() => _voiceEnabled = v && _voiceService.isAvailable);
                    _notificationService.setVoiceEnabled(v);
                  },
                ),
                ListTile(
                  title: const Text('Testar Comando de Voz'),
                  subtitle: const Text('Diga "Aceito" para testar'),
                  leading: const Icon(Icons.mic),
                  onTap: () {
                    _voiceService.startListening(listenFor: const Duration(seconds: 5));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('🎤 Ouvindo... Diga "Aceito"')),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // === FILTROS DE CORRIDA ===
          const Text('🎯 FILTROS DE CORRIDA', 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Aceitação Automática'),
                  subtitle: const Text('Aceitar corridas automaticamente'),
                  value: _autoAcceptEnabled,
                  onChanged: (v) {
                    setState(() => _autoAcceptEnabled = v);
                  },
                ),
                ListTile(
                  title: const Text('Distância Máxima (km)'),
                  subtitle: Text('$_maxDistance km'),
                  trailing: Slider(
                    value: double.parse(_maxDistance),
                    min: 1,
                    max: 50,
                    divisions: 49,
                    onChanged: (v) => setState(() => _maxDistance = v.round().toString()),
                  ),
                ),
                ListTile(
                  title: const Text('Valor Mínimo (CV\$)'),
                  subtitle: Text('CV\$ $_minFare'),
                  trailing: Slider(
                    value: double.parse(_minFare),
                    min: 10,
                    max: 500,
                    divisions: 49,
                    onChanged: (v) => setState(() => _minFare = v.round().toString()),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // === SOBRE ===
          const Text('ℹ️ SOBRE', 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Versão do App'),
                  subtitle: const Text('1.0.0 (MVP)'),
                  trailing: const Icon(Icons.info_outline),
                ),
                ListTile(
                  title: const Text('Termos de Uso'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                ListTile(
                  title: const Text('Política de Privacidade'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                ListTile(
                  title: const Text('Ajuda e Suporte'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
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
    );
  }
}