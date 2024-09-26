import 'package:dartssh2/dartssh2.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' show parse;
import '../utils/log_manager.dart';
import 'vpn_service.dart';

class SSHService {
  final Logger _logger = Logger();
  final LogManager _logManager;
  final VPNService _vpnService;
  SSHClient? _client;
  String? _banner;
  String? hostkey;
  DateTime? _startTime;
  bool _isVPNActive = false;
  SSHForwardChannel? _forwardChannel;

  SSHService(this._logManager) : _vpnService = VPNService(_logManager);

  Future<void> connect(String address, int port, String username, String password) async {
    _logManager.addLog('Connecting to $address:$port with username $username');
    debugPrint('Connecting to $address:$port with username $username');

    try {
      final socket = await SSHSocket.connect(address, port);
      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
        onUserauthBanner: (banner) {
          _banner = banner;
        },
        onVerifyHostKey: (host, key) {
          hostkey = '$host with key $key';
          return true;
        },
        algorithms: const SSHAlgorithms(
          kex : [SSHKexType.x25519],
          cipher: [
            SSHCipherType.aes128ctr,
            SSHCipherType.aes128cbc,
            SSHCipherType.aes256ctr,
            SSHCipherType.aes256cbc
          ],
          mac: [
            SSHMacType.hmacSha1,
            SSHMacType.hmacSha256,
            SSHMacType.hmacSha512,
            SSHMacType.hmacMd5
          ]
        ),
      );

      _startTime = DateTime.now();

      await _client!.authenticated;
      _logConnectionDetails();

      // Set up port forwarding
      await _setupPortForwarding();

      // Start VPN after SSH connection and port forwarding are established
      await _startVPN();

    } catch (e) {
      _logger.e('Failed to connect: $e');
      _logManager.addLog('Failed to connect: $e');
      rethrow;
    }
  }

  Future<void> _setupPortForwarding() async {
    try {
      _forwardChannel = await _client!.forwardLocal(
        'localhost',
        22,
      );
      _logManager.addLog('Port forwarding set up to localhost:22');
    } catch (e) {
      _logger.e('Failed to set up port forwarding: $e');
      _logManager.addLog('Failed to set up port forwarding: $e');
      throw Exception('Failed to set up port forwarding: $e');
    }
  }

  Future<void> disconnect() async {
    _logManager.addLog('Disconnecting');
    try {
      if (_isVPNActive) {
        await _stopVPN();
      }
      
      if (_forwardChannel != null) {
        _forwardChannel!.close();
        _logManager.addLog('Port forwarding closed');
      }
      
      if (_client != null) {
        _client!.close();
        _logger.i('Disconnection initiated');
        _logManager.addLog('Disconnection initiated');

        // Wait a bit to ensure the connection is fully closed
        await Future.delayed(const Duration(seconds: 2));

        if (_startTime != null) {
          final duration = DateTime.now().difference(_startTime!);
          _logManager.addLog('Connection duration: ${duration.inMinutes} minutes');
        }
      } else {
        _logManager.addLog('No active connection to disconnect');
      }
    } catch (e) {
      _logger.e('Error during disconnection: $e');
      _logManager.addLog('Error during disconnection: $e');
    } finally {
      _forwardChannel = null;
      _client = null;
      _startTime = null;
      _logManager.addLog('Disconnection process completed');
    }
  }

  Future<void> _startVPN() async {
    try {
      await _vpnService.startVPN('127.0.0.1', 1080);
      _isVPNActive = true;
      _logManager.addLog('VPN started successfully');
    } catch (e) {
      _logger.e('Failed to start VPN: $e');
      _logManager.addLog('Failed to start VPN: $e');
      throw Exception('Failed to start VPN: $e');
    }
  }

  Future<void> _stopVPN() async {
    try {
      await _vpnService.stopVPN();
      _isVPNActive = false;
      _logManager.addLog('VPN stopped successfully');
    } catch (e) {
      _logger.e('Failed to stop VPN: $e');
      _logManager.addLog('Failed to stop VPN: $e');
      throw Exception('Failed to stop VPN: $e');
    }
  }

  void _logConnectionDetails() {
    if (_client != null) {
      var remoteVersion = _client!.remoteVersion;
      _logManager.addLog('Remote version: $remoteVersion');
      _logManager.addLog('Using kex algorithms: ${_client!.algorithms.kex.join(', ')}');
      _logManager.addLog('Using cipher algorithms: ${_client!.algorithms.cipher.first}');
      _logManager.addLog('Using MAC algorithms: ${_client!.algorithms.mac.first}');
      _logManager.addLog('Verifying host key for $hostkey');
      if (_banner != null) {
        var document = parse(_banner!);
        var bannerHtml = document.outerHtml;
        _logManager.addLog('Userauth banner: $bannerHtml');
      }
      _logManager.addLog('Connected successfully');
    }
  }
}
