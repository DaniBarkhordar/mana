

import 'package:pp_bluetooth_kit_flutter/utils/pp_bluetooth_kit_logger.dart';

import 'channel/pp_bluetooth_kit_flutter_platform_interface.dart';

class PPBluetoothKitFlutter {

  static Future<String?> getPlatformVersion() {
    return PPBluetoothKitFlutterPlatform.instance.getPlatformVersion();
  }


}
