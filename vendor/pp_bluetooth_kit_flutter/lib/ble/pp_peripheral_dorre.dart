import 'package:pp_bluetooth_kit_flutter/channel/pp_bluetooth_kit_flutter_platform_interface.dart';
import 'package:pp_bluetooth_kit_flutter/enums/pp_scale_enums.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_body_base_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_180a_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_user.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_torre_user_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_wifi_result.dart';

class PPPeripheralDorre {
  static final _peripheralType = PPDevicePeripheralType.dorre.value;

  /// 获取指定用户下所有成员历史数据
  /// userID：下发给设备的 userID
  /// [callBack] 返回的是设备离线测量的数据
  static void fetchUserHistoryData(String userID,
      {required Function(List<PPBodyBaseModel> dataList, bool isSuccess)
          callBack}) {
    PPBluetoothKitFlutterPlatform.instance.fetchHistoryData(
        userID: userID, peripheralType: _peripheralType, callBack: callBack);
  }

  /// 获取游客历史数据
  /// [callBack] 返回的是设备离线测量的数据
  static void fetchTouristsHistoryData(
      {required Function(List<PPBodyBaseModel> dataList, bool isSuccess)
          callBack}) {
    PPBluetoothKitFlutterPlatform.instance.fetchHistoryData(
        userID: "30", peripheralType: _peripheralType, callBack: callBack);
  }

  /// 同步时间
  /// 返回值：true:成功
  static Future<bool?> syncTime({bool is24Hour = true}) async {
    return PPBluetoothKitFlutterPlatform.instance
        .syncTime(_peripheralType, is24Hour: is24Hour);
  }

  /// 同步单位
  /// unitType 单位，必传
  static Future<bool?> syncUnit(PPUnitType unitType) async {
    final deviceUser = PPDeviceUser(
        userHeight: 175, age: 20, sex: PPUserGender.female, unitType: unitType);
    return PPBluetoothKitFlutterPlatform.instance
        .syncUnit(_peripheralType, deviceUser);
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

  /// 是否已配网（Wi-Fi）
  /// 返回: true：已配网，false：未配网
  static Future<bool?> isConnectWIFI() async {
    return PPBluetoothKitFlutterPlatform.instance
        .isConnectWIFI(_peripheralType);
  }

  /// 获取设备配网信息（Wi-Fi）
  /// 返回: 如果设备已配网，则返回设备中的 ssId
  static Future<String?> fetchWifiInfo() async {
    return PPBluetoothKitFlutterPlatform.instance
        .fetchWifiInfo(_peripheralType);
  }

  /// 获取 WIFI MAC 地址
  /// 举例：MAC 地址：01:02:03:04:05:06
  static Future<String?> fetchWifiMac() async {
    return PPBluetoothKitFlutterPlatform.instance.fetchWifiMac(_peripheralType);
  }

  /// 获取周围Wi-Fi热点
  /// 返回：获取到的Wi-Fi热点列表
  static Future<List<String>?> scanWifiNetworks() async {
    return PPBluetoothKitFlutterPlatform.instance
        .scanWifiNetworks(_peripheralType);
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

  /// 设置绑定状态
  /// binding: true-绑定 false-取消绑定
  static Future<bool> setBindingState(bool binding) async {
    return PPBluetoothKitFlutterPlatform.instance
        .setBindingState(_peripheralType, binding);
  }

  /// 获取绑定状态
  /// 返回：true-已绑定，false-未绑定
  static Future<bool> fetchBindingState() async {
    return PPBluetoothKitFlutterPlatform.instance
        .fetchBindingState(_peripheralType);
  }

  /// 设置屏幕亮度
  /// brightness：0-100的数值用来表示屏幕亮度
  static Future<bool> setScreenBrightness(int brightness) async {
    return PPBluetoothKitFlutterPlatform.instance
        .setScreenBrightness(_peripheralType, brightness);
  }

  /// 获取屏幕亮度
  /// 0-100的数值用来表示屏幕亮度
  static Future<int> fetchScreenBrightness() async {
    return PPBluetoothKitFlutterPlatform.instance
        .fetchScreenBrightness(_peripheralType);
  }

  /// 同步单个用户到设备
  /// userModel：用户信息
  static Future<bool> syncUserInfo(PPTorreUserModel userModel) async {
    return PPBluetoothKitFlutterPlatform.instance
        .syncUserInfo(_peripheralType, userModel);
  }

  /// 获取设备中用户列表
  /// 返回：设备中用户列表
  static Future<List<PPTorreUserModel>> fetchUserList() async {
    return PPBluetoothKitFlutterPlatform.instance
        .fetchUserList(_peripheralType);
  }

  /// 选择测量用户
  /// userID ：下发给设备的 userID
  /// memberID：下发给设备的 memberID
  static Future<bool> selectDeviceUser(String userID, String memberID) async {
    return PPBluetoothKitFlutterPlatform.instance
        .selectUser(_peripheralType, userID, memberID);
  }

  /// 删除设备中用户
  /// userID ：下发给设备的 userID
  /// memberID：下发给设备的 memberID，如果传“”空字符串，则删除 userID 下所有成员，否则只删除 memberID 匹配的成员
  static Future<bool> deleteDeviceUser(String userID, String memberID) async {
    return PPBluetoothKitFlutterPlatform.instance
        .deleteUser(_peripheralType, userID, memberID);
  }

  /// 开始测量
  static Future<bool> startMeasure() async {
    return PPBluetoothKitFlutterPlatform.instance.startMeasure(_peripheralType);
  }

  /// 停止测量
  static Future<bool> stopMeasure() async {
    return PPBluetoothKitFlutterPlatform.instance.stopMeasure(_peripheralType);
  }

  /// 开启"抱婴模式"测量
  /// [step]：标识第几次上称，PPBabyModelStep.one 第一次上秤，PPBabyModelStep.two 第二次上秤
  /// [weight]：上次上秤重量，step 为 PPBabyModelStep.one时，传0
  static Future<bool> enterBabyModel(PPBabyModelStep step, int weight) async {
    return PPBluetoothKitFlutterPlatform.instance
        .startBabyModel(_peripheralType, step, weight);
  }

  /// 退出"抱婴模式"测量
  static Future<bool> exitBabyModel() async {
    return PPBluetoothKitFlutterPlatform.instance
        .exitBabyModel(_peripheralType);
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

  /// 清除设备数据
  static Future<bool> clearDeviceData(PPClearDeviceDataType type) async {
    return PPBluetoothKitFlutterPlatform.instance
        .clearDeviceData(_peripheralType, type);
  }

  /// 设置设备语言
  static Future<bool> setDeviceLanguage(PPDeviceLanguage type) async {
    return PPBluetoothKitFlutterPlatform.instance
        .setDeviceLanguage(_peripheralType, type);
  }

  /// 获取设备语言
  static void fetchDeviceLanguage(
      {required Function(PPDeviceLanguage? type, bool isSuccess) callBack}) {
    PPBluetoothKitFlutterPlatform.instance
        .fetchDeviceLanguage(_peripheralType, callBack: callBack);
  }

  /// 退出Wi-Fi配网
  static Future<bool> exitNetworkConfig() async {
    return PPBluetoothKitFlutterPlatform.instance
        .exitNetworkConfig(_peripheralType);
  }
}
