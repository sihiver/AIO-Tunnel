import 'package:flutter/services.dart';
import '../utils/log_manager.dart';

class VPNService {
  static const platform = MethodChannel('com.example.ssh_tunneling/vpn');
  final LogManager _logManager;

  VPNService(this._logManager);

  Future<void> startVPN(String socksAddress, int socksPort) async {
    try {
      final result = await platform.invokeMethod('startVPN', {
        'socksAddress': socksAddress,
        'socksPort': socksPort,
      });
      _logManager.addLog('VPN started: $result');
    } on PlatformException catch (e) {
      _logManager.addLog('Failed to start VPN: ${e.message}');
      throw Exception('Failed to start VPN: ${e.message}');
    }
  }

  Future<void> stopVPN() async {
    try {
      final result = await platform.invokeMethod('stopVPN');
      _logManager.addLog('VPN stopped: $result');
    } on PlatformException catch (e) {
      _logManager.addLog('Failed to stop VPN: ${e.message}');
      throw Exception('Failed to stop VPN: ${e.message}');
    }
  }
}
