// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  String _language = 'pt';
  String _currency = 'CVE';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _locationEnabled = prefs.getBool('location') ?? true;
      _language = prefs.getString('language') ?? 'pt';
      _currency = prefs.getString('currency') ?? 'CVE';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        children: [
          const ListTile(title: Text('PREFERÊNCIAS'), style: ListTileStyle.drawer),
          SwitchListTile(
            title: const Text('Notificações Push'),
            subtitle: const Text('Receber alertas de corridas'),
            value: _notificationsEnabled,
            onChanged: (v) {
              setState(() => _notificationsEnabled = v);
              _saveSetting('notifications', v);
            },
          ),
          SwitchListTile(
            title: const Text('Localização em Tempo Real'),
            subtitle: const Text('Compartilhar localização com motoristas'),
            value: _locationEnabled,
            onChanged: (v) {
              setState(() => _locationEnabled = v);
              _saveSetting('location', v);
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Idioma'),
            subtitle: Text({'pt': 'Português', 'en': 'English', 'fr': 'Français'}[_language]!),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageSelector(),
          ),
          ListTile(
            title: const Text('Moeda'),
            subtitle: Text(_currency),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showCurrencySelector(),
          ),
          const Divider(),
          const ListTile(title: Text('SOBRE'), style: ListTileStyle.drawer),
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
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Taxi Nearby © 2026\nCabo Verde',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Selecionar Idioma', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...['pt', 'en', 'fr'].map((lang) => ListTile(
            title: Text({'pt': 'Português', 'en': 'English', 'fr': 'Français'}[lang]!),
            trailing: _language == lang ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () {
              setState(() => _language = lang);
              _saveSetting('language', lang);
              Navigator.pop(context);
            },
          )),
        ],
      ),
    );
  }

  void _showCurrencySelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Selecionar Moeda', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...['CVE', 'USD', 'EUR'].map((curr) => ListTile(
            title: Text(curr),
            trailing: _currency == curr ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () {
              setState(() => _currency = curr);
              _saveSetting('currency', curr);
              Navigator.pop(context);
            },
          )),
        ],
      ),
    );
  }
}