import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pp_bluetooth_kit_flutter/enums/pp_scale_enums.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_body_base_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_180a_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_user.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_last_7_data_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_torre_user_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_wifi_result.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_light_mode_model.dart';

import 'pp_bluetooth_kit_flutter_method_channel.dart';

abstract class PPBluetoothKitFlutterPlatform extends PlatformInterface {
  /// Constructs a PpBluetoothKitFlutterPlatform.
  PPBluetoothKitFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static PPBluetoothKitFlutterPlatform _instance =
      MethodChannelPpBluetoothKitFlutter();

  /// The default instance of [PpBluetoothKitFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelPpBluetoothKitFlutter].
  static PPBluetoothKitFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PpBluetoothKitFlutterPlatform] when
  /// they register themselves.
  static set instance(PPBluetoothKitFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// API

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> loggerListener(Function(String content) callBack) {
    throw UnimplementedError('stopScan has not been implemented.');
  }

  Future<void> initSDK(String appKey, String appSecret, String configContent) {
    throw UnimplementedError('initSDK has not been implemented.');
  }

  Future<void> setDeviceSetting(String deviceContent) {
    throw UnimplementedError('setDeviceSetting has not been implemented.');
  }

  Future<void> startScan(Function(PPDeviceModel device) callBack) {
    throw UnimplementedError('startScan has not been implemented.');
  }

  Future<void> stopScan() {
    throw UnimplementedError('stopScan has not been implemented.');
  }

  Future<void> connectDevice(PPDeviceModel device,
      {required Function(PPDeviceConnectionState state) callBack}) {
    throw UnimplementedError('connectDevice has not been implemented.');
  }

  Future<void> disconnect() {
    throw UnimplementedError('disconnect has not been implemented.');
  }

  Future<void> addMeasurementListener(
      {required Function(PPMeasurementDataState measurementState,
              PPBodyBaseModel dataModel, PPDeviceModel device)
          callBack}) {
    throw UnimplementedError(
        'addMeasurementListener has not been implemented.');
  }

  Future<void> fetchHistoryData(
      {String? userID,
      required int peripheralType,
      required Function(List<PPBodyBaseModel> dataList, bool isSuccess)
          callBack}) {
    throw UnimplementedError('fetchHistoryData has not been implemented.');
  }

  Future<void> deleteHistoryData(int peripheralType) {
    throw UnimplementedError('deleteHistoryData has not been implemented.');
  }

  Future<bool?> syncUnit(int peripheralType, PPDeviceUser deviceUser) {
    throw UnimplementedError('syncUnit has not been implemented.');
  }

  Future<bool?> syncTime(int peripheralType, {bool is24Hour = true}) {
    throw UnimplementedError('syncTime has not been implemented.');
  }

  Future<PPWifiResult> configWifi(int peripheralType,
      {required String domain,
      required String ssId,
      required String password}) {
    throw UnimplementedError('configWifi has not been implemented.');
  }

  Future<String?> fetchWifiInfo(int peripheralType) {
    throw UnimplementedError('fetchWifiInfo has not been implemented.');
  }

  Future<bool?> isConnectWIFI(int peripheralType) {
    throw UnimplementedError('isConnectWIFI has not been implemented.');
  }

  Future<PPDevice180AModel?> fetchDeviceInfo(
    int peripheralType,
  ) {
    throw UnimplementedError('fetchDeviceInfo has not been implemented.');
  }

  Future<void> fetchBatteryInfo(int peripheralType,
      {required bool continuity,
      required Function(int power, int? lumen) callBack}) {
    throw UnimplementedError('fetchBatteryInfo has not been implemented.');
  }

  Future<void> resetDevice(int peripheralType) {
    throw UnimplementedError('resetDevice has not been implemented.');
  }

  Future<PPDeviceModel?> fetchConnectedDevice() {
    throw UnimplementedError('fetchConnectedDevice has not been implemented.');
  }

  Future<void> blePermissionListener(
      {required Function(PPBlePermissionState state) callBack}) {
    throw UnimplementedError('fetchConnectedDevice has not been implemented.');
  }

  Future<String?> fetchWifiMac(int peripheralType) {
    throw UnimplementedError('fetchWifiMac has not been implemented.');
  }

  Future<List<String>?> scanWifiNetworks(int peripheralType) {
    throw UnimplementedError('scanWifiNetworks has not been implemented.');
  }

  Future<bool> wifiOTA(int peripheralType) {
    throw UnimplementedError('wifiOTA has not been implemented.');
  }

  Future<bool> heartRateSwitchControl(int peripheralType, bool open) {
    throw UnimplementedError(
        'heartRateSwitchControl has not been implemented.');
  }

  Future<bool> fetchHeartRateSwitch(int peripheralType) {
    throw UnimplementedError('fetchHeartRateSwitch has not been implemented.');
  }

  Future<bool> impedanceSwitchControl(int peripheralType, bool open) {
    throw UnimplementedError(
        'impedanceSwitchControl has not been implemented.');
  }

  Future<bool> fetchImpedanceSwitch(int peripheralType) {
    throw UnimplementedError('fetchImpedanceSwitch has not been implemented.');
  }

  Future<bool> setBindingState(int peripheralType, bool binding) {
    throw UnimplementedError('setBindingState has not been implemented.');
  }

  Future<bool?> fetchBindingState(int peripheralType) {
    throw UnimplementedError('fetchBindingState has not been implemented.');
  }

  Future<bool> setScreenBrightness(int peripheralType, int brightness) {
    throw UnimplementedError('setScreenBrightness has not been implemented.');
  }

  Future<int> fetchScreenBrightness(int peripheralType) {
    throw UnimplementedError('fetchScreenBrightness has not been implemented.');
  }

  Future<bool> syncUserInfo(int peripheralType, PPTorreUserModel userModel) {
    throw UnimplementedError('syncUserInfo has not been implemented.');
  }

  Future<bool> syncUserList(
      int peripheralType, List<PPTorreUserModel> userList) {
    throw UnimplementedError('syncUserList has not been implemented.');
  }

  Future<List<String>> fetchUserIDList(int peripheralType) {
    throw UnimplementedError('fetchUserIDList has not been implemented.');
  }

  Future<bool> selectUser(int peripheralType, String userID, String memberID) {
    throw UnimplementedError('selectUser has not been implemented.');
  }

  Future<bool> deleteUser(int peripheralType, String userID, String memberID) {
    throw UnimplementedError('deleteUser has not been implemented.');
  }

  Future<bool> startMeasure(int peripheralType) {
    throw UnimplementedError('startMeasure has not been implemented.');
  }

  Future<bool> stopMeasure(int peripheralType) {
    throw UnimplementedError('stopMeasure has not been implemented.');
  }

  Future<bool> startBabyModel(
      int peripheralType, PPBabyModelStep step, int weight) {
    throw UnimplementedError('startBabyModel has not been implemented.');
  }

  Future<bool> exitBabyModel(int peripheralType) {
    throw UnimplementedError('exitBabyModel has not been implemented.');
  }

  void startDFU(int peripheralType, String filePath,
      String deviceFirmwareVersion, bool isForceCompleteUpdate,
      {required Function(double progress, bool isSuccess) callBack}) {
    throw UnimplementedError('startDFU has not been implemented.');
  }

  void syncDeviceLog(int peripheralType, String logFolder,
      {required Function(double progress, bool isFailed, String? filePath)
          callBack}) {
    throw UnimplementedError('syncDeviceLog has not been implemented.');
  }

  void addScanStateListener({required Function(bool isScanning) callBack}) {
    throw UnimplementedError('syncDeviceLog has not been implemented.');
  }

  Future<void> keepAlive(int peripheralType) {
    throw UnimplementedError('keepAlive has not been implemented.');
  }

  Future<bool> clearDeviceData(int peripheralType, PPClearDeviceDataType type) {
    throw UnimplementedError('clearDeviceData has not been implemented.');
  }

  Future<bool> setDeviceLanguage(int peripheralType, PPDeviceLanguage type) {
    throw UnimplementedError('setDeviceLanguage has not been implemented.');
  }

  Future<void> fetchDeviceLanguage(int peripheralType,
      {required Function(PPDeviceLanguage? type, bool isSuccess) callBack}) {
    throw UnimplementedError('fetchDeviceLanguage has not been implemented.');
  }

  Future<void> setDisplayBodyFat(int bodyFat, int peripheralType) {
    throw UnimplementedError('setDisplayBodyFat has not been implemented.');
  }

  Future<void> exitScanWifiNetworks(int peripheralType) {
    throw UnimplementedError('exitScanWifiNetworks has not been implemented.');
  }

  Future<bool> exitNetworkConfig(int peripheralType) {
    throw UnimplementedError('exitNetworkConfig has not been implemented.');
  }

  Future<bool> receiveBroadcastData(PPDeviceModel device, int peripheralType) {
    throw UnimplementedError('receiveBroadcastData has not been implemented.');
  }

  Future<bool> unReceiveBroadcastData(
      PPDeviceModel device, int peripheralType) {
    throw UnimplementedError(
        'unReceiveBroadcastData has not been implemented.');
  }

  Future<bool> sendBroadcastData(
      PPUnitType unit, PPBroadcastCommand cmd, int peripheralType) {
    throw UnimplementedError('sendBroadcastData has not been implemented.');
  }

  /// 厨房秤
  Future<void> addKitchenMeasurementListener(
      {required Function(PPMeasurementDataState measurementState,
              PPBodyBaseModel dataModel, PPDeviceModel device)
          callBack}) {
    throw UnimplementedError(
        'addKitchenMeasurementListener has not been implemented.');
  }

  Future<bool> toZero(int peripheralType) {
    throw UnimplementedError('toZero has not been implemented.');
  }

  Future<bool> changeBuzzerGate(bool open) async {
    throw UnimplementedError('changeBuzzerGate has not been implemented.');
  }

  Future<bool> last7Data(int peripheralType, PPLast7DataModel model) {
    throw UnimplementedError('last7Data has not been implemented.');
  }

  /// 同步最近7天/7次数据
  Future<bool> borreClast7Data(int peripheralType, PPLast7DataModel model) {
    throw UnimplementedError('borreClast7Data has not been implemented.');
  }

  Future<List<PPTorreUserModel>> fetchUserList(int peripheralType) {
    throw UnimplementedError('fetchUserList has not been implemented.');
  }

  Future<String> foodScaleUnit(
      double weightG,
      PPDeviceAccuracyType accuracyType,
      PPUnitType unitType,
      String deviceName) {
    throw UnimplementedError('foodScaleUnit has not been implemented.');
  }

  Future<bool> setRGBMode(int peripheralType, PPDeviceLightModeModel model) {
    throw UnimplementedError('setRGBModel has not been implemented.');
  }

  Future<bool> setDisplayMetrics(int peripheralType, int metrics) async {
    throw UnimplementedError('setRGBModel has not been implemented.');
  }

  Future<PPDisplayMetrics> getDisplayMetrics(int peripheralType) async {
    throw UnimplementedError('setRGBModel has not been implemented.');
  }
}
