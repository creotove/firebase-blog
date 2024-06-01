import 'package:permission_handler/permission_handler.dart';

class PermsHandler {
  Future<bool> microphone() async {
    final statuses = await [
      Permission.microphone,
    ].request();

    return statuses[Permission.microphone]!.isGranted;
  }
}
