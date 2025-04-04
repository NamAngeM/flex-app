// lib/services/logger_service.dart
class Logger {
  void info(String message) {
    print('[INFO] $message');
  }

  void error(String message) {
    print('[ERROR] $message');
  }

  void warning(String message) {
    print('[WARNING] $message');
  }

  void debug(String message) {
    print('[DEBUG] $message');
  }
}