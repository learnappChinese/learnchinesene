import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  /// Request permissions needed for speaking practice (microphone and speech recognition)
  static Future<bool> requestSpeakingPermissions() async {
    final micStatus = await Permission.microphone.request();
    final speechStatus = await Permission.speech.request();

    if (micStatus.isPermanentlyDenied || speechStatus.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return micStatus.isGranted && speechStatus.isGranted;
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
