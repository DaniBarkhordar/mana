

import 'package:pp_bluetooth_kit_flutter/enums/pp_scale_enums.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_user.dart';

class PPTorreUserModel extends PPDeviceUser {
  String userID; // userID
  String memberID; // 成员ID
  String userName; // 用户昵称
  int deviceHeaderIndex = 0; // 用户设备头像index

  int pIndex = 0; // Borre设备需要

  double currentWeight; // 当前体重
  double targetWeight; // 目标体重
  double idealWeight;  // 理想体重

  List<PPUserHistoryData> recentData = []; // 最近体重数据

  PPTorreUserModel({
    required super.userHeight, 
    required super.age, 
    required super.sex, 
    required super.unitType,
    super.isAthleteMode = false,
    super.isPregnantMode = false,
    required this.userID,
    required this.memberID,
    this.userName = "",
    this.deviceHeaderIndex = 0,
    required this.currentWeight,
    this.targetWeight = 0,
    this.idealWeight = 0,
    this.recentData = const [],
    this.pIndex = 0,

  });

  factory PPTorreUserModel.fromJson(Map<String, dynamic> json) {
    return PPTorreUserModel(
      userID: json['userID'] ?? '',
      memberID: json['memberID'] ?? '',
      userName: json['userName'] ?? '',
      deviceHeaderIndex: json['deviceHeaderIndex'] ?? 0,
      pIndex: json['pIndex'] ?? 0,
      currentWeight: json['currentWeight']?.toDouble() ?? 0.0,
      targetWeight: json['targetWeight']?.toDouble() ?? 0.0,
      idealWeight: json['idealWeight']?.toDouble() ?? 0.0,
      recentData: (json['recentData'] as List<dynamic>?)
          ?.map((e) => PPUserHistoryData.fromJson(e))
          .toList() ?? [],
      userHeight: json['userHeight'] ?? 0,
      age: json['age'] ?? 0,
      sex: PPUserGender.values[json['sex'] ?? 0],
      isAthleteMode: json['isAthleteMode'] ?? false,
      isPregnantMode: json['isPregnantMode'] ?? false,
      unitType:PPUnitType.values[json['unitType'] ?? 0],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'userID': userID,
      'memberID': memberID,
      'userName': userName,
      'deviceHeaderIndex': deviceHeaderIndex,
      'pIndex':pIndex,
      'currentWeight': currentWeight,
      'targetWeight': targetWeight,
      'idealWeight': idealWeight,
      'recentData': recentData.map((e) => e.toJson()).toList(),
      'userHeight': userHeight,
      'age': age,
      'sex': sex.index,
      'isAthleteMode': isAthleteMode,
      'isPregnantMode': isPregnantMode,
      'unitType': unitType.type,
    };
  }
}


class PPUserHistoryData {
  final double weightKg;
  final double timeStamp;

  PPUserHistoryData({
    required this.weightKg,
    required this.timeStamp,
  });

  factory PPUserHistoryData.fromJson(Map<String, dynamic> json) {
    return PPUserHistoryData(
      weightKg: json['weightKg']?.toDouble() ?? 0.0,
      timeStamp: json['timeStamp']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weightKg': weightKg,
      'timeStamp': timeStamp,
    };
  }
}