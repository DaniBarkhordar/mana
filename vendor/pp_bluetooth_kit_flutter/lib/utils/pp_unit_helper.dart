
import 'package:pp_bluetooth_kit_flutter/channel/pp_bluetooth_kit_flutter_platform_interface.dart';
import 'package:pp_bluetooth_kit_flutter/enums/pp_scale_enums.dart';

class PPUnitHelper {

  /// 食物秤单位转换
  /// weightG 重量（g）
  /// accuracyType 精度
  /// unitType 需要转的 单位
  /// deviceName 蓝牙名称
  static Future<String> foodScaleUnit(double weightG, PPDeviceAccuracyType accuracyType, PPUnitType unitType, String deviceName) {
    return PPBluetoothKitFlutterPlatform.instance.foodScaleUnit(weightG, accuracyType, unitType, deviceName);
  }

  /// 食物秤单位转换-带单位后缀
  /// weightG 重量（g）
  /// accuracyType 精度
  /// unitType 需要转的 单位
  /// deviceName 蓝牙名称
  static Future<String> foodScaleUnitWithSuffix(double weightG, PPDeviceAccuracyType accuracyType, PPUnitType unitType, String deviceName) async {

    final ret = await PPBluetoothKitFlutterPlatform.instance.foodScaleUnit(weightG, accuracyType, unitType, deviceName);
    var unitStr = "g";
    if(unitType == PPUnitType.UnitOZ){
      unitStr = "oz";
    } else if(unitType == PPUnitType.UnitMLMilk){
      unitStr = "ml(milk)";
    }else if(unitType == PPUnitType.UnitMLWater){
      unitStr = "ml(water)";
    }else if(unitType == PPUnitType.UnitFL_OZ_WATER){
      unitStr = "fl.oz(water)";
    }else if(unitType == PPUnitType.UnitFL_OZ_MILK){
      unitStr = "fl.oz(milk)";
    }else if(unitType == PPUnitType.UnitLBOZ){
      unitStr = "lb:oz";
    }else if(unitType == PPUnitType.Unit_LB){
      unitStr = "lb";
    }
    return "$ret$unitStr";
  }

}