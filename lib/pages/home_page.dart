import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import '../utils/log_manager.dart';
import '../utils/device_info_manager.dart';
import '../widgets/sidebar.dart';
import '../widgets/connection_settings.dart';
import '../widgets/start_stop_button.dart' as custom_widget;
import '../widgets/log_widget.dart';
import '../services/ssh_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../widgets/custom_tab_bar.dart';
import '../main.dart'; // Pastikan untuk mengimpor file main.dart

class HomePage extends StatefulWidget {
  final String appName;
  final String appVersion;
  final Widget? showModal;

  const HomePage({
    super.key,
    required this.appName,
    required this.appVersion,
    this.showModal,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;
  List<Map<String, String>> _connections = [];
  String? _selectedServer;
  bool _usePayload = false;
  bool _useSSL = false;
  bool _useSlowDNS = false;
  bool _useXray = false;
  bool _isLoadingConnections = true;
  final LogManager _logManager = LogManager();
  late DeviceInfoManager _deviceInfoManager;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  late SSHService _sshService;
  custom_widget.ConnectionState _connectionState = custom_widget.ConnectionState.stopped;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _deviceInfoManager = DeviceInfoManager(_logManager);
    _sshService = SSHService(_logManager);
    _initializeApp();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
    _loadSettings();
    _loadConnections();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showModalIfNeeded();
    });
  }

  Future<void> _initializeApp() async {
    _logManager.addLog('Aplikasi dimulai: ${widget.appName} v${widget.appVersion}');
    await _deviceInfoManager.initializeDeviceInfo();
    await _deviceInfoManager.checkConnectivity();
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    _deviceInfoManager.checkConnectivity(result);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _showModalIfNeeded() {
    if (widget.showModal != null && mounted) {
      Future.microtask(() {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) => widget.showModal!,
          );
        }
      });
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _selectedServer = prefs.getString('selectedServer');
        _usePayload = prefs.getBool('usePayload') ?? false;
        _useSSL = prefs.getBool('useSSL') ?? false;
        _useSlowDNS = prefs.getBool('useSlowDNS') ?? false;
        _useXray = prefs.getBool('useXray') ?? false;
      });
      _logManager.addLog('Loaded settings: selectedServer=$_selectedServer');
    }
  }

  Future<void> _loadConnections() async {
    final prefs = await SharedPreferences.getInstance();
    final String? connectionsString = prefs.getString('connections');
    if (mounted) {
      setState(() {
        if (connectionsString != null) {
          _connections = List<Map<String, String>>.from(
            json.decode(connectionsString).map(
              (item) => Map<String, String>.from(item),
            ),
          );
        }
        _isLoadingConnections = false;
      });
      _logManager.addLog('Loaded connections: $_connections');
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('selectedServer', _selectedServer ?? '');
    prefs.setBool('usePayload', _usePayload);
    prefs.setBool('useSSL', _useSSL);
    prefs.setBool('useSlowDNS', _useSlowDNS);
    prefs.setBool('useXray', _useXray);
  }

  Future<void> _toggleConnection() async {
    _logManager.addLog('Toggling connection. Current state: $_connectionState');
    try {
      if (_connectionState == custom_widget.ConnectionState.connected) {
        await _stopSSHService();
      } else {
        await _startSSHService();
      }
    } catch (e) {
      _logManager.addLog('Error toggling connection: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      // Pastikan state diupdate meskipun terjadi error
      setState(() {
        _connectionState = custom_widget.ConnectionState.stopped;
      });
    }
  }

  Future<void> _startSSHService() async {
    _logManager.addLog('Starting SSH service');
    setState(() {
      _connectionState = custom_widget.ConnectionState.connecting;
    });

    try {
      _logManager.addLog('Attempting to connect to $_selectedServer');
      _logManager.addLog('Available connections: $_connections');

      final serverParts = _selectedServer?.split(':');
      final serverAddress = serverParts?[0];

      final selectedConnection = _connections.firstWhere(
        (connection) => connection['address'] == serverAddress,
        orElse: () => throw Exception('No connection found for the selected server'),
      );
      _logManager.addLog('Selected connection: $selectedConnection');

      if (defaultTargetPlatform == TargetPlatform.android) {
        await startForegroundService();
      }

      await _sshService.connect(
        selectedConnection['address']!,
        int.parse(selectedConnection['port']!),
        selectedConnection['username']!,
        selectedConnection['password']!,
      );

      setState(() {
        _connectionState = custom_widget.ConnectionState.connected;
      });

      _logManager.addLog('Connected to ${selectedConnection['address']}:${selectedConnection['port']}');
      
      // Update notification
      await _showNotification('SSH Tunneling Active', 'Connected to ${selectedConnection['address']}:${selectedConnection['port']}');
    } catch (e) {
      setState(() {
        _connectionState = custom_widget.ConnectionState.stopped;
      });
      _logManager.addLog('Failed to connect: $e');
      if (defaultTargetPlatform == TargetPlatform.android) {
        await stopForegroundService();
      }
      // Show error notification
      await _showNotification('Connection Failed', 'Failed to connect: $e');
      rethrow; // Melempar kembali error untuk ditangani di _toggleConnection
    }
  }

  Future<void> _stopSSHService() async {
    _logManager.addLog('Stopping SSH service');
    try {
      await _sshService.disconnect();
      
      if (defaultTargetPlatform == TargetPlatform.android) {
        await stopForegroundService();
      }
      
      setState(() {
        _connectionState = custom_widget.ConnectionState.stopped;
      });
      
      _logManager.addLog('Disconnected successfully');
      await _showNotification('SSH Tunneling Stopped', 'Connection has been terminated');
    } catch (e) {
      _logManager.addLog('Error stopping SSH service: $e');
      // Even if there's an error, we should still update the state
      setState(() {
        _connectionState = custom_widget.ConnectionState.stopped;
      });
      await _showNotification('Error', 'Failed to stop SSH service: $e');
      rethrow; // Melempar kembali error untuk ditangani di _toggleConnection
    }
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'ssh_tunneling_channel',
      'SSH Tunneling',
      channelDescription: 'Notifications for SSH Tunneling',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await FlutterLocalNotificationsPlugin().show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.grey[900] : colorScheme.primary,
        foregroundColor: Colors.white,
        title: Text(widget.appName),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: CustomTabBar(
            controller: _tabController,
            tabs: const ['SSH', 'Log'],
            connectionState: _connectionState,  // Tambahkan ini
          ),
        ),
      ),
      drawer: Sidebar(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        appName: widget.appName,
        appVersion: widget.appVersion,
      ),
      body: Container(
        color: isDarkMode ? Colors.black : colorScheme.surface,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildSSHTab(),
            LogWidget(logManager: _logManager),
          ],
        ),
      ),
    );
  }

  Widget _buildSSHTab() {
    
    return _isLoadingConnections
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConnectionSettings(
                    selectedServer: _selectedServer,
                    connections: _connections,
                    usePayload: _usePayload,
                    useSSL: _useSSL,
                    useSlowDNS: _useSlowDNS,
                    useXray: _useXray,
                    onServerChanged: (String? newValue) {
                      setState(() {
                        _selectedServer = newValue;
                      });
                      _saveSettings();
                    },
                    onPayloadChanged: (bool? value) {
                      setState(() {
                        _usePayload = value ?? false;
                      });
                      _saveSettings();
                    },
                    onSSLChanged: (bool? value) {
                      setState(() {
                        _useSSL = value ?? false;
                      });
                      _saveSettings();
                    },
                    onSlowDNSChanged: (bool? value) {
                      setState(() {
                        _useSlowDNS = value ?? false;
                      });
                      _saveSettings();
                    },
                    onXrayChanged: (bool? value) {
                      setState(() {
                        _useXray = value ?? false;
                      });
                      _saveSettings();
                    },
                  ),
                  const SizedBox(height: 16),
                  custom_widget.StartStopButton(
                    connectionState: _connectionState,
                    onPressed: _toggleConnection,
                  ),
                ],
              ),
            ),
          );
  }
}
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(SSHTaskHandler());
}

class SSHTaskHandler extends TaskHandler {
  int _lastUpdateMinute = -1;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    // Tidak perlu memperbarui notifikasi di sini karena sudah diatur saat memulai layanan
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    final prefs = await SharedPreferences.getInstance();
    final updateNotifications = prefs.getBool('updateNotifications') ?? true;

    if (updateNotifications && timestamp.minute != _lastUpdateMinute) {
      _lastUpdateMinute = timestamp.minute;
      await FlutterForegroundTask.updateService(
        notificationText: 'SSH Tunneling active. Last update: ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
      );
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    // Bersihkan resources jika diperlukan
  }
}
