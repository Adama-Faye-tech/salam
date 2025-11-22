import 'package:flutter/foundation.dart';
import 'dart:io';

class ApiConfig {
  // Adresse IP de votre PC sur le réseau local
  static const String _localIpAddress = '192.168.1.23';
  
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Pour appareil Android physique, utilise l'IP locale du PC
      return 'http://$_localIpAddress:3000/api';
    } else if (Platform.isIOS) {
      // Pour appareil iOS physique, utilise l'IP locale du PC
      return 'http://$_localIpAddress:3000/api';
    } else {
      // Pour émulateurs et desktop
      return 'http://localhost:3000/api';
    }
  }

  static String getPhysicalDeviceUrl(String localIpAddress) {
    return 'http://$localIpAddress:3000/api';
  }

  static void printApiUrl() {
    debugPrint('API URL: $baseUrl');
    debugPrint('Platform: ${Platform.operatingSystem}');
  }
}

