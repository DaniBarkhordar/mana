import 'package:pp_bluetooth_kit_flutter/channel/pp_bluetooth_kit_flutter_platform_interface.dart';
import 'package:pp_bluetooth_kit_flutter/enums/pp_scale_enums.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_model.dart';


class PPPeripheralBanana {
  static final _peripheralType = PPDevicePeripheralType.banana.value;


  /// 接收设备的广播数据
  /// 注:需要先调用 PPBluetoothKitManager 的 startScan 方法 搜索到指定设备，再调用此方法接收该设备的广播数据（测量数据）
  static Future<bool> receiveDeviceData(PPDeviceModel device) async {
    return PPBluetoothKitFlutterPlatform.instance.receiveBroadcastData(device, _peripheralType);
  }

  /// 取消设备的广播数据，不再接收设备的广播数据
  /// 注:跟 receiveDeviceData 成对调用
  static Future<bool> unReceiveDeviceData(PPDeviceModel device) async {
    return PPBluetoothKitFlutterPlatform.instance.unReceiveBroadcastData(device, _peripheralType);
  }

}