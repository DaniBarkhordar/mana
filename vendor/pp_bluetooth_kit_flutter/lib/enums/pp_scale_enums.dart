///@author liyp
///@email liyp520@foxmail.com
///@date 2025/1/9 16:57

//@description
enum PPDeviceConnectType {
  unknown(0),
  broadcast(1), //广播
  direct(2), //直连
  Lte(3); //(4G设备)

  final int value;
  const PPDeviceConnectType(this.value);

  static PPDeviceConnectType? fromValue(int value) {
    try {
      return values.firstWhere((e) => e.value == value);
    } catch (_) {
      return null;
    }
  }
}

enum PPDevicePeripheralType {
  apple(0),
  banana(1),
  coconut(2),
  durian(3),
  egg(4),
  fish(5),
  grapes(6),
  hamburger(7),
  torre(8),
  ice(9),
  jambul(10),
  kiwifruit(11),
  borre(12),
  dorre(13),
  forre(14);

  final int value;
  const PPDevicePeripheralType(this.value);

  static PPDevicePeripheralType? fromValue(int value) {
    try {
      return values.firstWhere((e) => e.value == value);
    } catch (_) {
      return null;
    }
  }
}

enum PPDeviceType {
  unknown(0), // 未知
  cf(1), // 体脂秤
  ce(2), //体重秤
  cb(3), // 婴儿秤
  ca(4); // 厨房秤

  final int value;
  const PPDeviceType(this.value);

  static PPDeviceType fromValue(int value) {
    try {
      return values.firstWhere((e) => e.value == value);
    } catch (_) {
      return unknown;
    }
  }
}

enum PPDeviceProtocolType {
  unknown(0),
  v2(1),
  v3(2),
  torre(3),
  v4(4),
  borre(5),
  dorre(6),
  forre(7),
  borre_A(8),
  korre(9),
  lorre(10),
  morre(11),
  borre_B(12),
  borre_C(13);

  final int value;
  const PPDeviceProtocolType(this.value);

  static PPDeviceProtocolType fromValue(int value) {
    try {
      return values.firstWhere((e) => e.value == value);
    } catch (_) {
      return unknown;
    }
  }
}

enum PPDeviceCalculateType {
  unknown(0),
  inScale(1),
  direct(2),
  alternate(3),
  alternate8(4),
  normal(5),
  needNot(6),
  alternate8_0(7),
  alternate8_1(8),
  alternate4_0(9),
  alternate4_1(10),
  alternate8_2(11),
  alternate8_3(12),
  alternate8_4(13),
  alternate8_5(14);

  final int value;
  const PPDeviceCalculateType(this.value);

  static PPDeviceCalculateType fromValue(int value) {
    try {
      return values.firstWhere((e) => e.value == value);
    } catch (_) {
      return unknown;
    }
  }
}

enum PPDeviceAccuracyType {
  unknown(0),
  point01(1),
  point005(2),
  pointG(3),
  point01G(4),
  point001(5);

  final int value;
  const PPDeviceAccuracyType(this.value);

  static PPDeviceAccuracyType fromValue(int value) {
    try {
      return values.firstWhere((e) => e.value == value);
    } catch (_) {
      return unknown;
    }
  }
}

enum PPDevicePowerType {
  unknown(0),
  battery(1),
  solar(2),
  charge(3);

  final int value;
  const PPDevicePowerType(this.value);

  static PPDevicePowerType fromValue(int value) {
    try {
      return values.firstWhere((e) => e.value == value);
    } catch (_) {
      return unknown;
    }
  }
}

enum PPDisplayMetrics {
  unknown(0),
  PPDisplayMetricsBMI(1),
  PPDisplayMetricsFat(2),
  PPDisplayMetricsPRO(3),
  PPDisplayMetricsMus(4),
  PPDisplayMetricsTbw(5),
  PPDisplayMetricsBon(6),
  PPDisplayMetricsAge(7);

  final int value;
  const PPDisplayMetrics(this.value);

  static PPDisplayMetrics fromValue(int value) {
    try {
      return values.firstWhere((e) => e.value == value);
    } catch (_) {
      return unknown;
    }
  }
}

/// 功能类型，可多功能叠加
enum PPDeviceFuncType {
  // 称重
  weight(0x01),

  // 测体脂
  fat(0x02),

  // 心率
  heartRate(0x04),

  // 历史数据
  history(0x08),

  // 安全模式，孕妇模式
  safe(0x10),

  // 闭幕单脚
  BMDJ(0x20),

  // 抱婴模式
  baby(0x40),

  // wifi配网
  Wifi(0x80),

  // 时钟功能
  time(0x0100),

  // 按键声音
  voice(0x0200),

  // 双向广播功能
  bidirectional(0x0400),

  // 呼吸灯
  light(0x0800),

