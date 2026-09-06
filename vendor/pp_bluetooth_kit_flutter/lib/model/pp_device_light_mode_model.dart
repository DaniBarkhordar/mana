class PPDeviceLightModeModel {
  String defalutColor;
  String gainColor;
  String lossColor;
  int lightEnable;
  int lightMode;

  PPDeviceLightModeModel({
    required this.defalutColor,
    required this.gainColor,
    required this.lossColor,
    required this.lightEnable,
    required this.lightMode,
  });

  factory PPDeviceLightModeModel.fromJson(Map<String, dynamic> json) {
    return PPDeviceLightModeModel(
      defalutColor: json['defalutColor'] ?? '',
      gainColor: json['gainColor'] ?? '',
      lossColor: json['lossColor'] ?? '',
      lightEnable: json['lightEnable'] ?? 0,
      lightMode: json['lightMode'] ?? 0,
    );
  }

  // 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'defalutColor': defalutColor,
      'gainColor': gainColor,
      'lossColor': lossColor,
      'lightEnable': lightEnable,
      'lightMode': lightMode,
    };
  }
}
