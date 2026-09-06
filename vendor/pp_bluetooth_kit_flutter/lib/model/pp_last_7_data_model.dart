import 'dart:convert';

import 'package:pp_bluetooth_kit_flutter/enums/pp_scale_enums.dart';

class PPLast7DataModel {
  int lastBMI; //传放大 100倍的值
  int lastMuscleRate; //传放大 100倍的值
  int lastWaterRate; //传放大 100倍的值
  int lastBodyFat; //传放大 100倍的值
  int lastBoneRate; //传放大 100倍的值
  int lastMuscle; //传放大 100倍的值
  int lastBone; //传放大 100倍的值
  int lastHeartRate; //传放大 10倍的值

  String userID;
  String memberID;
  double targetWeight; // 目标体重，kg
  double idealWeight; // 理想体重，kg
  PPLast7DataType type;
  double value;

  List<PPRecentData> weightList;

  PPLast7DataModel(
      {this.lastBMI = 0,
      this.lastMuscleRate = 0,
      this.lastWaterRate = 0,
      this.lastBodyFat = 0,
      this.lastHeartRate = 0,
      this.lastMuscle = 0,
      this.lastBone = 0,
      this.lastBoneRate = 0,
      this.userID = '',
      this.memberID = '',
      this.targetWeight = 0.0,
      this.idealWeight = 0.0,
      this.type = PPLast7DataType.weight,
      this.weightList = const [],
      this.value = 0});

  factory PPLast7DataModel.fromJson(Map<String, dynamic> json) {
    return PPLast7DataModel(
      lastBMI: json['lastBMI']?.toDouble() ?? 0.0,
      lastMuscleRate: json['lastMuscleRate']?.toDouble() ?? 0.0,
      lastWaterRate: json['lastWaterRate']?.toDouble() ?? 0.0,
      lastBodyFat: json['lastBodyFat']?.toDouble() ?? 0.0,
      lastHeartRate: json['lastHeartRate']?.toDouble() ?? 0.0,
      lastMuscle: json['lastMuscle']?.toDouble() ?? 0.0,
      lastBone: json['lastBone']?.toDouble() ?? 0.0,
      lastBoneRate: json['lastBoneRate']?.toDouble() ?? 0.0,
      userID: json['userID']?.toString() ?? '',
      memberID: json['memberID']?.toString() ?? '',
      targetWeight: json['targetWeight']?.toDouble() ?? 0.0,
      idealWeight: json['idealWeight']?.toDouble() ?? 0.0,
      value: json['value']?.toDouble() ?? 0.0,
      type: PPLast7DataType.fromInt(json['type']?.toInt() ?? 0),
      weightList: (json['weightList'] as List<dynamic>?)
              ?.map((e) => PPRecentData.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'lastBMI': lastBMI,
        'lastMuscleRate': lastMuscleRate,
        'lastWaterRate': lastWaterRate,
        'lastBodyFat': lastBodyFat,
        'lastHeartRate': lastHeartRate,
        'lastMuscle': lastMuscle,
        'lastBone': lastBone,
        'lastBoneRate': lastBoneRate,
        'userID': userID,
        'memberID': memberID,
        'targetWeight': targetWeight,
        'idealWeight': idealWeight,
        'type': type.value,
        'weightList': weightList.map((e) => e.toJson()).toList(),
        'value': value,
      };

  @override
  String toString() {
    return 'PPLast7DataModel: ${jsonEncode(this)}';
  }
}

class PPRecentData {
  int timeStamp = 0;
  double value = 0; // 数值（如体重、BMI等）,放大100倍

  PPRecentData({
    this.timeStamp = 0,
    this.value = 0,
  });

  factory PPRecentData.fromJson(Map<String, dynamic> json) {
    return PPRecentData(
      timeStamp: json['timeStamp']?.toInt() ?? 0,
      value: json['value']?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'timeStamp': timeStamp,
        'value': value,
      };
}
