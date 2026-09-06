import { PPConfigWifiStateMenu } from '../../enums/PPConfigWifiStateMenu';
import { PPDeviceCalculateType } from '../../enums/PPDeviceEnums';
import { PPDataChangeListener } from '../../listener/PPDataChangeListener';
import { PPHistoryDataInterface } from '../../listener/PPHistoryDataInterface';
import { PPLogger } from '../../log/PPLogger';
import { ByteUtil } from '../../utils/ByteUtil';
import HexUtil from '../../utils/HexUtil';
import { ProtocolNormalDeviceHelper } from '../../utils/ProtocolNormalDeviceHelper';
import { PPBodyBaseModel } from '../../vo/PPBodyBaseModel';
import { PPDeviceModel } from '../../vo/PPDeviceModel';
import {
  PPScaleState,
  PPScaleStateCaptureZeroType,
  PPScaleStateHeartRateType,
  PPScaleStateImpedanceType,
  PPScaleStateMeasureModeType,
  PPScaleStateMeasureResultType,
  PPScaleStatePowerType,
  PPScaleStateWeightType
} from "../../enums/PPScaleState";
import { PPUnitType } from '../../enums/PPUnitType';

export class PPHamburgerDeviceDataAnalysis {
  private _lastReceiveData: string = "";
  private lastTimes: number = 0;
  public dataChangeListener?: PPDataChangeListener | null;
  public historyDataInterface?: PPHistoryDataInterface;
  public monitorConfigResultCallback?: (sn: string | null, stateMenu: PPConfigWifiStateMenu | null) => void;
  public modifyServerDomainResultCallback?: (resultState: boolean) => void;
  public getWifiInfoCallback?: (ssid: string | null) => void;
  public monitorResetStateResultCallback?: (resultState: boolean) => void;

  analysisData(data: Uint8Array, deviceModel: PPDeviceModel | null): void {
    if (data.length === 0) {
      return;
    }

    // 1. 字节数组转字符串
    const receiveData = HexUtil.formatHexString(data);
    PPLogger.i(`analysisData data:${receiveData}`);

    // 2. 过滤重复数据（2.5秒内相同数据视为重复）
    if (this._lastReceiveData !== receiveData || Date.now() - this.lastTimes > 2500) {
      this.lastTimes = Date.now();
      this._lastReceiveData = receiveData;

      // 3. 根据指令头进行分支处理
      if (receiveData.length === 22) {
        // 22字节体脂数据
        this.analyticalDataFatV2(data, deviceModel);
      }
    }
  }

  analyticalDataFatV2(data: Uint8Array, deviceModel: PPDeviceModel | null): void {
    if (data.length < 2) {
      return;
    }

    const bodyBaseModel = new PPBodyBaseModel();
    bodyBaseModel.deviceModel = deviceModel ?? undefined;

    // 获取前导字节（原substring(0,2) → 取第0个字节）
    const prefixByte = data[0];

    if(prefixByte == 0xca && data[5] == 0x00){

      bodyBaseModel.isPlus = true
    }else{
      bodyBaseModel.isPlus = false
    }

    const weightInt = data[4]*256 + data[3]

    if (weightInt == 65535) {
      bodyBaseModel.isOverload = true
    }

    bodyBaseModel.weight = weightInt

    bodyBaseModel.scaleState = new PPScaleState()

    if (data[9] == 0x00) {
      bodyBaseModel.scaleState!.measureResultType = PPScaleStateMeasureResultType.MEASURE_RESULT_FINISH
    }

    switch (data[8]){
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