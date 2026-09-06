import 'dart:async';
import 'dart:ffi';
import 'package:flutter/services.dart';
import 'package:pp_bluetooth_kit_flutter/enums/pp_scale_enums.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_body_base_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_180a_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_user.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_last_7_data_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_torre_user_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_wifi_result.dart';
import 'package:pp_bluetooth_kit_flutter/utils/pp_bluetooth_kit_logger.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_light_mode_model.dart';

import 'pp_bluetooth_kit_flutter_platform_interface.dart';

/// An implementation of [PpBluetoothKitFlutterPlatform] that uses method channels.
class MethodChannelPpBluetoothKitFlutter extends PPBluetoothKitFlutterPlatform {
  StreamSubscription? _logSubscription;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectSubscription;
  StreamSubscription? _measurementSubscription;
  StreamSubscription? _historySubscription;
  StreamSubscription? _batterySubscription;
  StreamSubscription? _blePermissionSubscription;
  StreamSubscription? _dfuSubscription;
  StreamSubscription? _deviceLogSubscription;
  StreamSubscription? _scanStateSubscription;
  StreamSubscription? _kitchenSubscription;

  final methodChannel = const MethodChannel('pp_bluetooth_kit_flutter');

  final _bleChannel = const MethodChannel('pp_ble_channel');

  final _loggerEvent = const EventChannel('pp_logger_streams');
  final _scanResultEvent = const EventChannel('pp_device_list_streams');
  final _connectStateEvent = const EventChannel('pp_connect_state_streams');
  final _measurementDataEvent = const EventChannel('pp_measurement_streams');
  final _historyDataEvent = const EventChannel('pp_history_data_streams');
  final _batteryEvent = const EventChannel('pp_battery_streams');
  final _blePermissionEvent = const EventChannel('pp_ble_permission_streams');
  final _dfuEvent = const EventChannel('pp_dfu_streams');
  final _deviceLogEvent = const EventChannel('device_log_streams');
  final _scanStateEvent = const EventChannel('pp_scan_state_streams');
  final _kitchenDataEvent = const EventChannel('pp_kitchen_streams');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<void> loggerListener(Function(String content) callBack) async {
    _logSubscription?.cancel();
    _logSubscription = _loggerEvent.receiveBroadcastStream().listen((event) {
      final content = '$event';
      PPBluetoothKitLogger.i(content);
    }, onError: (error) {
      PPBluetoothKitLogger.i('loggerListener-返回结果异常:$error');
    });
  }

  @override
  Future<void> initSDK(
      String appKey, String appSecret, String configContent) async {
    PPBluetoothKitLogger.i('执行初始化-initSDK appKey:$appKey appSecret:$appSecret');
    await _bleChannel.invokeMethod('initSDK', <String, dynamic>{
      'appKey': appKey,
      'appSecret': appSecret,
      'deviceContent': configContent
    });
  }

  @override
  Future<void> setDeviceSetting(String deviceContent) async {
    PPBluetoothKitLogger.i(
        '执行初始化-setDeviceSetting deviceContent len:${deviceContent.length}');
    await _bleChannel.invokeMethod(
        'setDeviceSetting', <String, dynamic>{'deviceContent': deviceContent});
  }

