import 'package:flutter/services.dart';
import '../utils/log_manager.dart';

class VPNService {
  static const platform = MethodChannel('flutter_v2ray');
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
      // Tidak melempar exception di sini untuk memastikan proses pembersihan tetap berlanjut
    }
  }

  Future<void> initializeV2Ray() async {
    try {
      await platform.invokeMethod('initializeV2Ray');
      _logManager.addLog('V2Ray initialized');
    } on PlatformException catch (e) {
      _logManager.addLog('Failed to initialize V2Ray: ${e.message}');
      throw Exception('Failed to initialize V2Ray: ${e.message}');
    }
  }

  Future<void> setupAndStartVPN(String socksAddress, int socksPort) async {
    try {
      await initializeV2Ray();
      await startVPN(socksAddress, socksPort);
    } catch (e) {
      _logManager.addLog('Failed to setup and start VPN: $e');
      throw Exception('Failed to setup and start VPN: $e');
    }
  }

  Future<bool> requestVPNPermission() async {
    try {
      final bool hasPermission = await platform.invokeMethod('requestPermission');
      return hasPermission;
    } on PlatformException catch (e) {
      _logManager.addLog('Failed to request VPN permission: ${e.message}');
      return false;
    }
  }
}