  // V2.0是否支持用户信息
  userInfo(0x1000),

  // 时间制式
  timeFormat(0x2000),

  // 语言切换,其实就是二进制 100000000000000 转换为16进制，
  languageSwitch(0x4000),

  // 语音播报-四电极
  voiceType4(0x8000),

  // 语音播报-八电极
  voiceType8(0x010000),

  // 语音播报-CF610
  voiceTypecf610(0x020000),

  // 下发体重信息类型(条)---选中按条下发体重信息给秤, 未选中按天/条下发体重信息给秤
  weightInfoType(0x040000);

  final int type;

  const PPDeviceFuncType(this.type);

  /// 获取类型值
  int getType() {
    return type;
  }
}

enum PPDeviceUnitType {
  KG,
  LB,
  ST,
  Jin,
  STLB,
}

enum PPDeviceConnectionState {
  disconnected,
  connected,
  error,
  undefine,
}

enum PPUnitType {
  Unit_KG(0),
  Unit_LB(1),
  UnitST_LB(2),
  UnitJin(3),
  UnitG(4),
  UnitLBOZ(5),
  UnitOZ(6),
  UnitMLWater(7),
  UnitMLMilk(8),
  UnitFL_OZ_WATER(9),
  UnitFL_OZ_MILK(10),
  UnitST(11);

  final int type;

  const PPUnitType(this.type);
}

enum PPMeasurementDataState {
  processData, //过程数据
  measuringBodyFat, //测量体脂中（部分设备无此状态）
  measuringHeartRate, //测量心率中（部分设备无此状态）
  completed, //测量完成，此状态下获取 阻抗 计算身体数据
}

enum PPUserGender {
  female(0),
  male(1);

  final int type;

  const PPUserGender(this.type);
}

enum PPBlePermissionState {
  unknown(0), // 未知
  unauthorized(1), // 未授权
  on(2), // 蓝牙-开
  off(3); // 蓝牙-关

  final int state;
  const PPBlePermissionState(this.state);

  static PPBlePermissionState fromInt(int value) {
    return values.firstWhere(
      (e) => e.state == value,
      orElse: () => PPBlePermissionState.unknown,
    );
  }
}

enum PPBabyModelStep {
  one(0), // 第一步
  two(1); // 第二步

  final int value;

  const PPBabyModelStep(this.value);

  static PPBabyModelStep fromInt(int value1) {
    return values.firstWhere(
      (e) => e.value == value1,
      orElse: () => PPBabyModelStep.one,
    );
  }
}

enum PPClearDeviceDataType {
  /// 清除所有设备数据（包括：用户信息、历史数据、配网状态、设置信息）
  all(0),

  /// 仅清除用户信息（如用户账号、个性化设置等）
  userInfo(1),

  /// 仅清除历史记录数据（如测量记录、操作日志等）
  historyData(2),

  /// 仅清除网络配置信息（如Wi-Fi配网状态、网络凭证等）
  networkConfig(3),

  /// 仅清除设备设置信息（如单位设置、报警阈值等）
  settings(4);

  final int value;

  const PPClearDeviceDataType(this.value);

  static PPClearDeviceDataType fromValue(int value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('无效的类型值: $value'),
    );
  }
}

enum PPDeviceLanguage {
  /// 中文简体 (简体中文)
  chineseSimplified(0),

  /// 英文 (English)
  english(1),

  /// 中文繁体 (繁體中文)
  chineseTraditional(2),

  /// 日语 (日本語)
  japanese(3),

  /// 西班牙语 (Español)
  spanish(4),

  /// 葡萄牙语 (Português)
  portuguese(5),

  /// 阿拉伯语 (العربية)
  arabic(6),

  /// 韩语 (한국어)
  korean(7);

  final int value;

  const PPDeviceLanguage(this.value);

  static PPDeviceLanguage fromValue(int value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Invalid language value: $value'),
    );
  }
}

/// 设备命令枚举
enum PPBroadcastCommand {
  /// 退出安全模式
  exitSafeMode('37'),

  /// 设备进入安全模式，不会测量阻抗
  enterSafeMode('38');

  final String value;

  const PPBroadcastCommand(this.value);

  static PPBroadcastCommand fromValue(String value) {
    return values.firstWhere(
      (e) => e.value.toUpperCase() == value.toUpperCase(),
      orElse: () => throw ArgumentError('无效的命令值: $value'),
    );
  }
}

enum PPLast7DataType {
  weight(1), // 体重
  bmi(2), // BMI
  fat(3), // 体脂率
  waterPercentage(4), // 水分率
  muscle(5), // 肌肉率
  bmr(6);

  final int value;

  const PPLast7DataType(this.value);

  /// 根据整数值反向解析枚举
  static PPLast7DataType fromInt(int value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => PPLast7DataType.weight, // 默认返回 weight
    );
  }
}
