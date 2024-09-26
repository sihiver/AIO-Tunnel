import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'dart:io';

import 'log_manager.dart';

class DeviceInfoManager {
  final LogManager _logManager;
  String _lastConnectionType = '';
  String _lastIpAddress = '';

  DeviceInfoManager(this._logManager);

  Future<void> initializeDeviceInfo() async {
    await detectDevice();
    await detectAndroidVersion();
  }

  Future<void> detectDevice() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        String manufacturer = androidInfo.manufacturer;
        String model = androidInfo.model;
        _logManager.addLog('Perangkat: $manufacturer $model');
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        String name = iosInfo.name.isNotEmpty ? iosInfo.name : 'Unknown';
        String model = iosInfo.model.isNotEmpty ? iosInfo.model : 'Unknown';
        _logManager.addLog('Perangkat: $name $model');
      }
    } catch (e) {
      _logManager.addLog('Gagal mendeteksi perangkat: $e');
    }
  }

  Future<void> detectAndroidVersion() async {
    if (!Platform.isAndroid) return;

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      String release = androidInfo.version.release;
      String sdkInt = androidInfo.version.sdkInt.toString();
      _logManager.addLog('Versi Android: $release (SDK $sdkInt)');
    } catch (e) {
      _logManager.addLog('Gagal mendeteksi versi Android: $e');
    }
  }

  Future<void> checkConnectivity([ConnectivityResult? result]) async {
    try {
      result ??= await Connectivity().checkConnectivity();
      String connectionType = _getConnectionType(result);
      
      if (connectionType != _lastConnectionType) {
        _logManager.addLog('Jenis koneksi: $connectionType');
        _lastConnectionType = connectionType;
      }

      String? ip = await _detectLocalIP(result);
      String ipAddress = ip ?? "Tidak diketahui";
      
      if (ipAddress != _lastIpAddress) {
        _logManager.addLog('IP Lokal: $ipAddress');
        _lastIpAddress = ipAddress;
      }
    } catch (e) {
      _logManager.addLog('Gagal memeriksa konektivitas: $e');
    }
  }

  String _getConnectionType(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Seluler';
      case ConnectivityResult.none:
        return 'Tidak ada koneksi';
      default:
        return 'Tidak diketahui';
    }
  }

  Future<String?> _detectLocalIP(ConnectivityResult connectivityResult) async {
    try {
      if (connectivityResult == ConnectivityResult.wifi) {
        final info = NetworkInfo();
        return await info.getWifiIP();
      } else if (connectivityResult == ConnectivityResult.mobile) {
        final interfaces = await NetworkInterface.list(
          includeLoopback: false,
          type: InternetAddressType.IPv4,
        );
        for (var interface in interfaces) {
          if (interface.name == "rmnet0" || 
              interface.name.startsWith("pdp") ||
              interface.name.startsWith("wwan") ||
              interface.name.startsWith("ccmni")) {
            return interface.addresses.first.address;
          }
        }
        // Jika tidak menemukan interface spesifik, ambil IP dari interface pertama yang bukan loopback
        for (var interface in interfaces) {
          if (interface.addresses.isNotEmpty && !interface.addresses.first.isLoopback) {
            return interface.addresses.first.address;
          }
        }
      }
    } catch (e) {
      _logManager.addLog('Error dalam mendeteksi IP lokal: $e');
    }
    return null;
  }
}
