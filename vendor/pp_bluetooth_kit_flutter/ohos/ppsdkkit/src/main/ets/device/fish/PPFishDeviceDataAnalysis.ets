import { PPConfigWifiStateMenu } from '../../enums/PPConfigWifiStateMenu';
import { PPDeviceCalculateType } from '../../enums/PPDeviceEnums';
import { PPUnitType } from '../../enums/PPUnitType';
import { PPDataChangeListener } from '../../listener/PPDataChangeListener';
import { PPHistoryDataInterface } from '../../listener/PPHistoryDataInterface';
import { PPLogger } from '../../log/PPLogger';
import { ByteUtil } from '../../utils/ByteUtil';
import HexUtil from '../../utils/HexUtil';
import { ProtocolNormalDeviceHelper } from '../../utils/ProtocolNormalDeviceHelper';
import { PPBodyBaseModel } from '../../vo/PPBodyBaseModel';
import { PPDeviceModel } from '../../vo/PPDeviceModel';
import { PPScaleState, PPScaleStateHeartRateType, PPScaleStateImpedanceType,PPScaleStateMeasureResultType } from '../../../../../Index';


export class PPFishDeviceDataAnalysis {
  private _lastReceiveData: string = "";
  private lastTimes: number = 0;
  private lockWeightKg: number = 0.0;
  private lockImpedance: number = 0;
  private myWeightKgInt: number = 0;
  private myImpedance: number = 0;
  private impedance50: number = 0;
  private impedance100: number = 0;
  private heartRate: number = 0;
  private lastReceiveData: string = "";
  private lastReceiveData11: string = "";
  private ssidHex: Uint8Array = new Uint8Array(0);
  public dataChangeListener?: PPDataChangeListener | null;
  public historyDataInterface?: PPHistoryDataInterface;
  public monitorConfigResultCallback?: (sn: string | null, stateMenu: PPConfigWifiStateMenu | null) => void;
  public modifyServerDomainResultCallback?: (resultState: boolean) => void;
  public getWifiInfoCallback?: (ssid: string | null) => void;
  public onResetStateResultCallBack?: (resultState: boolean) => void;

  analysisData(data: Uint8Array, deviceModel: PPDeviceModel | null): void {
    if (data.length === 0) {
      return;
    }

    const bodyBaseModel = new PPBodyBaseModel();
    bodyBaseModel.deviceModel = deviceModel ?? undefined;

    // 获取前导字节（原substring(0,2) → 取第0个字节）
    const prefixByte = data[0];

    if (prefixByte == 0xca && data[5] == 0x00) {

      bodyBaseModel.isPlus = true
    } else {
      bodyBaseModel.isPlus = false
    }

    const weightInt = data[4] * 256 + data[3]

    if (weightInt == 65535) {
      bodyBaseModel.isOverload = true
    }

    bodyBaseModel.weight = weightInt

    bodyBaseModel.scaleState = new PPScaleState()

    if (data[9] == 0x00) {
      bodyBaseModel.scaleState!.measureResultType = PPScaleStateMeasureResultType.MEASURE_RESULT_FINISH
    }

    switch (data[8]) {
      case 0x00:
        bodyBaseModel.unit = PPUnitType.Unit_KG
        break

      case 0x01:
        bodyBaseModel.unit = PPUnitType.Unit_LB
        break

      case 0x02:
        bodyBaseModel.unit = PPUnitType.PPUnitST_LB
        break

      case 0x03:
        bodyBaseModel.unit = PPUnitType.PPUnitJin
        break

      case 0x04:
        bodyBaseModel.unit = PPUnitType.PPUnitG
        break

      case 0x05:
        bodyBaseModel.unit = PPUnitType.PPUnitLBOZ
        break

      case 0x06:
        bodyBaseModel.unit = PPUnitType.PPUnitOZ
        break

      case 0x07:
        bodyBaseModel.unit = PPUnitType.PPUnitMLWater
        break

      case 0x08:
        bodyBaseModel.unit = PPUnitType.PPUnitMLMilk
        break

      case 0x09:
        bodyBaseModel.unit = PPUnitType.PPUnitFL_OZ_WATER
        break

      case 0x0a:
        bodyBaseModel.unit = PPUnitType.PPUnitFL_OZ_MILK
        break

      case 0x0b:
        bodyBaseModel.unit = PPUnitType.PPUnitST
        break
    }

    this.dataChangeListener?.monitorProcessData?.(bodyBaseModel, deviceModel);
  }

  }