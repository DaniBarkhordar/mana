import 'package:pp_bluetooth_kit_flutter/channel/pp_bluetooth_kit_flutter_platform_interface.dart';

///@author liyp
///@email liyp520@foxmail.com
///@date 2025/1/10 11:15
//@description


class PPBluetoothKitLogger {

  static bool _enabled = true;
  static Function(String logStr)? _logListener;

  /// 添加日志监听回调
  /// [isDebug] true-调试模式，打印控制台日志，false-不打印控制台日志
  /// @param callBack 日志内容回调
  ///                 参数：[String] 日志内容
  static void addListener({bool isDebug = false, required Function(String logStr) callBack}) {
    PPBluetoothKitLogger._enabled = isDebug;
    PPBluetoothKitLogger._logListener = callBack;


    PPBluetoothKitFlutterPlatform.instance.loggerListener((content){
      PPBluetoothKitLogger.i(content);
    });

  }



  static void i(String msg) {
    PPBluetoothKitLogger._logListener?.call("[PPSdk]:$msg");

    if (PPBluetoothKitLogger._enabled) {
      print("[PPSdk]:$msg");
    }
  }

}


