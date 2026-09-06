import '../enums/pp_scale_enums.dart';

///@author liyp
///@email liyp520@foxmail.com
///@date 2025/2/6 17:54
//@description

class PPScaleHelper {
  /// 是否支持历史数据
  static bool isSupportHistoryData(int? deviceFuncType) {
    if (deviceFuncType != null) {
      return (deviceFuncType & PPDeviceFuncType.history.type ==
          PPDeviceFuncType.history.type);
    }
    return false;
  }

  /// 是否支持Wifi
  static bool isFuncTypeWifi(int? deviceFuncType) {
    if (deviceFuncType != null) {
      return (deviceFuncType & PPDeviceFuncType.Wifi.type ==
          PPDeviceFuncType.Wifi.type);
    }
    return false;
  }

  static bool isFuncTypeTime(int? deviceFuncType) {
    if (deviceFuncType != null) {
      return (deviceFuncType & PPDeviceFuncType.time.type ==
          PPDeviceFuncType.time.type);
    }
    return false;
  }

  static bool isFuncTypeVoice(int? deviceFuncType) {
    if (deviceFuncType != null) {
      return (deviceFuncType & PPDeviceFuncType.voice.type ==
          PPDeviceFuncType.voice.type);
    }
    return false;
  }

  /// 是否支持时间制式
  static bool isFuncTypeTimeFormat(int? deviceFuncType) {
    if (deviceFuncType != null) {
      return (deviceFuncType & PPDeviceFuncType.timeFormat.type ==
          PPDeviceFuncType.timeFormat.type);
    }
    return false;
  }

  /// 是否支持语言切换
  static bool isFuncTypeLanguageSwitch(int? deviceFuncType) {
    if (deviceFuncType != null) {
      return (deviceFuncType & PPDeviceFuncType.languageSwitch.type ==
          PPDeviceFuncType.languageSwitch.type);
    }
    return false;
  }

  /// 语音播报-四电极
  static bool isVoiceTypeH4(int? deviceFuncType) {
    if (deviceFuncType != null) {
      return (deviceFuncType & PPDeviceFuncType.voiceType4.type ==
          PPDeviceFuncType.voiceType4.type);
    }
    return false;
  }

  /// 是否支持8电极
  static bool isVoiceTypeH8(int? deviceFuncType) {
    if (deviceFuncType != null) {
      return (deviceFuncType & PPDeviceFuncType.voiceType8.type ==
          PPDeviceFuncType.voiceType8.type);
    }
    return false;
  }

  /// CF610
  static bool isVoiceTypeCf610(int? deviceFuncType) {
    if (deviceFuncType != null) {
      return (deviceFuncType & PPDeviceFuncType.voiceTypecf610.type ==
          PPDeviceFuncType.voiceTypecf610.type);
    }
    return false;
  }

  /// 下发体重信息类型(条)
  static bool isSevenWeightInfoType(int? deviceFuncType) {
    if (deviceFuncType != null) {
      return (deviceFuncType & PPDeviceFuncType.weightInfoType.type ==
          PPDeviceFuncType.weightInfoType.type);
    }
    return false;
  }

  /// 是否支持呼吸灯
  static bool isFuncTypeLight(int? deviceFuncType) {
    if (deviceFuncType != null) {
      return (deviceFuncType & PPDeviceFuncType.light.type ==
          PPDeviceFuncType.light.type);
    }
    return false;
  }

  /// Apple系列是否支持用户信息下发
  static bool isFuncTypeUserInfo(int? deviceFuncType) {
    if (deviceFuncType != null) {
      return (deviceFuncType & PPDeviceFuncType.userInfo.type ==
          PPDeviceFuncType.userInfo.type);
    }
    return false;
  }

  static bool isFuncTypeTwoBroadcast(int? deviceFuncType) {
    if (deviceFuncType != null) {
      return (deviceFuncType & PPDeviceFuncType.bidirectional.type ==
          PPDeviceFuncType.bidirectional.type);
    }
    return false;
  }

  /// 是否支持测脂
  static bool isFat(int? deviceFuncType) {
    if (deviceFuncType != null) {
      return (deviceFuncType & PPDeviceFuncType.fat.type ==
          PPDeviceFuncType.fat.type);
    }
    return false;
  }

  /// 是否支持心率
  static bool isHeartRate(int? deviceFuncType) {
    if (deviceFuncType != null) {
      return (deviceFuncType & PPDeviceFuncType.heartRate.type ==
          PPDeviceFuncType.heartRate.type);
    }
    return false;
  }

  /// 是否是8电极
  static bool isCalcute8(int? calcuteType) {
    return calcuteType == PPDeviceCalculateType.alternate8.index ||
        calcuteType == PPDeviceCalculateType.alternate8_0.index ||
        calcuteType == PPDeviceCalculateType.alternate8_1.index ||
        calcuteType == PPDeviceCalculateType.alternate8_2.index ||
        calcuteType == PPDeviceCalculateType.alternate8_3.index ||
        calcuteType == PPDeviceCalculateType.alternate8_4.index;
  }

  /// 是否支持光能充电
  static bool isFuncTypeSolar(int? devicePowerType) {
    if (devicePowerType != null) {
      return (devicePowerType == PPDevicePowerType.solar.index);
    }
    return false;
  }
}
