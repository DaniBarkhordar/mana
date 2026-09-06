import 'package:pp_bluetooth_kit_flutter/channel/pp_bluetooth_kit_flutter_platform_interface.dart';
import 'package:pp_bluetooth_kit_flutter/enums/pp_scale_enums.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_180a_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_user.dart';

class PPPeripheralDurian {
  static final _peripheralType = PPDevicePeripheralType.durian.value;

  /// 同步用户信息
  /// deviceUser 用户信息
  /// unitType 单位，必传
  /// userHeight 身高，必传
  /// age 年龄，必传
  /// sex 性别，必传
  /// isAthleteMode 运动员模式，可以不传
  /// isPregnantMode 孕妇模式，可以不传
  static Future<bool?> syncUserInfo(PPDeviceUser deviceUser) async {
    return PPBluetoothKitFlutterPlatform.instance
        .syncUnit(_peripheralType, deviceUser);
  }

  /// 获取设备信息
  static Future<PPDevice180AModel?> fetchDeviceInfo() async {
    return PPBluetoothKitFlutterPlatform.instance
        .fetchDeviceInfo(_peripheralType);
  }

  /// 获取设备电量
  /// continuity true:返回实时电量，false:只返回一次电量
  static void fetchBatteryInfo(
      {required bool continuity,
      required Function(int power, int? lumen) callBack}) {
    PPBluetoothKitFlutterPlatform.instance.fetchBatteryInfo(_peripheralType,
        continuity: continuity, callBack: callBack);
  }
}
