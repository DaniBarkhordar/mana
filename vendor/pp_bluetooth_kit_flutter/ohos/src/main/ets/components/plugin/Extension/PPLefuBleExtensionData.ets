import { Any, MethodResult } from '@ohos/flutter_ohos';
import { PPDeviceModel } from 'ppsdkkit/src/main/ets/vo/PPDeviceModel';
import { PPWifiModel } from 'ppsdkkit/src/main/ets/vo/PPWifiModel';
import { PPBodyBaseModel } from 'ppsdkkit/src/main/ets/vo/PPBodyBaseModel';
import { PPLefuBleConnectManager } from '../PPLefuBleConnectManager';
import { PPLefuStreamHandler } from '../PPLefuStreamHandler';
import { PPUnitType } from 'ppsdkkit/src/main/ets/enums/PPUnitType';
import { PPScaleStatePowerType } from 'ppsdkkit/src/main/ets/enums/PPScaleState';
import { PPBluetoothKit } from 'ppsdkkit';
import { DeviceConfigVo } from 'ppsdkkit/src/main/ets/vo/DeviceConfigVo';

export class PPLefuBleExtensionData {
  static convertDeviceDict(device: PPDeviceModel | null): DeviceDict {

    const deviceConfig = PPLefuBleExtensionData.getDeviceConfigVo(device?.deviceSettingId);


    return {
      deviceSettingId: device?.deviceSettingId ?? 0,
      deviceMac: device?.deviceMac ?? "",
      deviceName: device?.deviceName ?? "",
      devicePower: device?.devicePower ?? -1,
      rssi: device?.rssi ?? 0,
      deviceType: device?.deviceType ?? 0,
      deviceProtocolType: device?.deviceProtocolType ?? 0,
      deviceCalculateType: device?.deviceCalculateType ?? 0,
      deviceAccuracyType: device?.deviceAccuracyType ?? 0,
      devicePowerType: device?.devicePowerType ?? 0,
      deviceConnectType: device?.deviceConnectType ?? 0,
      deviceFuncType: device?.deviceFuncType ?? 0,
      deviceUnitType: device?.deviceUnitType ?? "",
      peripheralType: device?.getDevicePeripheralType().valueOf() ?? 0,
      sign: device?.sign ?? "",
      advLength: device?.advLength ?? 0,
      macAddressStart: device?.macAddressStart ?? 0,
      standardType: device?.standardType ?? 0,
      productModel: device?.productModel ?? "",
      imgUrl: deviceConfig?.imgUrl ?? "",
      avatarType: deviceConfig?.avatarType ?? 0,
      brandId:deviceConfig?.brandId ?? 0,
      modelNumber: device?.modelNumber ?? "",
      firmwareRevision: device?.firmwareVersion ?? "",
      softwareRevision: device?.softwareVersion ?? "",
      hardwareRevision: device?.hardwareVersion ?? "",
      serialNumber: device?.serialNumber ?? "",
      manufacturerName: device?.manufacturerName ?? "",

    };
  }


  static getDeviceConfigVo(settingId?: number): DeviceConfigVo | null {
    return PPBluetoothKit.deviceConfigVos?.find(deviceConfig => deviceConfig.id === settingId) ?? null;
  }


  static convertMeasurementDict(model: PPBodyBaseModel): MeasurementDict {

    let isPowerOff = false;

    if (model.scaleState) {
      if (model.scaleState?.powerType == PPScaleStatePowerType.POWER_ON) {
        isPowerOff = true
      }
    }

    const dict: MeasurementDict = {
      weight: model.weight ?? 0,
      impedance: model.impedance ?? 0,
      impedance100EnCode: model.ppImpedance100EnCode ?? 0,
      isHeartRating: model.isHeartRating ?? false,
      heartRate: model.heartRate ?? 0,
      isOverload: model.isOverload ?? false,
      isPlus: model.isPlus ?? false,
      measureTime: model.measureTime ?? 0,
      memberId: model.memberId ?? "",
      footLen: model.footLen ?? 0,
      unit: model.unit?.type ?? PPUnitType.Unit_KG.type,
      z100KhzLeftArmEnCode: model.z100KhzLeftArmEnCode ?? 0,
      z100KhzLeftLegEnCode: model.z100KhzLeftLegEnCode ?? 0,
      z100KhzRightArmEnCode: model.z100KhzRightArmEnCode ?? 0,
      z100KhzRightLegEnCode: model.z100KhzRightLegEnCode ?? 0,
      z100KhzTrunkEnCode: model.z100KhzTrunkEnCode ?? 0,
      z20KhzLeftArmEnCode: model.z20KhzLeftArmEnCode ?? 0,
      z20KhzLeftLegEnCode: model.z20KhzLeftLegEnCode ?? 0,
      z20KhzRightArmEnCode: model.z20KhzRightArmEnCode ?? 0,
      z20KhzRightLegEnCode: model.z20KhzRightLegEnCode ?? 0,
      z20KhzTrunkEnCode: model.z20KhzTrunkEnCode ?? 0,
      isPowerOff: isPowerOff ?? false,
      hasLightStrength: model.hasLightStrength ?? false,
      lightStrength: model.lightStrength ?? -1
    };

    return dict;
  }

  static sendMeasureData(model: PPBodyBaseModel | null, advModel: PPDeviceModel | null, measureState: number): Any {
    const deviceDict = PPLefuBleExtensionData.convertDeviceDict(advModel);
    if (model) {
      const dataDict = PPLefuBleExtensionData.convertMeasurementDict(model);
      return {
        measurementState: measureState,
        device: deviceDict,
        data: dataDict
      };
    } else {
      return {
        measurementState: measureState,
        device: deviceDict,
        data: null
      };
    }
  }

  static sendHistoryData(models: PPBodyBaseModel[]): MeasurementDict[] {
    const dataList = models.map(model => PPLefuBleExtensionData.convertMeasurementDict(model));
    return dataList;
  }
}


export interface MeasureDataDict {
  measurementState: number,
  device: DeviceDict,
  data: MeasurementDict
}

export interface MeasurementDict {
  weight: number;
  impedance: number;
  impedance100EnCode: number;
  isHeartRating: boolean;
  heartRate: number;
  isOverload: boolean;
  isPlus: boolean;
  measureTime: number;
  memberId: string;
  footLen: number;
  unit: number;
  z100KhzLeftArmEnCode: number;
  z100KhzLeftLegEnCode: number;
  z100KhzRightArmEnCode: number;
  z100KhzRightLegEnCode: number;
  z100KhzTrunkEnCode: number;
  z20KhzLeftArmEnCode: number;
  z20KhzLeftLegEnCode: number;
  z20KhzRightArmEnCode: number;
  z20KhzRightLegEnCode: number;
  z20KhzTrunkEnCode: number;
  isPowerOff: boolean;
  hasLightStrength: boolean;
  lightStrength: number;
}


export interface DeviceDict {
  deviceSettingId: number;
  deviceMac: string;
  deviceName: string;
  devicePower: number;
  rssi: number;
  deviceType: number;
  deviceProtocolType: number;
  deviceCalculateType: number;
  deviceAccuracyType: number;
  devicePowerType: number;
  deviceConnectType: number;
  deviceFuncType: number;
  deviceUnitType: string;
  peripheralType: number;
  sign: string;
  advLength: number;
  macAddressStart: number;
  standardType: number;
  productModel: string;
  imgUrl: string;
  avatarType: number;
  brandId: number;
  modelNumber: string;
  firmwareRevision: string;
  softwareRevision: string;
  hardwareRevision: string;
  serialNumber: string;
  manufacturerName: string;
}