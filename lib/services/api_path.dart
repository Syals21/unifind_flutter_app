import 'package:flutter/foundation.dart';

class ApiPath {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost/unifind/api';
    }

    // 10.0.2.2 lets the Android emulator reach XAMPP on this computer.
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2/unifind/api';
      default:
        return 'http://localhost/unifind/api';
    }
  }

  static String endpoint(String fileName) {
    return '$baseUrl/$fileName';
  }

  static String reportImage(String fileName) {
    return '${baseUrl.replaceFirst('/api', '')}/uploads/reports/$fileName';
  }
}
