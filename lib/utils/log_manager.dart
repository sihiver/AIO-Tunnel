import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:html/parser.dart' show parse; // Tambahkan impor ini

class LogEntry {
  final DateTime timestamp;
  final String message;

  LogEntry(this.timestamp, this.message);

  String get formattedLog {
    final timeFormat = DateFormat('HH:mm:ss');
    return '[${timeFormat.format(timestamp)}] $message';
  }

  String get formattedLogHtml {
    final timeFormat = DateFormat('HH:mm:ss');
    var document = parse(message);
    var messageHtml = document.outerHtml;
    return '[${timeFormat.format(timestamp)}] $messageHtml';
  }
}

class LogManager extends ChangeNotifier {
  final List<LogEntry> _logs = [];
  final Map<String, DateTime> _lastLogTimes = {};
  final Duration _minLogInterval = const Duration(seconds: 5);  // Tambahkan 'const' di sini

  List<LogEntry> get logs => List.unmodifiable(_logs);

  void addLog(String message) {
    final now = DateTime.now();
    if (_canAddLog(message, now)) {
      _logs.add(LogEntry(now, message));
      _lastLogTimes[message] = now;
      notifyListeners();
      debugPrint('Log added: $message'); // Tambahkan log untuk debugging
    } else {
      debugPrint('Log skipped (interval too short): $message'); // Tambahkan log untuk debugging
    }
  }

  void addLogHtml(String message) {
    final now = DateTime.now();
    if (_canAddLog(message, now)) {
      var document = parse(message);
      var messageHtml = document.outerHtml;
      _logs.add(LogEntry(now, messageHtml));
      _lastLogTimes[messageHtml] = now;
      notifyListeners();
      debugPrint('Log added: $messageHtml'); // Tambahkan log untuk debugging
    } else {
      debugPrint('Log skipped (interval too short): $message'); // Tambahkan log untuk debugging
    }
  }

  bool _canAddLog(String message, DateTime now) {
    if (!_lastLogTimes.containsKey(message)) {
      return true;
    }
    return now.difference(_lastLogTimes[message]!) > _minLogInterval;
  }

  void clearLogs() {
    _logs.clear();
    _lastLogTimes.clear();
    notifyListeners();
  }
}
