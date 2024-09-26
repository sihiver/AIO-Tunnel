import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;
  bool _notifications = true;
  String _language = 'English';
  bool _updateNotifications = true;

  static const String _appName = 'SSH Tunneling';
  static const String _appVersion = '1.0.0';
  static const String _appLegalese = '© 2023 Your Company';
  static const Image _appIcon = Image(  // Tambahkan 'const' di sini
    image: AssetImage('assets/logo.png'),
    width: 48,
    height: 48,
  );

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
      _notifications = prefs.getBool('notifications') ?? true;
      _language = prefs.getString('language') ?? 'English';
      _updateNotifications = prefs.getBool('updateNotifications') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
    await prefs.setBool('notifications', _notifications);
    await prefs.setString('language', _language);
    await prefs.setBool('updateNotifications', _updateNotifications);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
        )
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Mode Gelap'),
            value: _darkMode,
            onChanged: (bool value) {
              setState(() {
                _darkMode = value;
              });
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Notifikasi'),
            value: _notifications,
            onChanged: (bool value) {
              setState(() {
                _notifications = value;
              });
              _saveSettings();
            },
          ),
          ListTile(
            title: const Text('Bahasa'),
            trailing: DropdownButton<String>(
              value: _language,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _language = newValue;
                  });
                  _saveSettings();
                }
              },
              items: <String>['English', 'Indonesia', 'Español']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          const ListTile(
            title: const Text('Versi Aplikasi'),
            trailing: Text(_appVersion),
          ),
          ListTile(
            title: const Text('Tentang'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: _appName,
                applicationVersion: _appVersion,
                applicationIcon: _appIcon,
                applicationLegalese: _appLegalese,
              );
            },
          ),
          SwitchListTile(
            title: const Text('Update Notifications'),
            subtitle: const Text('Periodically update the SSH tunneling notification'),
            value: _updateNotifications,
            onChanged: (bool value) {
              setState(() {
                _updateNotifications = value;
              });
              _saveSettings();
            },
          ),
        ],
      ),
    );
  }
}