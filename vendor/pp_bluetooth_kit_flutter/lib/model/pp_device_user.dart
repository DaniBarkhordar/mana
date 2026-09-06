

import 'dart:convert';
import '../enums/pp_scale_enums.dart';

class PPDeviceUser {
  PPUnitType unitType; // 单位
  int userHeight; // 身高
  int age; // 年龄
  PPUserGender sex; // 性别
  bool isAthleteMode = false; // 运动员模式
  bool isPregnantMode = false; // 孕妇模式


  PPDeviceUser({
    required this.userHeight,
    required this.age,
    required this.sex,
    required this.unitType,
    this.isAthleteMode = false,
    this.isPregnantMode = false,
  });

  factory PPDeviceUser.fromJson(Map<String, dynamic> json) {
    return PPDeviceUser(
      userHeight: json['userHeight'] ?? 0,
      age: json['age'] ?? 0,
      sex: PPUserGender.values[json['sex'] ?? 0],
      isAthleteMode: json['isAthleteMode'] ?? false,
      isPregnantMode: json['isPregnantMode'] ?? false,
      unitType:PPUnitType.values[json['unitType'] ?? 0],
    );
  }

  // 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'userHeight': userHeight,
      'age': age,
      'sex': sex.index, // 将枚举转换为整数
      'isAthleteMode': isAthleteMode,
      'isPregnantMode': isPregnantMode,
      'unitType': unitType,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