  @override
  Future<void> startScan(Function(PPDeviceModel device) callBack) async {
    PPBluetoothKitLogger.i('扫描到设备123456');

    _scanSubscription?.cancel();
    _scanSubscription =
        _scanResultEvent.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        try {
          final retJson = event.cast<String, dynamic>();
          PPBluetoothKitLogger.i('扫描到设备123456:$retJson');

          PPDeviceModel model = PPDeviceModel.fromJson(retJson);
          callBack(model);
        } catch (e) {
          PPBluetoothKitLogger.i('$e');
        }
      } else {
        PPBluetoothKitLogger.i('设备返回数据格式不正确');
      }
    });

    PPBluetoothKitLogger.i('开启扫描');
    await _bleChannel.invokeMethod('startScan');
  }

  @override
  Future<void> stopScan() async {
    PPBluetoothKitLogger.i('停止扫描');
    await _bleChannel.invokeMethod('stopScan');
  }

  @override
  Future<void> connectDevice(PPDeviceModel device,
      {required Function(PPDeviceConnectionState state) callBack}) async {
    this.stopScan();
    final deviceMac = device.deviceMac;
    final deviceName = device.deviceName;

    if (deviceMac == null || deviceMac.isEmpty) {
      callBack(PPDeviceConnectionState.error);
      PPBluetoothKitLogger.i('deviceMac 为空');
      return;
    }
    if (deviceName == null || deviceName.isEmpty) {
      callBack(PPDeviceConnectionState.error);
      PPBluetoothKitLogger.i('deviceName 为空');
      return;
    }

    _connectSubscription?.cancel();
    _connectSubscription =
        _connectStateEvent.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        try {
          final retJson = event.cast<String, dynamic>();
          int state = retJson['state'] as int;
          if (state == 0) {
            callBack(PPDeviceConnectionState.disconnected);
          } else if (state == 1) {
            callBack(PPDeviceConnectionState.connected);
          } else if (state == 2) {
            callBack(PPDeviceConnectionState.error);
          } else {
            callBack(PPDeviceConnectionState.undefine);
          }

          PPBluetoothKitLogger.i('连接状态-state:$state');
        } catch (e) {
          PPBluetoothKitLogger.i('连接状态-返回结果异常:$e');
        }
      } else {
        PPBluetoothKitLogger.i('连接状态-返回数据格式不正确');
      }
    });

    PPBluetoothKitLogger.i(
        '开始连接设备-deviceMac:$deviceMac deviceName:$deviceName');
    await _bleChannel.invokeMethod('connectDevice',
        <String, dynamic>{'deviceMac': deviceMac, 'deviceName': deviceName});
  }

  @override
  Future<void> disconnect() async {
    PPBluetoothKitLogger.i('执行-断开连接');
    await _bleChannel.invokeMethod("disconnect");
  }

  @override
  Future<void> addMeasurementListener(
      {required Function(PPMeasurementDataState measurementState,
              PPBodyBaseModel dataModel, PPDeviceModel device)
          callBack}) async {
    PPBluetoothKitLogger.i('添加测量监听-addMeasurementListener');
    _measurementSubscription?.cancel();
    _measurementSubscription =
        _measurementDataEvent.receiveBroadcastStream().listen((event) {
      final retJson1 = event.cast<String, dynamic>();

      PPBluetoothKitLogger.i('$retJson1');

      try {
        final retJson = event.cast<String, dynamic>();

        final stateCode = retJson['measurementState'] as int;
        final device = retJson['device'].cast<String, dynamic>();
        final data = retJson['data'].cast<String, dynamic>();

        var state = PPMeasurementDataState.processData;
        switch (stateCode) {
          case 1:
            state = PPMeasurementDataState.measuringBodyFat;
            break;
          case 2:
            state = PPMeasurementDataState.measuringHeartRate;
            break;
          case 10:
            state = PPMeasurementDataState.completed;
            break;
        }

        final model = PPBodyBaseModel.fromJson(data);
        final deviceModel = PPDeviceModel.fromJson(device);

        callBack(state, model, deviceModel);
      } catch (e) {
        PPBluetoothKitLogger.i('测量数据-返回结果异常:$e');
      }
    });
  }

  @override
  Future<void> fetchHistoryData(
      {String? userID = "",
      required int peripheralType,
      required Function(List<PPBodyBaseModel> dataList, bool isSuccess)
          callBack}) async {
    if (peripheralType == PPDevicePeripheralType.torre.value) {
      if (userID == null || userID.isEmpty) {
        PPBluetoothKitLogger.i('历史数据-userID 为空');
        callBack([], false);
        return;
      }
    }

    _historySubscription?.cancel();
    _historySubscription =
        _historyDataEvent.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        try {
          final retList = <PPBodyBaseModel>[];
          final retJson = event.cast<String, dynamic>();
          final array = retJson['dataList'] as List;
          if (array.isNotEmpty) {
            for (int i = 0; i < array.length; ++i) {
              final map = array[i].cast<String, dynamic>();
              final model = PPBodyBaseModel.fromJson(map);
              retList.add(model);
            }
          }

          callBack(retList, true);
        } catch (e) {
          PPBluetoothKitLogger.i('历史数据-返回结果异常:$e');

          callBack([], false);
        }
      } else {
        PPBluetoothKitLogger.i('历史数据-返回数据格式不正确');

        callBack([], false);
      }

      // // 返回数据，则不需要订阅
      // _historySubscription?.cancel();
    });

    PPBluetoothKitLogger.i('开始同步历史数据-$userID peripheralType:$peripheralType');
    await _bleChannel.invokeMethod('fetchHistory',
        <String, dynamic>{'peripheralType': peripheralType, 'userID': userID});
  }

  @override
  Future<void> deleteHistoryData(int peripheralType) async {
    PPBluetoothKitLogger.i('删除历史数据-peripheralType:$peripheralType');
    await _bleChannel.invokeMethod(
        'deleteHistory', <String, dynamic>{'peripheralType': peripheralType});
  }

  @override
  Future<bool?> syncUnit(int peripheralType, PPDeviceUser deviceUser) async {
    PPBluetoothKitLogger.i(
        '开始同步单位-${deviceUser.unitType} peripheralType:$peripheralType');

    try {
      final ret = await _bleChannel.invokeMethod("syncUnit", <String, dynamic>{
        'unit': deviceUser.unitType.type,
        'sex': deviceUser.sex.type,
        'age': deviceUser.age,
        'height': deviceUser.userHeight,
        'isPregnantMode': deviceUser.isPregnantMode,
        'isAthleteMode': deviceUser.isAthleteMode,
        'peripheralType': peripheralType
      });

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool?;

      PPBluetoothKitLogger.i('同步单位结果-$state');

      return state;
    } catch (e) {
      PPBluetoothKitLogger.i('同步单位-返回结果异常:$e');
      return false;
    }
  }

  @override
  Future<bool?> syncTime(int peripheralType, {bool is24Hour = true}) async {
    PPBluetoothKitLogger.i(
        '开始同步时间-is24Hour:$is24Hour peripheralType:$peripheralType');

    try {
      final ret = await _bleChannel.invokeMethod<Map>(
          'syncTime', <String, dynamic>{
        'peripheralType': peripheralType,
        'is24Hour': is24Hour
      });
      final retJson = ret?.cast<String, dynamic>();
      final state = (retJson?["state"] as bool?) ?? false;

      PPBluetoothKitLogger.i('同步时间-结果:$state');

      return state;
    } catch (e) {
      PPBluetoothKitLogger.i('同步时间-返回结果异常:$e');

      return false;
    }
  }

  @override
  Future<PPWifiResult> configWifi(int peripheralType,
      {required String domain,
      required String ssId,
      required String password}) async {
    PPBluetoothKitLogger.i(
        '开始配网-domain:$domain wifi:$ssId peripheralType:$peripheralType');

    try {
      final ret =
          await _bleChannel.invokeMethod<Map>('configWifi', <String, dynamic>{
        'domain': domain,
        'ssId': ssId,
        'password': password,
        'peripheralType': peripheralType
      });

      final retJson = ret?.cast<String, dynamic>();
      final success = retJson?["success"] as bool? ?? false;
      final sn = retJson?["sn"] as String?;
      final errorCode = retJson?["errorCode"] as int?;

      final retObj =
          PPWifiResult(success: success, sn: sn, errorCode: errorCode);

      PPBluetoothKitLogger.i(
          '配网结果:${retObj.success} errorCode:${retObj.errorCode}');

      return retObj;
    } catch (e) {
      PPBluetoothKitLogger.i('配网-返回结果异常:$e');
      return PPWifiResult(success: false, sn: null, errorCode: -1);
    }
  }

  @override
  Future<String?> fetchWifiInfo(int peripheralType) async {
    PPBluetoothKitLogger.i('获取配网信息-peripheralType:$peripheralType');

    try {
      final ret = await _bleChannel.invokeMethod<Map>(
          'fetchWifiInfo', <String, dynamic>{'peripheralType': peripheralType});

      final retJson = ret?.cast<String, dynamic>();
      final ssId = retJson?["ssId"] as String?;

      PPBluetoothKitLogger.i('获取配网信息结果-ssId:$ssId');

      return ssId;
    } catch (e) {
      PPBluetoothKitLogger.i('获取配网信息-返回结果异常:$e');
      return null;
    }
  }

  @override
  Future<bool?> isConnectWIFI(int peripheralType) async {
    PPBluetoothKitLogger.i('获取配网状态-peripheralType:$peripheralType');

    try {
      final ret = await _bleChannel.invokeMethod<Map>(
          'fetchWifiInfo', <String, dynamic>{'peripheralType': peripheralType});

      final retJson = ret?.cast<String, dynamic>();
      final connectedWIFI = retJson?["isConnectWIFI"] as bool?;

      PPBluetoothKitLogger.i('获取配网状态结果-$connectedWIFI');

      return connectedWIFI;
    } catch (e) {
      PPBluetoothKitLogger.i('获取是否配网-返回结果异常:$e');
      return null;
    }
  }

  @override
  Future<PPDevice180AModel?> fetchDeviceInfo(int peripheralType) async {
    PPBluetoothKitLogger.i('获取设备信息-peripheralType:$peripheralType');

    try {
      final ret = await _bleChannel.invokeMethod<Map>('fetchDeviceInfo',
          <String, dynamic>{'peripheralType': peripheralType});
      final retJson = ret?.cast<String, dynamic>();
      final modelNumber = retJson?["modelNumber"] as String?;
      final firmwareRevision = retJson?["firmwareRevision"] as String?;
      final softwareRevision = retJson?["softwareRevision"] as String?;
      final hardwareRevision = retJson?["hardwareRevision"] as String?;
      final serialNumber = retJson?["serialNumber"] as String?;
      final manufacturerName = retJson?["manufacturerName"] as String?;

      final retObj = PPDevice180AModel(
          modelNumber: modelNumber,
          firmwareRevision: firmwareRevision,
          softwareRevision: softwareRevision,
          hardwareRevision: hardwareRevision,
          serialNumber: serialNumber,
          manufacturerName: manufacturerName);

      PPBluetoothKitLogger.i(
          '获取设备信息结果-firmwareRevision:${retObj.firmwareRevision} modelNumber:${retObj.modelNumber}');

      return retObj;
    } catch (e) {
      PPBluetoothKitLogger.i('获取设备信息-返回结果异常:$e');
      return null;
    }
  }

  @override
  Future<void> fetchBatteryInfo(int peripheralType,
      {required bool continuity,
      required Function(int power, int? lumen) callBack}) async {
    _batterySubscription?.cancel();
    _batterySubscription =
        _batteryEvent.receiveBroadcastStream().listen((event) {
      if (continuity == false) {
        _batterySubscription?.cancel();
      }

      if (event is Map) {
        try {
          final retJson = event.cast<String, dynamic>();
          final power = retJson['power'] as int? ?? 0;
          final lumen = retJson['lumen'] as int?;

          callBack(power, lumen);
        } catch (e) {
          PPBluetoothKitLogger.i('获取电量-返回结果异常:$e');
          callBack(0, -1);
        }
      } else {
        PPBluetoothKitLogger.i('获取电量-返回数据格式不正确');

        callBack(0, -1);
      }
    });

    PPBluetoothKitLogger.i(
        '获取电量信息-continuity:$continuity peripheralType:$peripheralType');

    await _bleChannel.invokeMethod<Map>('fetchBatteryInfo',
        <String, dynamic>{'peripheralType': peripheralType});
  }

  @override
  Future<void> resetDevice(int peripheralType) async {
    PPBluetoothKitLogger.i('恢复出厂-peripheralType:$peripheralType');
    _bleChannel.invokeMethod<Map>(
        'resetDevice', <String, dynamic>{'peripheralType': peripheralType});
  }

  @override
  Future<PPDeviceModel?> fetchConnectedDevice() async {
    PPBluetoothKitLogger.i('获取当前连接设备');
    try {
      final ret = await _bleChannel.invokeMethod('fetchConnectedDevice');
      if (ret is Map) {
        final retJson = ret.cast<String, dynamic>();
        PPDeviceModel model = PPDeviceModel.fromJson(retJson);

        PPBluetoothKitLogger.i('获取当前连接设备结果-deviceMac:${model.deviceMac}');

        if (model.deviceMac != null) {
          return model;
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      PPBluetoothKitLogger.i('获取已连接的设备-返回结果异常:$e');

      return null;
    }
  }

  @override
  Future<void> blePermissionListener(
      {required Function(PPBlePermissionState state) callBack}) async {
    _blePermissionSubscription?.cancel();
    _blePermissionSubscription =
        _blePermissionEvent.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        try {
          final retJson = event.cast<String, dynamic>();
          final stateValue = retJson['state'] as int? ?? 0;
          final state = PPBlePermissionState.fromInt(stateValue);
          callBack(state);
        } catch (e) {
          PPBluetoothKitLogger.i('蓝牙权限-监听结果异常:$e');
          callBack(PPBlePermissionState.unknown);
        }
      } else {
        PPBluetoothKitLogger.i('蓝牙权限-返回数据格式不正确');
        callBack(PPBlePermissionState.unknown);
      }
    });

    _bleChannel.invokeMethod('addBlePermissionListener');
  }

  @override
  Future<String?> fetchWifiMac(int peripheralType) async {
    PPBluetoothKitLogger.i('获取Wi-Fi Mac-peripheralType:$peripheralType');
    try {
      final ret = await _bleChannel.invokeMethod<Map>(
          'fetchWifiMac', <String, dynamic>{'peripheralType': peripheralType});

      final retJson = ret?.cast<String, dynamic>();
      final wifiMac = retJson?["wifiMac"] as String?;

      PPBluetoothKitLogger.i('获取Wi-Fi Mac 结果-$wifiMac');

      return wifiMac;
    } catch (e) {
      PPBluetoothKitLogger.i('获取Wi-Fi Mac-异常:$e');
      return null;
    }
  }

  @override
  Future<List<String>?> scanWifiNetworks(int peripheralType) async {
    PPBluetoothKitLogger.i('搜索周围Wi-Fi热点-peripheralType:$peripheralType');
    try {
      final ret = await _bleChannel.invokeMethod<Map>('scanWifiNetworks',
          <String, dynamic>{'peripheralType': peripheralType});

      final retJson = ret?.cast<String, dynamic>();
      final wifiList = retJson?["wifiList"]?.cast<String>().toList() ?? [];

      PPBluetoothKitLogger.i('搜索周围Wi-Fi热点结果-数量:${wifiList?.length}');

      return wifiList;
    } catch (e) {
      PPBluetoothKitLogger.i('获取周围Wi-Fi热点-异常:$e');
      return null;
    }
  }

  @override
  Future<bool> wifiOTA(int peripheralType) async {
    PPBluetoothKitLogger.i('Wi-Fi OTA-peripheralType:$peripheralType');
    try {
      final ret = await _bleChannel.invokeMethod<Map>(
          'wifiOTA', <String, dynamic>{'peripheralType': peripheralType});

      final retJson = ret?.cast<String, dynamic>();
      final isSuccess = retJson?["isSuccess"] as bool? ?? false;
      final errorCode = retJson?["errorCode"] as int?;

      PPBluetoothKitLogger.i('Wi-Fi OTA 状态:$isSuccess errorCode:$errorCode');

      return isSuccess;
    } catch (e) {
      PPBluetoothKitLogger.i('Wi-Fi OTA-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> heartRateSwitchControl(int peripheralType, bool open) async {
    PPBluetoothKitLogger.i(
        '设置心率控制开关-open:$open peripheralType:$peripheralType');
    try {
      final ret = await _bleChannel.invokeMethod<Map>('heartRateSwitchControl',
          <String, dynamic>{'peripheralType': peripheralType, 'open': open});

      final retJson = ret?.cast<String, dynamic>();
      final isSuccess = retJson?["state"] as bool? ?? false;

      PPBluetoothKitLogger.i('设置心率控制开关结果:$isSuccess');

      return isSuccess;
    } catch (e) {
      PPBluetoothKitLogger.i('设置心率控制开关-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> fetchHeartRateSwitch(int peripheralType) async {
    PPBluetoothKitLogger.i('获取心率控制开关-peripheralType:$peripheralType');
    try {
      final ret = await _bleChannel.invokeMethod<Map>('fetchHeartRateSwitch',
          <String, dynamic>{'peripheralType': peripheralType});

      final retJson = ret?.cast<String, dynamic>();
      final open = retJson?["open"] as bool? ?? false;

      PPBluetoothKitLogger.i('获取心率控制开关 结果-$open');

      return open;
    } catch (e) {
      PPBluetoothKitLogger.i('获取心率开关状态-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> impedanceSwitchControl(int peripheralType, bool open) async {
    PPBluetoothKitLogger.i(
        '设置阻抗控制开关-open:$open peripheralType:$peripheralType');
    try {
      final ret = await _bleChannel.invokeMethod<Map>('impedanceSwitchControl',
          <String, dynamic>{'peripheralType': peripheralType, 'open': open});

      final retJson = ret?.cast<String, dynamic>();
      final isSuccess = retJson?["state"] as bool? ?? false;

      PPBluetoothKitLogger.i('设置阻抗控制开关 结果-$isSuccess');

      return isSuccess;
    } catch (e) {
      PPBluetoothKitLogger.i('阻抗控制开关-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> fetchImpedanceSwitch(int peripheralType) async {
    PPBluetoothKitLogger.i('获取阻抗控制开关-peripheralType:$peripheralType');
    try {
      final ret = await _bleChannel.invokeMethod<Map>('fetchImpedanceSwitch',
          <String, dynamic>{'peripheralType': peripheralType});

      final retJson = ret?.cast<String, dynamic>();
      final open = retJson?["open"] as bool? ?? false;

      PPBluetoothKitLogger.i('获取阻抗控制开关-结果:$open');

      return open;
    } catch (e) {
      PPBluetoothKitLogger.i('获取阻抗开关状态-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> setBindingState(int peripheralType, bool binding) async {
    PPBluetoothKitLogger.i(
        '设置绑定状态-binding:$binding peripheralType:$peripheralType');
    try {
      final ret = await _bleChannel.invokeMethod<Map>(
          'setBindingState', <String, dynamic>{
        'peripheralType': peripheralType,
        'binding': binding
      });

      final retJson = ret?.cast<String, dynamic>();
      final isSuccess = retJson?["state"] as bool? ?? false;

      PPBluetoothKitLogger.i('设置绑定状态 结果:$isSuccess');

      return isSuccess;
    } catch (e) {
      PPBluetoothKitLogger.i('设置设备绑定状态-异常:$e');
      return false;
    }
  }

  @override
  Future<bool?> fetchBindingState(int peripheralType) async {
    PPBluetoothKitLogger.i('获取绑定状态-peripheralType:$peripheralType');
    try {
      final ret = await _bleChannel.invokeMethod<Map>('fetchBindingState',
          <String, dynamic>{'peripheralType': peripheralType});

      final retJson = ret?.cast<String, dynamic>();
      final binding = retJson?["binding"] as bool? ?? null;

      PPBluetoothKitLogger.i('获取绑定状态 结果-binding:$binding');

      return binding;
    } catch (e) {
      PPBluetoothKitLogger.i('获取设备绑定状态-异常:$e');
      return null;
    }
  }

  @override
  Future<bool> setRGBMode(
      int peripheralType, PPDeviceLightModeModel model) async {
    PPBluetoothKitLogger.i('灯光管理peripheralType:$peripheralType');

    try {
      final ret =
          await _bleChannel.invokeMethod<Map>('setRGBMode', model.toJson());

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      PPBluetoothKitLogger.i('设置屏幕亮度 结果:$state');

      return state;
    } catch (e) {
      PPBluetoothKitLogger.i('设置屏幕亮度-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> setScreenBrightness(int peripheralType, int brightness) async {
    PPBluetoothKitLogger.i(
        '设置屏幕亮度-brightness:$brightness peripheralType:$peripheralType');

    if (brightness < 0 || brightness > 100) {
      PPBluetoothKitLogger.i('设置屏幕亮度-参数异常');
      return false;
    }

    try {
      final ret = await _bleChannel.invokeMethod<Map>(
          'setScreenBrightness', <String, dynamic>{
        'peripheralType': peripheralType,
        'brightness': brightness
      });

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      PPBluetoothKitLogger.i('设置屏幕亮度 结果:$state');

      return state;
    } catch (e) {
      PPBluetoothKitLogger.i('设置屏幕亮度-异常:$e');
      return false;
    }
  }

  @override
  Future<int> fetchScreenBrightness(int peripheralType) async {
    PPBluetoothKitLogger.i('获取屏幕亮度-peripheralType:$peripheralType');

    try {
      final ret = await _bleChannel.invokeMethod<Map>('getScreenBrightness',
          <String, dynamic>{'peripheralType': peripheralType});

      final retJson = ret?.cast<String, dynamic>();
      final brightness = retJson?["brightness"] as int? ?? 0;

      PPBluetoothKitLogger.i('获取屏幕亮度 结果-brightness:$brightness');

      return brightness;
    } catch (e) {
      PPBluetoothKitLogger.i('获取屏幕亮度-异常:$e');
      return 0;
    }
  }

  @override
  Future<bool> syncUserInfo(
      int peripheralType, PPTorreUserModel userModel) async {
    PPBluetoothKitLogger.i(
        '同步单个用户-userID:${userModel.userID} memberID:${userModel.memberID} peripheralType:$peripheralType');

    if (userModel.userID.isEmpty || userModel.memberID.isEmpty) {
      PPBluetoothKitLogger.i('同步用户- userID 或 memberID 为空');
      return false;
    }

    try {
      Map<String, dynamic> userMap = userModel.toJson();
      userMap['peripheralType'] = peripheralType;

      final ret = await _bleChannel.invokeMethod<Map>('syncUserInfo', userMap);

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      PPBluetoothKitLogger.i('同步单个用户 结果:$state');

      return state;
    } catch (e) {
      PPBluetoothKitLogger.i('同步单个用户-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> syncUserList(
      int peripheralType, List<PPTorreUserModel> userList) async {
    PPBluetoothKitLogger.i(
        '同步用户列表-数量:${userList.length} peripheralType:$peripheralType');
    try {
      List<Map<String, dynamic>> list = [];

      for (var model in userList) {
        if (model.userID.isEmpty || model.memberID.isEmpty) {
          PPBluetoothKitLogger.i('同步用户列表- userID 或 memberID 为空');
          return false;
        }

        final map = model.toJson();
        list.add(map);
      }

      Map<String, dynamic> userMap = {
        'userList': list,
        'peripheralType': peripheralType
      };

      final ret = await _bleChannel.invokeMethod<Map>('syncUserList', userMap);

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      PPBluetoothKitLogger.i('同步用户列表 结果:$state');

      return state;
    } catch (e) {
      PPBluetoothKitLogger.i('同步用户列表-异常:$e');
      return false;
    }
  }

  @override
  Future<List<String>> fetchUserIDList(int peripheralType) async {
    PPBluetoothKitLogger.i('获取用户ID列表-peripheralType:$peripheralType');
    try {
      final ret = await _bleChannel.invokeMethod<Map>('fetchUserIDList',
          <String, dynamic>{'peripheralType': peripheralType});

      final retJson = ret?.cast<String, dynamic>();
      final userIDList = retJson?["userIDList"]?.cast<String>().toList() ?? [];

      PPBluetoothKitLogger.i('获取用户ID列表 结果-数量${userIDList.length}');

      return userIDList;
    } catch (e) {
      PPBluetoothKitLogger.i('获取设备用户ID列表-异常:$e');
      return [];
    }
  }

  @override
  Future<List<PPTorreUserModel>> fetchUserList(int peripheralType) async {
    PPBluetoothKitLogger.i('获取用户列表-peripheralType:$peripheralType');
    try {
      final ret = await _bleChannel.invokeMethod<Map>('fetchUserInfoList',
          <String, dynamic>{'peripheralType': peripheralType});

      final retList = <PPTorreUserModel>[];

      final retJson = ret?.cast<String, dynamic>();
      final array = retJson?["userList"] as List;
      if (array.isNotEmpty) {
        for (int i = 0; i < array.length; ++i) {
          final map = array[i].cast<String, dynamic>();
          final model = PPTorreUserModel.fromJson(map);
          retList.add(model);
        }
      }

      PPBluetoothKitLogger.i('获取用户列表 结果-数量${array.length}');

      return retList;
    } catch (e) {
      PPBluetoothKitLogger.i('获取设备用户列表-异常:$e');
      return [];
    }
  }

  @override
  Future<bool> selectUser(
      int peripheralType, String userID, String memberID) async {
    PPBluetoothKitLogger.i(
        '选中用户-userID:$userID memberID:$memberID peripheralType:$peripheralType');
    try {
      final ret = await _bleChannel.invokeMethod<Map>(
          'selectUser', <String, dynamic>{
        'peripheralType': peripheralType,
        'userID': userID,
        'memberID': memberID
      });

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      PPBluetoothKitLogger.i('选中用户 结果:$state');

      return state;
    } catch (e) {
      PPBluetoothKitLogger.i('选择测量用户-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> deleteUser(
      int peripheralType, String userID, String memberID) async {
    if (userID.isEmpty) {
      PPBluetoothKitLogger.i('删除设备用户失败- userID 为空');
      return false;
    }

    // if (memberID.isEmpty ||
    //     peripheralType == PPDevicePeripheralType.torre.value) {
    //   // 删除 userID 下所有成员

    // memberID = "ff";
    // }

    PPBluetoothKitLogger.i(
        '删除设备用户-userID:$userID memberID:$memberID peripheralType:$peripheralType');

    try {
      final ret = await _bleChannel.invokeMethod<Map>(
          'deleteUser', <String, dynamic>{
        'peripheralType': peripheralType,
        'userID': userID,
        'memberID': memberID
      });

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      PPBluetoothKitLogger.i('删除设备用户 结果:$state');

      return state;
    } catch (e) {
      PPBluetoothKitLogger.i('删除设备用户-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> startMeasure(int peripheralType) async {
    PPBluetoothKitLogger.i('开始测量-peripheralType:$peripheralType');
    try {
      final ret = await _bleChannel.invokeMethod<Map>(
          'startMeasure', <String, dynamic>{'peripheralType': peripheralType});

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      PPBluetoothKitLogger.i('开始测量 结果:$state');

      return state;
    } catch (e) {
      PPBluetoothKitLogger.i('开始测量-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> stopMeasure(int peripheralType) async {
    PPBluetoothKitLogger.i('停止测量-peripheralType:$peripheralType');
    try {
      final ret = await _bleChannel.invokeMethod<Map>(
          'stopMeasure', <String, dynamic>{'peripheralType': peripheralType});

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      PPBluetoothKitLogger.i('停止测量 结果-$state');

      return state;
    } catch (e) {
      PPBluetoothKitLogger.i('停止测量-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> startBabyModel(
      int peripheralType, PPBabyModelStep step, int weight) async {
    PPBluetoothKitLogger.i(
        '开始抱婴模式-step:$step weight:$weight peripheralType:$peripheralType');

    try {
      final ret = await _bleChannel.invokeMethod<Map>(
          'startBabyModel', <String, dynamic>{
        'peripheralType': peripheralType,
        'step': step.value,
        'weight': weight
      });

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      PPBluetoothKitLogger.i('开始抱婴模式 结果:$state step:$step');

      return state;
    } catch (e) {
      PPBluetoothKitLogger.i('开始抱婴模式-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> exitBabyModel(int peripheralType) async {
    PPBluetoothKitLogger.i('退出抱婴模式-peripheralType:$peripheralType');
    try {
      final ret = await _bleChannel.invokeMethod<Map>(
          'exitBabyModel', <String, dynamic>{'peripheralType': peripheralType});

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      PPBluetoothKitLogger.i('退出抱婴模式 结果-$state');

      return state;
    } catch (e) {
      PPBluetoothKitLogger.i('退出抱婴模式-异常:$e');
      return false;
    }
  }

  @override
  void startDFU(int peripheralType, String filePath,
      String deviceFirmwareVersion, bool isForceCompleteUpdate,
      {required Function(double progress, bool isSuccess) callBack}) async {
    PPBluetoothKitLogger.i(
        '蓝牙DFU升级-$isForceCompleteUpdate filePath:$filePath peripheralType:$peripheralType');
    if (filePath.isEmpty) {
      PPBluetoothKitLogger.i('蓝牙DFU-失败-升级包路径为空');
      callBack(0, false);
      return;
    }

    if (deviceFirmwareVersion.isEmpty) {
      deviceFirmwareVersion = '000.000.000.000';
    }

    _dfuSubscription?.cancel();
    _dfuSubscription = _dfuEvent.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        try {
          final retJson = event.cast<String, dynamic>();
          final progress = retJson['progress'] as double? ?? 0;
          final isSuccess = retJson['isSuccess'] as bool? ?? false;

          callBack(progress, isSuccess);
        } catch (e) {
          PPBluetoothKitLogger.i('蓝牙DFU-返回结果异常:$e');
          callBack(0, false);
        }
      } else {
        PPBluetoothKitLogger.i('蓝牙DFU-返回数据格式不正确');
        callBack(0, false);
      }
    });

    await _bleChannel.invokeMethod<Map>('startDFU', <String, dynamic>{
      'peripheralType': peripheralType,
      'filePath': filePath,
      'deviceFirmwareVersion': deviceFirmwareVersion,
      'isForceCompleteUpdate': isForceCompleteUpdate
    });
  }

  @override
  void syncDeviceLog(int peripheralType, String logFolder,
      {required Function(double progress, bool isFailed, String? filePath)
          callBack}) async {
    PPBluetoothKitLogger.i(
        '同步设备日志-logFolder:$logFolder peripheralType:$peripheralType');
    if (logFolder.isEmpty) {
      PPBluetoothKitLogger.i('同步设备日志-失败-日志文件夹为空');
      callBack(0, false, null);
      return;
    }

    _deviceLogSubscription?.cancel();
    _deviceLogSubscription =
        _deviceLogEvent.receiveBroadcastStream().listen((event) {
      try {
        final retJson = event.cast<String, dynamic>();
        final progress = retJson['progress'] as double? ?? 0;
        final filePath = retJson['filePath'] as String?;
        final isFailed = retJson['isFailed'] as bool? ?? false;
        callBack(progress, isFailed, filePath);
      } catch (e) {
        PPBluetoothKitLogger.i('获取设备日志-返回结果异常:$e');
        callBack(0, false, null);
      }
    });

    await _bleChannel.invokeMethod<Map>('syncDeviceLog', <String, dynamic>{
      'peripheralType': peripheralType,
      'logFolder': logFolder
    });
  }

  @override
  void addScanStateListener(
      {required Function(bool isScanning) callBack}) async {
    _scanStateSubscription?.cancel();
    _scanStateSubscription =
        _scanStateEvent.receiveBroadcastStream().listen((event) {
      try {
        final retJson = event.cast<String, dynamic>();
        final state = retJson['state'] as int? ?? 0;
        bool isScanning = state == 1;
        callBack(isScanning);
      } catch (e) {
        PPBluetoothKitLogger.i('扫描状态-返回结果异常:$e');
        callBack(false);
      }
    });
  }

  @override
  Future<void> keepAlive(int peripheralType) async {
    // PPBluetoothKitLogger.i('发送保活指令:peripheralType:$peripheralType');
    await _bleChannel.invokeMethod('keepAlive');
  }

  @override
  Future<bool> clearDeviceData(
      int peripheralType, PPClearDeviceDataType type) async {
    PPBluetoothKitLogger.i('清除设备数据-type:$type peripheralType:$peripheralType');
    try {
      final ret = await _bleChannel.invokeMethod<Map>(
          'clearDeviceData', <String, dynamic>{
        'peripheralType': peripheralType,
        'type': type.value
      });

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      PPBluetoothKitLogger.i('清除设备数据 结果:$state');

      return state;
    } catch (e) {
      PPBluetoothKitLogger.i('清除设备数据-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> setDeviceLanguage(
      int peripheralType, PPDeviceLanguage type) async {
    PPBluetoothKitLogger.i('设置设备语言-type:$type peripheralType:$peripheralType');
    try {
      final ret = await _bleChannel.invokeMethod<Map>(
          'setDeviceLanguage', <String, dynamic>{
        'peripheralType': peripheralType,
        'type': type.value
      });

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      PPBluetoothKitLogger.i('设置设备语言 结果 $state');

      return state;
    } catch (e) {
      PPBluetoothKitLogger.i('设置设备语言-异常:$e');
      return false;
    }
  }

  @override
  Future<void> fetchDeviceLanguage(int peripheralType,
      {required Function(PPDeviceLanguage? type, bool isSuccess)
          callBack}) async {
    PPBluetoothKitLogger.i('获取设备语言-peripheralType:$peripheralType');
    try {
      final ret = await _bleChannel
          .invokeMethod<Map>('fetcgDeviceLanguage', <String, dynamic>{
        'peripheralType': peripheralType,
      });

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;
      final typeCode = retJson?["type"] as int?;

      PPBluetoothKitLogger.i('获取设备语言 结果-typeCode:$typeCode');

      PPDeviceLanguage? type;
      if (typeCode != null) {
        type = PPDeviceLanguage.fromValue(typeCode);
      }

      callBack(type, state);
    } catch (e) {
      PPBluetoothKitLogger.i('获取设备语言-异常:$e');
    }
  }

  @override
  Future<void> setDisplayBodyFat(int bodyFat, int peripheralType) async {
    PPBluetoothKitLogger.i('设置设备回显的体脂率-peripheralType:$peripheralType');
    try {
      final ret = await _bleChannel.invokeMethod<Map>(
          'setDisplayBodyFat', <String, dynamic>{
        'peripheralType': peripheralType,
        'bodyFat': bodyFat
      });

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      PPBluetoothKitLogger.i('设置设备回显的体脂率 结果-$state');
    } catch (e) {
      PPBluetoothKitLogger.i('设置设备回显的体脂率-异常:$e');
    }
  }

  @override
  Future<void> exitScanWifiNetworks(int peripheralType) async {
    PPBluetoothKitLogger.i('退出搜索周边Wi-Fi热点-peripheralType:$peripheralType');
    try {
      final ret = await _bleChannel.invokeMethod<Map>('exitScanWifiNetworks',
          <String, dynamic>{'peripheralType': peripheralType});

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      PPBluetoothKitLogger.i('退出搜索周边Wi-Fi热点 结果-$state');
    } catch (e) {
      PPBluetoothKitLogger.i('退出搜索周边Wi-Fi热点-异常:$e');
    }
  }

  @override
  Future<bool> exitNetworkConfig(int peripheralType) async {
    PPBluetoothKitLogger.i('退出Wi-Fi配网-peripheralType:$peripheralType');
    try {
      final ret = await _bleChannel.invokeMethod<Map>('exitNetworkConfig',
          <String, dynamic>{'peripheralType': peripheralType});

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      PPBluetoothKitLogger.i('退出Wi-Fi配网 结果-$state');

      return state;
    } catch (e) {
      PPBluetoothKitLogger.i('退出Wi-Fi配网-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> receiveBroadcastData(
      PPDeviceModel device, int peripheralType) async {
    PPBluetoothKitLogger.i('接收广播设备数据-peripheralType:$peripheralType');

    final deviceMac = device.deviceMac;
    final deviceName = device.deviceName;

    if (deviceMac == null || deviceMac.isEmpty) {
      PPBluetoothKitLogger.i('deviceMac 为空');
      return false;
    }
    if (deviceName == null || deviceName.isEmpty) {
      PPBluetoothKitLogger.i('deviceName 为空');
      return false;
    }

    try {
      final ret = await _bleChannel
          .invokeMethod<Map>('receiveBroadcastData', <String, dynamic>{
        'peripheralType': peripheralType,
        'deviceMac': deviceMac,
        'deviceName': deviceName
      });

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      PPBluetoothKitLogger.i('接收广播设备数据 结果-$state');

      return state;
    } catch (e) {
      PPBluetoothKitLogger.i('接收广播设备数据-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> unReceiveBroadcastData(
      PPDeviceModel device, int peripheralType) async {
    PPBluetoothKitLogger.i('取消广播设备数据-peripheralType:$peripheralType');

    final deviceMac = device.deviceMac;
    final deviceName = device.deviceName;

    if (deviceMac == null || deviceMac.isEmpty) {
      PPBluetoothKitLogger.i('deviceMac 为空');
      return false;
    }
    if (deviceName == null || deviceName.isEmpty) {
      PPBluetoothKitLogger.i('deviceName 为空');
      return false;
    }

    try {
      final ret = await _bleChannel
          .invokeMethod<Map>('unReceiveBroadcastData', <String, dynamic>{
        'peripheralType': peripheralType,
        'deviceMac': deviceMac,
        'deviceName': deviceName
      });

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      PPBluetoothKitLogger.i('取消广播设备数据 结果-$state');

      return state;
    } catch (e) {
      PPBluetoothKitLogger.i('取消广播设备数据-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> sendBroadcastData(
      PPUnitType unit, PPBroadcastCommand cmd, int peripheralType) async {
    PPBluetoothKitLogger.i(
        '发送广播数据-unit:${unit.type} cmd:$cmd peripheralType:$peripheralType');

    try {
      final ret = await _bleChannel.invokeMethod<Map>(
          'sendBroadcastData', <String, dynamic>{
        'peripheralType': peripheralType,
        'unit': unit.type,
        'cmd': cmd.value
      });

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      PPBluetoothKitLogger.i('发送广播数据 结果-$state');

      return state;
    } catch (e) {
      PPBluetoothKitLogger.i('发送广播数据-异常:$e');
      return false;
    }
  }

  @override
  Future<void> addKitchenMeasurementListener(
      {required Function(PPMeasurementDataState measurementState,
              PPBodyBaseModel dataModel, PPDeviceModel device)
          callBack}) async {
    PPBluetoothKitLogger.i('添加厨房秤测量监听-addKitchenMeasurementListener');
    _kitchenSubscription?.cancel();
    _kitchenSubscription =
        _kitchenDataEvent.receiveBroadcastStream().listen((event) {
      try {
        final retJson = event.cast<String, dynamic>();

        final stateCode = retJson['measurementState'] as int;
        final device = retJson['device'].cast<String, dynamic>();
        final data = retJson['data'].cast<String, dynamic>();

        var state = PPMeasurementDataState.processData;
        switch (stateCode) {
          case 10:
            state = PPMeasurementDataState.completed;
            break;
        }

        final model = PPBodyBaseModel.fromJson(data);
        final deviceModel = PPDeviceModel.fromJson(device);

        callBack(state, model, deviceModel);
      } catch (e) {
        PPBluetoothKitLogger.i('厨房秤-测量数据-返回结果异常:$e');
      }
    });
  }

  @override
  Future<bool> toZero(int peripheralType) async {
    PPBluetoothKitLogger.i('去皮/清零-peripheralType:$peripheralType');

    try {
      final ret =
          await _bleChannel.invokeMethod<Map>('toZero', <String, dynamic>{
        'peripheralType': peripheralType,
      });

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      PPBluetoothKitLogger.i('去皮/清零 结果-$state');

      return state;
    } catch (e) {
      PPBluetoothKitLogger.i('去皮/清零-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> changeBuzzerGate(bool open) async {
    PPBluetoothKitLogger.i('开关蜂鸣器 $open');

    try {
      final ret = await _bleChannel
          .invokeMethod<Map>('changeBuzzerGate', <String, dynamic>{
        'open': open,
      });

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      PPBluetoothKitLogger.i('开关蜂鸣器 结果-$state');

      return state;
    } catch (e) {
      PPBluetoothKitLogger.i('开关蜂鸣器-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> last7Data(int peripheralType, PPLast7DataModel model) async {
    PPBluetoothKitLogger.i('同步最近7天/7次数据 peripheralType:$peripheralType');
    try {
      final dataMap = model.toJson();
      dataMap['peripheralType'] = peripheralType;

      final ret = await _bleChannel.invokeMethod<Map>('syncLast7Data', dataMap);

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      PPBluetoothKitLogger.i('同步最近7天/7次数据 结果:$state');

      return state;
    } catch (e) {
      PPBluetoothKitLogger.i('同步最近7天/7次数据-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> borreClast7Data(
      int peripheralType, PPLast7DataModel model) async {
    PPBluetoothKitLogger.i('同步最近7天/7次数据 peripheralType:$peripheralType');
    try {
      final dataMap = model.toJson();
      dataMap['peripheralType'] = peripheralType;

      final ret =
          await _bleChannel.invokeMethod<Map>('syncBorreCLast7Data', dataMap);

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      PPBluetoothKitLogger.i('同步borreC最近7天/7次数据 结果:$state');

      return state;
    } catch (e) {
      PPBluetoothKitLogger.i('同步borreC最近7天/7次数据-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> setDisplayMetrics(int peripheralType, int metrics) async {
    PPBluetoothKitLogger.i(
        '设置显示指标 peripheralType:$peripheralType metrics:$metrics');
    try {
      final ret = await _bleChannel
          .invokeMethod<Map>('setDisplayMetrics', {"metrics": metrics});

      return true;
    } catch (e) {
      PPBluetoothKitLogger.i('设置显示指标-异常:$e');
      return false;
    }
  }

  Future<PPDisplayMetrics> getDisplayMetrics(int peripheralType) async {
    PPBluetoothKitLogger.i('获取显示指标 peripheralType:$peripheralType');
    try {
      final ret = await _bleChannel.invokeMethod<Map>('getDisplayMetrics');
      final retJson = ret?.cast<String, dynamic>();

      final metrics = retJson?["metrics"] as int? ?? 0;

      return PPDisplayMetrics.fromValue(metrics);
    } catch (e) {
      PPBluetoothKitLogger.i('获取显示指标-异常:$e');
      return PPDisplayMetrics.unknown;
    }
  }

  @override
  Future<String> foodScaleUnit(
      double weightG,
      PPDeviceAccuracyType accuracyType,
      PPUnitType unitType,
      String deviceName) async {
    try {
      final ret = await _bleChannel
          .invokeMethod<Map>('foodScaleUnit', <String, dynamic>{
        'weightG': weightG,
        'accuracyType': accuracyType.value,
        'unitType': unitType.type,
        'deviceName': deviceName,
      });

      final retJson = ret?.cast<String, dynamic>();
      final weightStr = retJson?["weightStr"] as String? ?? "";

      return weightStr;
    } catch (e) {
      PPBluetoothKitLogger.i('食物秤转换单位-异常:$e');
      return "";
    }
  }
}
