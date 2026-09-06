import 'package:pp_bluetooth_kit_flutter/channel/pp_bluetooth_kit_flutter_platform_interface.dart';
import 'package:pp_bluetooth_kit_flutter/enums/pp_scale_enums.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_180a_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_user.dart';

class PPPeripheralFish {
  static final _peripheralType = PPDevicePeripheralType.fish.value;

  /// 同步时间
  /// 返回值：true:成功
  static Future<bool?> syncTime() async {
    return PPBluetoothKitFlutterPlatform.instance.syncTime(_peripheralType);
  }

  /// 同步单位
  /// unitType 单位，必传
  static Future<bool?> syncUnit(PPUnitType unitType) async {
    final deviceUser = PPDeviceUser(
        userHeight: 175, age: 20, sex: PPUserGender.female, unitType: unitType);
    return PPBluetoothKitFlutterPlatform.instance
        .syncUnit(_peripheralType, deviceUser);
  }

  /// 获取设备信息
  static Future<PPDevice180AModel?> fetchDeviceInfo() async {
    return PPBluetoothKitFlutterPlatform.instance
        .fetchDeviceInfo(_peripheralType);
  }

  /// 去皮/清零
  static Future<bool> toZero() async {
    return PPBluetoothKitFlutterPlatform.instance.toZero(_peripheralType);
  }

  /// 获取设备电量
  /// continuity true:返回实时电量，false:只返回一次电量
  static void fetchBatteryInfo(
      {required bool continuity,
      required Function(int power, int? lumen) callBack}) {
    PPBluetoothKitFlutterPlatform.instance.fetchBatteryInfo(_peripheralType,
        continuity: continuity, callBack: callBack);
  }

  /// 去皮/清零
  static Future<bool> changeBuzzerGate(bool isOpen) async {
    return PPBluetoothKitFlutterPlatform.instance.changeBuzzerGate(isOpen);
  }
}
