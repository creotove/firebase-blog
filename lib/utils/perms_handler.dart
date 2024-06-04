import 'package:permission_handler/permission_handler.dart';

class PermsHandler {
  Future<bool> microphone() async {
    final statuses = await [
      Permission.microphone,
    ].request();

    return statuses[Permission.microphone]!.isGranted;
  }

  Future<bool> camera() async {
    final statuses = await [
      Permission.camera,
    ].request();
    return statuses[Permission.camera]!.isGranted;
  }
}
