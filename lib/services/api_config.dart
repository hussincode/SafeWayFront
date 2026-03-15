import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Base URL for backend API.
///
/// - Android emulator: use 10.0.2.2
/// - iOS simulator / desktop / web: use localhost
/// - Real devices: set this to your machine's LAN IP (e.g. 192.168.x.x) via
///   a dart-define or by editing this file.
String get apiBaseUrl {
  if (kIsWeb) return 'http://localhost:5143';
  if (Platform.isAndroid) return 'http://192.168.100.46:5143';  // For real Android device on same network
  return 'http://localhost:5143';
}
