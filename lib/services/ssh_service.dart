import 'package:dartssh2/dartssh2.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import '../utils/log_manager.dart';
import 'vpn_service.dart';
import 'dart:io';
import 'dart:async';

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
  ServerSocket? _socksServer;
  Timer? _keepAliveTimer;

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
        printDebug:(p0) {
          _logManager.addLog('Debug: $p0');
        },
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

      // Set up keep-alive mechanism
      _setupKeepAlive();

      // Set up port forwarding
      await _setupPortForwarding();

      // Start VPN after SSH connection and port forwarding are established
      await _startVPN();

    } catch (e) {
      _logger.e('Failed to connect: $e');
      _logManager.addLog('Failed to connect: $e');
      await disconnect();
      rethrow;
    }
  }

  void _setupKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_client != null) {
        try {
          // Ganti sendIgnore dengan operasi lain yang dapat menjaga koneksi tetap hidup
          _client!.ping();
        } catch (e) {
          _logger.e('Error during keep-alive: $e');
          _logManager.addLog('Error during keep-alive: $e');
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _setupPortForwarding() async {
    try {
      // Gunakan port tetap untuk forwarding lokal
      const int localForwardPort = 22;
      _forwardChannel = await _client!.forwardLocal(
        'localhost',
        localForwardPort,
      );
      
      _logManager.addLog('Local port forwarding set up on localhost:$localForwardPort to remote port 22');

      // Buat SOCKS5 proxy server
      const int socksPort = 1080;
      _socksServer = await ServerSocket.bind(InternetAddress.loopbackIPv4, socksPort);
      _socksServer!.listen((socket) {
        _handleSocksConnection(socket, localForwardPort);
      });
      
      _logManager.addLog('SOCKS5 proxy started on localhost:$socksPort');
    } catch (e) {
      _logger.e('Failed to set up port forwarding and SOCKS proxy: $e');
      _logManager.addLog('Failed to set up port forwarding and SOCKS proxy: $e');
      await disconnect();
      throw Exception('Failed to set up port forwarding and SOCKS proxy: $e');
    }
  }

  void _handleSocksConnection(Socket clientSocket, int forwardPort) async {
    try {
      // SOCKS5 handshake
      var data = await clientSocket.first;
      if (data[0] != 0x05) {
        clientSocket.close();
        return;
      }

      // Send authentication method (no authentication)
      clientSocket.add([0x05, 0x00]);

      // Read connection request
      data = await clientSocket.first;
      if (data[0] != 0x05 || data[1] != 0x01 || data[3] != 0x01) {
        clientSocket.close();
        return;
      }

      // Connect to the local forwarded port
      var forwardSocket = await Socket.connect('localhost', forwardPort);

      // Send connection response
      clientSocket.add(Uint8List.fromList([0x05, 0x00, 0x00, 0x01, 0, 0, 0, 0, 0, 0]));

      // Start forwarding data
      clientSocket.addStream(forwardSocket);
      forwardSocket.addStream(clientSocket);
    } catch (e) {
      debugPrint('Error in SOCKS connection: $e');
      _logManager.addLog('Error in SOCKS connection: $e');
      clientSocket.close();
    }
  }

  Future<void> disconnect() async {
    _logManager.addLog('Disconnecting');
    try {
      _keepAliveTimer?.cancel();
      
      if (_isVPNActive) {
        await _stopVPN();
      }
      
      if (_forwardChannel != null) {
        await _forwardChannel!.close();
        _logManager.addLog('Port forwarding closed');
      }
      
      if (_socksServer != null) {
        await _socksServer!.close();
        _logManager.addLog('SOCKS5 proxy stopped');
      }
      
      if (_client != null) {
        _client!.close(); // Hapus await di sini
        _logger.i('Disconnection initiated');
        _logManager.addLog('Disconnection initiated');

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
      // Memeriksa dan meminta izin VPN terlebih dahulu
      if (await _vpnService.requestVPNPermission()) {
        // Menggunakan SOCKS5 proxy yang telah di-setup
        await _vpnService.setupAndStartVPN('127.0.0.1', 1080);
        _isVPNActive = true;
        _logManager.addLog('VPN started successfully using SOCKS5 proxy');
      } else {
        throw Exception('VPN permission not granted');
      }
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
        // Jika Anda tidak memerlukan parsing HTML, Anda bisa langsung menggunakan _banner
        _logManager.addLog('Userauth banner: $_banner');
      }
      _logManager.addLog('Connected successfully');
    }
  }
}
