import 'package:pp_bluetooth_kit_flutter/channel/pp_bluetooth_kit_flutter_platform_interface.dart';
import 'package:pp_bluetooth_kit_flutter/enums/pp_scale_enums.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_body_base_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_180a_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_user.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_torre_user_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_wifi_result.dart';

class PPPeripheralIce {
  static final _peripheralType = PPDevicePeripheralType.ice.value;

  /// 同步时间
  /// 返回值：true:成功
  static Future<bool?> syncTime({bool is24Hour = true}) async {
    return PPBluetoothKitFlutterPlatform.instance
        .syncTime(_peripheralType, is24Hour: is24Hour);
  }

  /// 同步单位
  /// deviceUser 用户信息
  /// unitType 单位，必传
  /// userHeight 身高，必传
  /// age 年龄，必传
  /// sex 性别，必传
  /// isAthleteMode 运动员模式，可以不传
  /// isPregnantMode 孕妇模式，可以不传
  static Future<bool?> syncUnit(PPUnitType unitType) async {
    final deviceUser = PPDeviceUser(
        userHeight: 175, age: 20, sex: PPUserGender.female, unitType: unitType);
    return PPBluetoothKitFlutterPlatform.instance
        .syncUnit(_peripheralType, deviceUser);
  }

  /// 获取历史数据-获取历史数据后，调用 deleteHistoryData 删除设备中的历史数据
  /// [callBack] 返回的是设备离线测量的数据
  static void fetchHistoryData(
      {required Function(List<PPBodyBaseModel> dataList, bool isSuccess)
          callBack}) {
    PPBluetoothKitFlutterPlatform.instance
        .fetchHistoryData(peripheralType: _peripheralType, callBack: callBack);
  }

  /// 删除设备中的历史数据-执行后，设备中离线测量数据会被删除
  static void deleteHistoryData() {
    PPBluetoothKitFlutterPlatform.instance.deleteHistoryData(_peripheralType);
  }

  /// 配网（Wi-Fi）
  /// 参数说明：
  ///   - [domain] 配网服务器域名
  ///   - [ssId] Wi-Fi的名称（区分大小写）
  ///   - [password] Wi-Fi的密码
  ///   - [callBack] 配网结果回调函数，包含三个参数：
  ///     1. [success] true:成功，false：失败
  ///     2. [sn] sn
  ///     3. [errorCode] 错误码
  static Future<PPWifiResult> configWifi(
      {required String domain,
      required String ssId,
      required String password}) async {
    return PPBluetoothKitFlutterPlatform.instance.configWifi(_peripheralType,
        domain: domain, ssId: ssId, password: password);
  }

  /// 获取设备配网信息（Wi-Fi）
  /// 返回: 如果设备已配网，则返回设备中的 ssId
  static Future<String?> fetchWifiInfo() async {
    return PPBluetoothKitFlutterPlatform.instance
        .fetchWifiInfo(_peripheralType);
  }

  /// 获取周围Wi-Fi热点
  /// 返回：获取到的Wi-Fi热点列表
  static Future<List<String>?> scanWifiNetworks() async {
    return PPBluetoothKitFlutterPlatform.instance
        .scanWifiNetworks(_peripheralType);
  }

  static Future<void> exitScanWifiNetworks() async {
    await PPBluetoothKitFlutterPlatform.instance
        .exitScanWifiNetworks(_peripheralType);
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

  /// Wi-Fi OTA升级
  static Future<bool> wifiOTA() async {
    return PPBluetoothKitFlutterPlatform.instance.wifiOTA(_peripheralType);
  }

  /// 心率控制开关
  /// open： true-开，false-关
  static Future<bool> heartRateSwitchControl(bool open) async {
    return PPBluetoothKitFlutterPlatform.instance
        .heartRateSwitchControl(_peripheralType, open);
  }

  /// 获取心率开关状态
  /// 返回： true-开，false-关
  static Future<bool> fetchHeartRateSwitch() async {
    return PPBluetoothKitFlutterPlatform.instance
        .fetchHeartRateSwitch(_peripheralType);
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

  /// 开始"抱婴模式"测量
  static Future<bool> enterBabyModel() async {
    return PPBluetoothKitFlutterPlatform.instance
        .startBabyModel(_peripheralType, PPBabyModelStep.one, 0);
  }

  /// 退出"抱婴模式"测量
  static Future<bool> exitBabyModel() async {
    return PPBluetoothKitFlutterPlatform.instance
        .exitBabyModel(_peripheralType);
  }

  /// 获取设备日志
  /// [logFolder] 存放设备日志的文件夹路径，如:  沙盒路径//Log/DeviceLog
  /// [callBack]
  /// - progress 进度
  /// - isFailed 是否失败，true：同步设备日志失败
  /// - filePath 设备日志路径
  static void syncDeviceLog(String logFolder,
      {required Function(double progress, bool isFailed, String? filePath)
          callBack}) async {
    PPBluetoothKitFlutterPlatform.instance
        .syncDeviceLog(_peripheralType, logFolder, callBack: callBack);
  }

  /// 保活指令
  static void keepAlive() async {
    PPBluetoothKitFlutterPlatform.instance.keepAlive(_peripheralType);
  }

  /// 设置设备回显的体脂率
  static void setDisplayBodyFat(int bodyFat) async {
    PPBluetoothKitFlutterPlatform.instance
        .setDisplayBodyFat(bodyFat, _peripheralType);
  }

  /// 恢复出厂设置
  static void resetDevice() {
    PPBluetoothKitFlutterPlatform.instance.resetDevice(_peripheralType);
  }

  /// 退出Wi-Fi配网
  static Future<bool> exitNetworkConfig() async {
    return PPBluetoothKitFlutterPlatform.instance
        .exitNetworkConfig(_peripheralType);
  }
}
