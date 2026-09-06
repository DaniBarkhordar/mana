
import 'package:pp_bluetooth_kit_flutter/channel/pp_bluetooth_kit_flutter_platform_interface.dart';
import 'package:pp_bluetooth_kit_flutter/enums/pp_scale_enums.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_body_base_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_180a_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_user.dart';

class PPPeripheralCoconut {
  static final _peripheralType = PPDevicePeripheralType.coconut.value;
  
  
  /// 获取历史数据-获取历史数据后，调用 deleteHistoryData 删除设备中的历史数据
  /// [callBack] 返回的是设备离线测量的数据
  static void fetchHistoryData({required Function(List<PPBodyBaseModel> dataList, bool isSuccess) callBack}) {
    PPBluetoothKitFlutterPlatform.instance.fetchHistoryData(peripheralType:_peripheralType, callBack: callBack);
  }

  /// 删除设备中的历史数据-执行后，设备中离线测量数据会被删除
  static void deleteHistoryData() {
    PPBluetoothKitFlutterPlatform.instance.deleteHistoryData(_peripheralType);
  }

  /// 同步时间
  /// 返回值：true:成功
  static Future<bool?> syncTime() async {
    return PPBluetoothKitFlutterPlatform.instance.syncTime(_peripheralType);
  }

  /// 同步单位
  /// deviceUser 用户信息
  /// unitType 单位，必传
  /// userHeight 身高，必传
  /// age 年龄，必传
  /// sex 性别，必传
  /// isAthleteMode 运动员模式，可以不传
  /// isPregnantMode 孕妇模式，可以不传
  static Future<bool?> syncUnit(PPDeviceUser deviceUser) async {
    return PPBluetoothKitFlutterPlatform.instance.syncUnit(_peripheralType, deviceUser);
  }


  /// 获取设备信息
  static Future<PPDevice180AModel?> fetchDeviceInfo() async {
    return PPBluetoothKitFlutterPlatform.instance.fetchDeviceInfo(_peripheralType);
  }

  /// 获取设备电量
  /// continuity true:返回实时电量，false:只返回一次电量
  static void fetchBatteryInfo({required bool continuity, required Function(int power,int? lumen) callBack}) {
    PPBluetoothKitFlutterPlatform.instance.fetchBatteryInfo(_peripheralType, continuity: continuity, callBack: callBack);
  }


}