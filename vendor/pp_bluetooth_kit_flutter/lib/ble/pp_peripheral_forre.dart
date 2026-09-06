import 'package:pp_bluetooth_kit_flutter/channel/pp_bluetooth_kit_flutter_platform_interface.dart';
import 'package:pp_bluetooth_kit_flutter/enums/pp_scale_enums.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_body_base_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_180a_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_user.dart';

class PPPeripheralForre {
  static final _peripheralType = PPDevicePeripheralType.forre.value;

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

  /// 获取设备电量
  /// continuity true:返回实时电量，false:只返回一次电量
  static void fetchBatteryInfo(
      {required bool continuity,
      required Function(int power, int? lumen) callBack}) {
    PPBluetoothKitFlutterPlatform.instance.fetchBatteryInfo(_peripheralType,
        continuity: continuity, callBack: callBack);
  }

  /// 阻抗控制开关
  /// open： true-开，false-关
  static Future<bool> impedanceSwitchControl(bool open) async {
    return PPBluetoothKitFlutterPlatform.instance
        .impedanceSwitchControl(_peripheralType, open);
  }

  /// 获取阻抗开关状态
  /// 返回： true-开，false-关
  static Future<bool> fetchImpedanceSwitch() async {
    return PPBluetoothKitFlutterPlatform.instance
        .fetchImpedanceSwitch(_peripheralType);
  }

  /// 保活指令
  static void keepAlive() async {
    PPBluetoothKitFlutterPlatform.instance.keepAlive(_peripheralType);
  }

  /// 蓝牙DFU升级
  /// [filePath] 固件zip包完整路径
  /// [deviceFirmwareVersion] 设备当前版本号，可以通过 fetchDeviceInfo 方法获取 “firmwareRevision”
  /// [isForceCompleteUpdate] 是否强制全量升级，true：每个包都升级，false:增量升级，根据版本号判定升级哪个包
  static void startDFU(
      String filePath, String deviceFirmwareVersion, bool isForceCompleteUpdate,
      {required Function(double progress, bool isSuccess) callBack}) async {
    PPBluetoothKitFlutterPlatform.instance.startDFU(
        _peripheralType, filePath, deviceFirmwareVersion, isForceCompleteUpdate,
        callBack: callBack);
  }
}
