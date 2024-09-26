import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'dart:isolate';

import 'pages/home_page.dart';
import 'pages/ssh_page.dart';
import 'pages/settings_page.dart';
import 'modals/payload_page.dart';
import 'modals/sni_page.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeNotifications();

  if (defaultTargetPlatform == TargetPlatform.android) {
    _initializeForegroundTask();
  }

  runApp(const MyApp());
}

Future<void> _initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  const LinuxInitializationSettings initializationSettingsLinux =
      LinuxInitializationSettings(
    defaultActionName: 'Open notification',
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
    macOS: initializationSettingsDarwin,
    linux: initializationSettingsLinux,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

void _initializeForegroundTask() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'ssh_tunneling_channel',
      channelName: 'SSH Tunneling',
      channelDescription: 'Running SSH Tunneling',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
      iconData: const NotificationIconData(
        resType: ResourceType.mipmap,
        resPrefix: ResourcePrefix.ic,
        name: 'launcher',
      ),
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: const ForegroundTaskOptions(
      interval: 60000, // Ubah menjadi 60000 (1 menit)
      isOnceEvent: false,
      autoRunOnBoot: true,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );
}

// Fungsi helper untuk memeriksa apakah foreground service sedang berjalan
Future<bool> isServiceRunning() async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return await FlutterForegroundTask.isRunningService;
  }
  return false;
}

// Fungsi helper untuk memulai foreground service
Future<void> startForegroundService() async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    await FlutterForegroundTask.startService(
      notificationTitle: 'SSH Tunneling',
      notificationText: 'Running in background',
      callback: startCallback,
    );
  }
}

// Fungsi helper untuk menghentikan foreground service
Future<void> stopForegroundService() async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    await FlutterForegroundTask.stopService();
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(SSHTaskHandler());
}

class SSHTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    // Code to execute when the foreground service starts
    debugPrint('SSH Tunneling Foreground Service Started');
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    // This will be called periodically (based on interval defined above)
    debugPrint('SSH Tunneling Foreground Task running at $timestamp');
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    // Cleanup code when the foreground task is destroyed
    debugPrint('SSH Tunneling Foreground Service Destroyed');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Map<String, String>> _getAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return {
      'appName': packageInfo.appName,
      'version': packageInfo.version,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _getAppInfo(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final appName = snapshot.data!['appName']!;
        final appVersion = snapshot.data!['version']!;

        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            ColorScheme lightColorScheme;
            ColorScheme darkColorScheme;

            if (lightDynamic != null && darkDynamic != null) {
              lightColorScheme = lightDynamic;
              darkColorScheme = darkDynamic;
            } else {
              lightColorScheme = ColorScheme.fromSeed(seedColor: Colors.green);
              darkColorScheme = ColorScheme.fromSeed(
                seedColor: Colors.green,
                brightness: Brightness.dark,
              );
            }

            return MaterialApp(
              title: appName,
              theme: ThemeData(
                colorScheme: lightColorScheme,
                useMaterial3: true,
                appBarTheme: AppBarTheme(
                  backgroundColor: lightColorScheme.primary,
                  foregroundColor: lightColorScheme.onPrimary,
                ),
              ),
              darkTheme: ThemeData(
                colorScheme: darkColorScheme,
                useMaterial3: true,
                appBarTheme: AppBarTheme(
                  backgroundColor: Colors.grey[900],  // Warna AppBar untuk mode gelap
                  foregroundColor: Colors.white,
                ),
                scaffoldBackgroundColor: Colors.black,
              ),
              themeMode: ThemeMode.system,
              home: HomePage(
                appName: appName,
                appVersion: appVersion,
              ),
              routes: {
                '/home': (context) =>
                    HomePage(appName: appName, appVersion: appVersion),
                '/ssh': (context) => SSHPage(onConnectionChanged: () {}),
                '/settings': (context) => const SettingsPage(),
                '/payload': (context) => const PayloadModal(),
                '/sni': (context) => const SNIModal(),
              },
            );
          },
        );
      },
    );
  }
}
