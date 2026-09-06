import 'package:pp_bluetooth_kit_flutter/ble/pp_peripheral_apple.dart';
import 'package:pp_bluetooth_kit_flutter/channel/pp_bluetooth_kit_flutter_platform_interface.dart';
import 'package:pp_bluetooth_kit_flutter/enums/pp_scale_enums.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_body_base_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_model.dart';
import 'package:pp_bluetooth_kit_flutter/utils/pp_bluetooth_kit_logger.dart';

class PPBluetoothKitManager {
  /// 初始化蓝牙SDK
  ///
  /// 必须在调用其他功能前先初始化
  ///
  /// @param appKey    应用唯一标识
  /// @param appSecret 应用安全密钥
  /// @param configContent  配置文件内容(加密内容)
  static void initSDK(String appKey, String appSecret, String configContent) {
    PPBluetoothKitFlutterPlatform.instance
        .initSDK(appKey, appSecret, configContent);
  }

  /// 开始扫描蓝牙设备
  ///
  /// @param callBack 设备发现回调
  ///                 参数：[PPDeviceModel] 发现的设备模型
  static Future<void> startScan(Function(PPDeviceModel device) callBack) async {
    await PPBluetoothKitFlutterPlatform.instance.startScan(callBack);
  }

  /// 停止扫描蓝牙设备
  static Future<void> stopScan() async {
    print('祝融SDK停止扫描');
    await PPBluetoothKitFlutterPlatform.instance.stopScan();
  }

  /// 添加蓝牙权限状态监听
  /// 多次注册，只有最后一次注册生效，建议全局只注册一个
  /// @param callBack 权限变更回调
  ///                 参数：[PPBlePermissionState] 当前权限状态
  static void addBlePermissionListener(
      {required Function(PPBlePermissionState state) callBack}) {
    PPBluetoothKitFlutterPlatform.instance
        .blePermissionListener(callBack: callBack);
  }

  /// 连接指定蓝牙设备
  ///
  /// 注:需要先调用 PPBluetoothKitManager 的 startScan 方法 搜索到指定设备，再调用此方法连接该设备
  /// @param device   要连接的设备模型，从扫描结果获取（startScan 方法）
  /// @param callBack 连接状态回调
  ///                 参数：[PPDeviceConnectionState] 连接状态枚举
  ///                 注意：连接成功/断开连接都会触发
  static void connectDevice(PPDeviceModel device,
      {required Function(PPDeviceConnectionState state) callBack}) {
    PPBluetoothKitFlutterPlatform.instance
        .connectDevice(device, callBack: callBack);
  }

  /// 添加测量数据监听器
  /// 多次注册，只有最后一次注册生效，建议全局只注册一个
  /// @param callBack 测量数据回调，包含三个参数：
  ///                 1. [PPMeasurementDataState] 测量状态
  ///                 2. [PPBodyBaseModel] 测量数据模型
  ///                 3. [PPDeviceModel] 数据来源设备
  static void addMeasurementListener(
      {required Function(PPMeasurementDataState measurementState,
              PPBodyBaseModel dataModel, PPDeviceModel device)
          callBack}) {
    PPBluetoothKitFlutterPlatform.instance
        .addMeasurementListener(callBack: callBack);
  }

  /// 获取当前已连接的设备
  ///
  /// @return [Future<PPDeviceModel?>] 已连接设备模型
  static Future<PPDeviceModel?> fetchConnectedDevice() async {
    return PPBluetoothKitFlutterPlatform.instance.fetchConnectedDevice();
  }

  /// 设置设备配置参数
  ///
  /// @param jsonContent 设备配置JSON字符串
  static void setDeviceSetting(String jsonContent) {
    PPBluetoothKitFlutterPlatform.instance.setDeviceSetting(jsonContent);
  }

  /// 主动断开当前设备连接
  static void disconnect() {
    PPBluetoothKitFlutterPlatform.instance.disconnect();
  }

  /// 添加扫描状态监听
  ///
  /// @param callBack 扫描状态回调
  ///                 参数：[bool] 是否正在扫描
  static void addScanStateListener(
      {required Function(bool isScanning) callBack}) async {
    PPBluetoothKitFlutterPlatform.instance
        .addScanStateListener(callBack: callBack);
  }

  /// 添加厨房秤-测量数据监听器
  /// 多次注册，只有最后一次注册生效
  /// @param callBack 测量数据回调，包含三个参数：
  ///                 1. [PPMeasurementDataState] 测量状态
  ///                 2. [PPBodyBaseModel] 测量数据模型
  ///                 3. [PPDeviceModel] 数据来源设备
  static void addKitchenMeasurementListener(
      {required Function(PPMeasurementDataState measurementState,
              PPBodyBaseModel dataModel, PPDeviceModel device)
          callBack}) {
    PPBluetoothKitFlutterPlatform.instance
        .addKitchenMeasurementListener(callBack: callBack);
  }
}
