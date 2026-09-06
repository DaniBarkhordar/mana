import { PPLefuStreamHandler } from './PPLefuStreamHandler';
import bluetooth from '@ohos.bluetooth';
import { access, ble, constant } from '@kit.ConnectivityKit';
import { AbilityPluginBinding, MethodResult } from '@ohos/flutter_ohos';
import { PPLefuBleExtensionData, DeviceDict } from './Extension/PPLefuBleExtensionData';
import { PPLoggerPluginOhos } from './util/PPLoggerPluginOhos';

import { PPBluetoothKit } from 'ppsdkkit/src/main/ets/PPBluetoothKit';
import { PPDeviceModel } from 'ppsdkkit/src/main/ets/vo/PPDeviceModel';
import { PPDevicePeripheralType,PPUserBodyDataType,PPDisplayMetrics } from 'ppsdkkit/src/main/ets/enums/PPDeviceEnums';
import { PPBleSearch } from 'ppsdkkit/src/main/ets/ble/search/PPBleSearch';
import { PPBaseDeviceControl } from 'ppsdkkit/src/main/ets/device/PPBaseDeviceControl';
import { PPAppleDeviceControl } from 'ppsdkkit/src/main/ets/device/apple/PPAppleDeviceControl';
import { PPIceDeviceControl } from 'ppsdkkit/src/main/ets/device/ice/PPIceDeviceControl';
import { PPBananaDeviceControl } from 'ppsdkkit/src/main/ets/device/banana/PPBananaDeviceControl';
import { PPCoconutDeviceControl } from 'ppsdkkit/src/main/ets/device/coconut/PPCoconutDeviceControl';
import { PPJambulDeviceControl } from 'ppsdkkit/src/main/ets/device/jambul/PPJambulDeviceControl';
import { PPTorreDeviceControl } from 'ppsdkkit/src/main/ets/device/torre/PPTorreDeviceControl';
import { PPBorreDeviceControl } from 'ppsdkkit/src/main/ets/device/borre/PPBorreDeviceControl';
import { PPFishDeviceControl } from 'ppsdkkit/src/main/ets/device/fish/PPFishDeviceControl';
import { PPHamburgerDeviceControl } from 'ppsdkkit/src/main/ets/device/hamburger/PPHamburgerDeviceControl';
import { PPGrapesDeviceControl } from 'ppsdkkit/src/main/ets/device/grapes/PPGrapesDeviceControl';
import { PPEggDeviceControl } from 'ppsdkkit/src/main/ets/device/egg/PPEggDeviceControl';

import { PPUserRecentBodyData } from 'ppsdkkit/src/main/ets/vo/PPUserRecentBodyData';
import { PPScaleHelper } from 'ppsdkkit/src/main/ets/utils/PPScaleHelper'

import { PPUserModel } from 'ppsdkkit/src/main/ets/vo/PPUserModel';

import { abilityAccessCtrl, bundleManager, Permissions, common, Context, featureAbility, UIAbility } from '@kit.AbilityKit';
import { BusinessError, systemDateTime } from '@kit.BasicServicesKit';
import {
  PPBodyBaseModel,
  PPConfigWifiStateMenu,
  PPDataChangeListener,
  PPHistoryDataInterface,
  PPScaleStateHeartRateType,
  PPScaleStateMeasureResultType,
  PPScaleStateImpedanceType,
  PPWifiModel,
  TimeFormat,
  UnitUtil
} from 'ppsdkkit';

enum PPLefuScanType {
  SCAN = 0
}

export class PPLefuBleConnectManager {
  scanResultStreamHandler: PPLefuStreamHandler | null = null;
  loggerStreamHandler: PPLefuStreamHandler | null = null;
  connectStateStreamHandler: PPLefuStreamHandler | null = null;
  measureStreamHandler: PPLefuStreamHandler | null = null;
  historyStreamHandler: PPLefuStreamHandler | null = null;
  batteryStreamHandler: PPLefuStreamHandler | null = null;
  blePermissionStreamHandler: PPLefuStreamHandler | null = null;
  dfuStreamHandler: PPLefuStreamHandler | null = null;
  deviceLogStreamHandler: PPLefuStreamHandler | null = null;
  scanStateStreamHandler: PPLefuStreamHandler | null = null;
  kitchenStreamHandler: PPLefuStreamHandler | null = null;

  private bluetoothState: bluetooth.BluetoothState | null = null;
  private needScan: boolean = false;
  private scanType: PPLefuScanType = PPLefuScanType.SCAN;
  private isScaning: boolean = false;
  private connectState: number = 0;
  deviceControl: PPBaseDeviceControl | null = null;
  currentDevice: PPDeviceModel | null = null;
  deviceModels: Map<String, PPDeviceModel> = new Map();
  private abilityPluginBinding: AbilityPluginBinding | null = null;
  historyModels: PPBodyBaseModel[] = [];

  constructor() {
    // 初始化蓝牙管理器
    this.initBluetooth();
  }

  private initBluetooth(): void {
    // 监听蓝牙状态变化
    PPBluetoothKit.addBleStateListener((state: number) => {
      this.onBluetoothStateChange(state);
    })
  }

  private onBluetoothStateChange(state: bluetooth.BluetoothState): void {
    if (this.bluetoothState !== state) {
      this.sendBlePermissionState(state);
    }

    this.bluetoothState = state;
    this.loggerStreamHandler?.success(`蓝牙状态:${state}`);

    if (this.needScan && access.BluetoothState.STATE_ON === state || access.BluetoothState.STATE_BLE_ON) {
      this.needScan = false;
      this.sendBlePermissionState(2)
    } else if (state === access.BluetoothState.STATE_OFF) {
      this.needScan = false;
      this.sendBlePermissionState(3)
      if (this.isScaning) {

        this.addLog(`onBluetoothStateChange stopScan`)

        this.stopScan();
      }
    }
  }

  onAttachedToAbility(binding: AbilityPluginBinding) {
    this.abilityPluginBinding = binding;
  }

  async checkPermission(): Promise<void> {
    this.addLog('checkPermission')
    let checkPermission: Permissions = "ohos.permission.ACCESS_BLUETOOTH";
    let isPermission: boolean = await this.checkSelfPermission(checkPermission);
    this.addLog(`checkPermission isPermission:${isPermission}`)
    if (isPermission) {
      if (this.isAdapterOn()) {
        this.addLog(`checkPermission 蓝牙可以使用`)
      } else {
        this.addLog(`checkPermission 蓝牙开关未打开`)
      }
    } else {
      let permissions = new Array<Permissions>();
      permissions.push("ohos.permission.ACCESS_BLUETOOTH");
      await this.ensurePermissions(permissions);
    }
  }

  isAdapterOn(): boolean {
    try {
      return access.getState() == access.BluetoothState.STATE_ON;
    } catch (e) {
      this.addLog(`蓝牙开关检测异常 ${e}`);
      return false;
    }
  }

  async checkSelfPermission(permission: Permissions): Promise<boolean> {
    PPLoggerPluginOhos.i("checkSelfPermission");
    let tokenId: number = 0;
    let grantStatus: abilityAccessCtrl.GrantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    let bundleInfo: bundleManager.BundleInfo =
      await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
    let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
    tokenId = appInfo.accessTokenId;
    grantStatus = await atManager.checkAccessToken(tokenId, permission);
    PPLoggerPluginOhos.i(`checkSelfPermission grantStatus：${grantStatus}`);
    return grantStatus != -1;
  }

  async ensurePermissions(permissions: Permissions[]) {
    let permissionsNeeded = new Array<Permissions>();
    for (const permission of permissions) {
      let flag = await this.checkSelfPermission(permission);
      if (permission != null && !flag) {
        permissionsNeeded.push(permission);
      }
    }
    if (permissionsNeeded.length == 0 || permissionsNeeded == null) {
      // result.success(true);
      this.addLog(`ensurePermissions permissions is null`)
      return;
    }

    const c: UIAbility | null = this.abilityPluginBinding?.getAbility() ?? null;
    let context = c?.context;

    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();

    // requestPermissionsFromUser会判断权限的授权状态来决定是否唤起弹窗
    atManager.requestPermissionsFromUser(context, permissionsNeeded).then(async (data) => {
      let grantStatus: Array<number> = data.authResults;
      let length: number = grantStatus.length;
      // for (let i = 0; i < length; i++) {
      //   if (grantStatus[i] === 0) {
      //     this.addLog(`拿到蓝牙权限`);
      //   } else {
      //     // 用户拒绝授权，提示用户必须授权才能访问当前页面的功能，并引导用户到系统设置中打开相应的权限
      //     this.addLog(`用户拒绝授权，提示用户必须授权才能访问当前页面的功能，并引导用户到系统设置中打开相应的权限`);
      //   }
      // }

      let checkPermission: Permissions = "ohos.permission.ACCESS_BLUETOOTH";
      let isPermission: boolean = await this.checkSelfPermission(checkPermission);
      this.addLog(`addBlePermissionListener isPermission:${isPermission}`)
      if (isPermission) {
        this.addLog(`拿到蓝牙权限`);
        // 授权成功
        if (this.isAdapterOn()) {
          this.addLog('addBlePermissionListener 蓝牙可以使用');
          this.sendBlePermissionState(2);
        } else {
          this.addLog('addBlePermissionListener 蓝牙开关未打开');
          this.sendBlePermissionState(3);
        }
      } else {
        this.addLog(`用户拒绝授权，提示用户必须授权才能访问当前页面的功能，并引导用户到系统设置中打开相应的权限`);
        this.sendBlePermissionState(1);
      }
    }).catch((err: BusinessError) => {
      this.addLog(`蓝牙权限获取失败 Code is ${err.code}, message is ${err.message}`);
    })
  }

  startScan(result: MethodResult): void {

    this.addLog('设备startScane')

    this.stopScan();
    this.disconnect();
    this.isScaning = true;
    this.scanType = PPLefuScanType.SCAN;

    this.sendScanState(true);
    this.addLog('startScan --------------------')
    PPBleSearch.getInstance().startScan((deviceModel: PPDeviceModel) => {
      this.addLog(`wwz startScan deviceName:${deviceModel.deviceName} deviceMac:${deviceModel.deviceMac}`)
      if (!deviceModel.deviceMac) {
        return;
      }

      if (deviceModel) {
        this.deviceModels[deviceModel.deviceMac] = deviceModel;
        if (this.scanType === PPLefuScanType.SCAN) {
          PPLoggerPluginOhos.d(`wwz startScan findDevice deviceName:${deviceModel.deviceName} deviceMac:${deviceModel.deviceMac}`);
          let deviceDict: DeviceDict = PPLefuBleExtensionData.convertDeviceDict(deviceModel);
          PPLoggerPluginOhos.d(`wwz startScan findDevice deviceDict:${deviceDict} deviceName:${deviceDict.deviceName} deviceMac:${deviceDict.deviceMac}`);
          // 转换设备信息为统一格式
          this.scanResultStreamHandler?.success(deviceDict);
        }
      }
    });
    this.sendCommonState(true, result)
  }

  stopScan(): void {
    this.addLog('停止扫描')
    PPBleSearch.getInstance().stopScan();
    if (this.isScaning) {
      this.isScaning = false;
      this.sendScanState(false);
    }
  }

  connectDevice(deviceMac: string) {

    this.addLog('设备connectDevice')

    let deviceModel: PPDeviceModel = this.deviceModels[deviceMac];
    if (!deviceModel) {
      this.addLog(`设备${deviceMac}未找到，请先搜索设备`)
      this.sendConnectState(2);
    } else {

      this.addLog(`connectDevice stopScan`)

      this.stopScan();
      if (this.deviceControl) {
        if (this.deviceControl.deviceModel?.deviceMac === deviceMac) {
          if (this.deviceControl.isConnect()) {
            this.addLog('设备已连接,无需重复连接')
            // this.sendConnectState(1);
          } else {
            this.startConnectDevice();
          }
        } else {
          this.addLog('其他设备连接，先断开,再连接')
          this.disconnect();
          this.createDeviceControl(deviceModel);
          this.startConnectDevice();
        }
      } else {
        this.createDeviceControl(deviceModel);
        this.startConnectDevice();
      }
    }
  }

  receiveBroadcastData(deviceMac: string, result: MethodResult): void {
    this.addLog(`设备receiveBroadcastData 启动数据监听 deviceMac:${deviceMac}`)
    let deviceModel: PPDeviceModel = this.deviceModels[deviceMac];
    if (!deviceModel) {
      this.addLog(`设备${deviceMac}未找到，请先搜索设备`)
      this.sendConnectState(2);
    } else {
      this.createDeviceControl(deviceModel);

      if (this.deviceControl) {

        this.addLog(`设备0${deviceMac}`)

        if (this.deviceControl.deviceModel?.deviceMac === deviceMac) {
          this.addLog(`设备1${deviceMac}`)


          if (this.deviceControl instanceof PPBananaDeviceControl) {
            const deviceControlBanan = this.deviceControl as PPBananaDeviceControl;
            this.addLog(`设备2${deviceMac}`)

            deviceControlBanan.startSearch()


          }

          if (this.deviceControl instanceof PPHamburgerDeviceControl) {
            const deviceControlHamburger = this.deviceControl as PPHamburgerDeviceControl;

            deviceControlHamburger.startSearch()


          }

          if (this.deviceControl instanceof PPJambulDeviceControl) {
            const deviceControlJambul = this.deviceControl as PPJambulDeviceControl;
            deviceControlJambul.startSearch()
          }

          if (this.deviceControl instanceof PPGrapesDeviceControl) {
            const deviceControlGrapes = this.deviceControl as PPGrapesDeviceControl;
            deviceControlGrapes.startSearch()
          }
        }

      }
    }
  }

  unReceiveBroadcastData(deviceMac: string, result: MethodResult): void {

    this.addLog(`设备unReceiveBroadcastData 取消广播秤数据监听 deviceMac:${deviceMac}`)
    let deviceModel: PPDeviceModel = this.deviceModels[deviceMac];
    if (deviceModel) {
      if (this.deviceControl) {
        this.unRegisterDataChangeListener();
        if (this.deviceControl.deviceModel?.deviceMac === deviceMac) {
          if (this.deviceControl instanceof PPBananaDeviceControl) {
            this.addLog(`设备 banana${deviceMac}`)
            const deviceControlBanan = this.deviceControl as PPBananaDeviceControl;
            deviceControlBanan.stopSearch()

          } else if (this.deviceControl instanceof PPHamburgerDeviceControl) {

            const deviceControlHamburger = this.deviceControl as PPHamburgerDeviceControl;
            deviceControlHamburger.stopSearch()
          } else if (this.deviceControl instanceof PPJambulDeviceControl) {
            this.addLog(`设备 jambul${deviceMac}`)
            const deviceControlJambul = this.deviceControl as PPJambulDeviceControl;
            deviceControlJambul.stopSearch()
          } else if (this.deviceControl instanceof PPGrapesDeviceControl) {
            this.addLog(`设备 grapes${deviceMac}`)
            const deviceControlGrapes = this.deviceControl as PPGrapesDeviceControl;
            deviceControlGrapes.stopSearch()
          }
        }
      }
    }

  }

  private createDeviceControl(deviceModel: PPDeviceModel) {
    switch (deviceModel.getDevicePeripheralType()) {
      case PPDevicePeripheralType.PeripheralApple:
        this.deviceControl = new PPAppleDeviceControl(deviceModel);
        break;
      case PPDevicePeripheralType.PeripheralIce:
        this.deviceControl = new PPIceDeviceControl(deviceModel);
        break;
      case PPDevicePeripheralType.PeripheralBanana:
        this.deviceControl = new PPBananaDeviceControl(deviceModel);
        break;
      case PPDevicePeripheralType.PeripheralHamburger:
        this.deviceControl = new PPHamburgerDeviceControl(deviceModel);
        break;
      case PPDevicePeripheralType.PeripheralCoconut:
        this.deviceControl = new PPCoconutDeviceControl(deviceModel);
        break;
      case PPDevicePeripheralType.PeripheralJambul:
        this.deviceControl = new PPJambulDeviceControl(deviceModel);
        break;
      case PPDevicePeripheralType.PeripheralTorre:
        this.deviceControl = new PPTorreDeviceControl(deviceModel);
        break;
      case PPDevicePeripheralType.PeripheralBorre:
        this.deviceControl = new PPBorreDeviceControl(deviceModel);
        break;
      case PPDevicePeripheralType.PeripheralFish:
        this.deviceControl = new PPFishDeviceControl(deviceModel);
        break;
      case PPDevicePeripheralType.PeripheralGrapes:
        this.deviceControl = new PPGrapesDeviceControl(deviceModel);
        break;
      case PPDevicePeripheralType.PeripheralEgg:
        this.deviceControl = new PPEggDeviceControl(deviceModel);
        break;
      default:
        this.addLog(`不支持的设备类型:${deviceModel.getDevicePeripheralType()}`);
        break;
    }
    this.registerDataChangeListener();
  }

  private registerDataChangeListener() {
    if (this.deviceControl instanceof PPAppleDeviceControl) {
      this.deviceControl.registerDataChangeListener(this.dataChangeListener)
    } else if (this.deviceControl instanceof PPTorreDeviceControl) {
      this.deviceControl.registerDataChangeListener(this.dataChangeListener)
    } else if (this.deviceControl instanceof PPBorreDeviceControl) {
      this.deviceControl.registerDataChangeListener(this.dataChangeListener)
    } else if (this.deviceControl instanceof PPIceDeviceControl) {
      this.deviceControl.registerDataChangeListener(this.dataChangeListener)
    } else if (this.deviceControl instanceof PPBananaDeviceControl) {
      this.deviceControl.registerDataChangeListener(this.dataChangeListener)
    } else if (this.deviceControl instanceof PPJambulDeviceControl) {
      this.deviceControl.registerDataChangeListener(this.dataChangeListener)
    } else if (this.deviceControl instanceof PPCoconutDeviceControl) {
      this.deviceControl.registerDataChangeListener(this.dataChangeListener)
    } else if (this.deviceControl instanceof PPFishDeviceControl) {
      this.deviceControl.registerDataChangeListener(this.dataChangeListener)
    } else if (this.deviceControl instanceof PPHamburgerDeviceControl) {
      this.deviceControl.registerDataChangeListener(this.dataChangeListener)

    } else if (this.deviceControl instanceof PPGrapesDeviceControl) {
      this.deviceControl.registerDataChangeListener(this.dataChangeListener)

    } else if (this.deviceControl instanceof PPEggDeviceControl) {
      this.deviceControl.registerDataChangeListener(this.dataChangeListener)

    }
  }

  private unRegisterDataChangeListener() {
    if (!this.deviceControl) {
      return
    }
    if (this.deviceControl instanceof PPAppleDeviceControl) {
      this.deviceControl.unRegisterDataChangeListener()
    } else if (this.deviceControl instanceof PPTorreDeviceControl) {
      this.deviceControl.unRegisterDataChangeListener()
    } else if (this.deviceControl instanceof PPBorreDeviceControl) {
      this.deviceControl.unRegisterDataChangeListener()
    } else if (this.deviceControl instanceof PPIceDeviceControl) {
      this.deviceControl.unRegisterDataChangeListener()
    } else if (this.deviceControl instanceof PPBananaDeviceControl) {
      this.deviceControl.unRegisterDataChangeListener()
    } else if (this.deviceControl instanceof PPJambulDeviceControl) {
      this.deviceControl.unRegisterDataChangeListener()
    } else if (this.deviceControl instanceof PPCoconutDeviceControl) {
      this.deviceControl.unRegisterDataChangeListener()
    } else if (this.deviceControl instanceof PPFishDeviceControl) {
      this.deviceControl.unRegisterDataChangeListener()
    } else if (this.deviceControl instanceof PPHamburgerDeviceControl) {
      this.deviceControl.unRegisterDataChangeListener()

    } else if (this.deviceControl instanceof PPGrapesDeviceControl) {
      this.deviceControl.unRegisterDataChangeListener()

    } else if (this.deviceControl instanceof PPEggDeviceControl) {
      this.deviceControl.unRegisterDataChangeListener()

    }
  }

  dataChangeListener: PPDataChangeListener = {

    monitorProcessData: (bodyBaseModel: PPBodyBaseModel | null, deviceModel: PPDeviceModel | null) => {
      this.addLog(`实时数据:${bodyBaseModel?.getPpWeightKg()}`)
      const scaleState = bodyBaseModel?.scaleState

      if(deviceModel?.deviceType === 1 || deviceModel?.deviceType === 2){
        if (scaleState?.heartRateType === PPScaleStateHeartRateType.HEARTRATE_MEASURING) {
          this.addLog(`心率测量中 monitorProcessData`)
          this.measureStreamHandler?.success(PPLefuBleExtensionData.sendMeasureData(bodyBaseModel, deviceModel, 2));
        } else if (scaleState?.impedanceType === PPScaleStateImpedanceType.IMPEDANCE_MEASURING) {
          this.measureStreamHandler?.success(PPLefuBleExtensionData.sendMeasureData(bodyBaseModel, deviceModel, 1));
        } else {
          this.measureStreamHandler?.success(PPLefuBleExtensionData.sendMeasureData(bodyBaseModel, deviceModel, 0));
        }
      }else{
        if(scaleState?.measureResultType ==  PPScaleStateMeasureResultType.MEASURE_RESULT_FINISH){
          this.kitchenStreamHandler?.success(PPLefuBleExtensionData.sendMeasureData(bodyBaseModel, deviceModel, 10));

        }else{
          this.kitchenStreamHandler?.success(PPLefuBleExtensionData.sendMeasureData(bodyBaseModel, deviceModel, 0));

        }
      }






    },

    monitorLockData: (bodyBaseModel: PPBodyBaseModel | null, deviceModel: PPDeviceModel | null) => {
      if (bodyBaseModel?.isHeartRating) {
        this.addLog(`心率测量中 monitorLockData`)
        this.measureStreamHandler?.success(PPLefuBleExtensionData.sendMeasureData(bodyBaseModel, deviceModel, 2));
      } else {
        if (PPScaleHelper.isCalculate8(deviceModel?.deviceCalculateType)) {
          this.addLog(`稳定数据:${bodyBaseModel?.getPpWeightKg()}
              z100KhzLeftLegEnCode:${bodyBaseModel?.z100KhzLeftLegEnCode}
              z100KhzRightArmEnCode:${bodyBaseModel?.z100KhzRightArmEnCode}
              z100KhzRightLegEnCode:${bodyBaseModel?.z100KhzRightLegEnCode}
              z100KhzTrunkEnCode:${bodyBaseModel?.z100KhzTrunkEnCode}
              z20KhzLeftArmEnCode:${bodyBaseModel?.z20KhzLeftArmEnCode}
              z20KhzLeftLegEnCode:${bodyBaseModel?.z20KhzLeftLegEnCode}
              z20KhzRightArmEnCode:${bodyBaseModel?.z20KhzRightArmEnCode}
              z20KhzRightLegEnCode:${bodyBaseModel?.z20KhzRightLegEnCode}
              z20KhzTrunkEnCode:${bodyBaseModel?.z20KhzTrunkEnCode}
              heartRate:${bodyBaseModel?.heartRate}
             `)
        } else if (PPScaleHelper.isCalculate4DualFrequency(deviceModel?.deviceCalculateType)) {
          this.addLog(`稳定数据:${bodyBaseModel?.getPpWeightKg()}
              impedance:${bodyBaseModel?.impedance}
              impedance100EnCode:${bodyBaseModel?.ppImpedance100EnCode}
              heartRate:${bodyBaseModel?.heartRate}`)
        } else {
          this.addLog(`稳定数据:${bodyBaseModel?.getPpWeightKg()} impedance:${bodyBaseModel?.impedance}`)
        }
        this.addLog(`测量结束`)
        this.measureStreamHandler?.success(PPLefuBleExtensionData.sendMeasureData(bodyBaseModel, deviceModel, 10));
      }
    },
  }

  private startConnectDevice() {
    this.addLog('开始连接设备');
    this.deviceControl?.startConnect((state: ble.ProfileConnectionState) => {
      this.connectState = state;
      PPLoggerPluginOhos.i(`BluetoothPage bluetooth connect state changed state:${state}}`);
      // 发送连接状态 连接状态 0:断开连接 1:连接成功 2:连接错误
      if (this.connectState === constant.ProfileConnectionState.STATE_DISCONNECTED) {
        this.addLog('设备断开');
        this.sendConnectState(0);
      } else if (this.connectState === constant.ProfileConnectionState.STATE_CONNECTED) {
        this.addLog('连接成功，需等待服务发现成功');
      } else if (this.connectState === constant.ProfileConnectionState.STATE_CONNECTING) {
        this.addLog('正在连接');
      } else if (this.connectState === constant.ProfileConnectionState.STATE_DISCONNECTING) {
        this.addLog('正在断开连接');
      }
    }, (isSuccess: boolean) => {
      if (isSuccess) {
        this.addLog('服务发现成功,可以调用指令');
        setTimeout(() => {
          console.log('1秒后执行的操作');
          this.sendConnectState(1);
        }, 500);

      } else {
        this.addLog('服务发现失败');
        this.sendConnectState(2);
      }
    });
  }

  delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  disconnect(): void {
    // 实现断开连接逻辑
    this.deviceControl?.stopSearch();
    this.deviceControl?.disConnect();
    this.clearData();
  }

  private clearData(): void {
    // 清理设备相关数据
    this.currentDevice = null;
    this.deviceControl = null;
    this.sendConnectState(0);
  }

  /// 发送连接状态 连接状态 0:断开连接 1:连接成功 2:连接错误
  sendConnectState(state: number): void {
    this.loggerStreamHandler?.success(`连接状态:${state}`);
    this.connectState = state;

    this.connectStateStreamHandler?.success({
      deviceMac: this.currentDevice?.deviceMac || '',
      state: state
    });
  }

  sendBlePermissionState(state: number): void {
    let stateValue = 0;
    switch (state) {
      case 1: // unauthorized
        stateValue = 1;
        break;
      case 2: // poweredOn
        stateValue = 2;
        break;
      case 3: // poweredOff
        stateValue = 3;
        break;
    }

    this.blePermissionStreamHandler?.success({ state: stateValue });
  }

  sendScanState(scaning: boolean): void {
    this.addLog(`sendScanState ${scaning}`);
    let code = scaning ? 1 : 0;
    this.scanStateStreamHandler?.success({ state: code });
  }

  // 发送通用状态
  sendCommonState(state: boolean, callBack: MethodResult): void {
    callBack.success({ state: state });
  }

  fetchHistory(userID: string, memberID: string, result: MethodResult) {
    this.historyModels = [];
    this.addLog(`获取历史记录 userID:${userID}`)
    if (this.deviceControl instanceof PPAppleDeviceControl) {
      this.deviceControl.syncHistory(this.touristHistoryDataInterface);

    } else if (this.deviceControl instanceof PPTorreDeviceControl || this.deviceControl instanceof PPBorreDeviceControl) {
      if (userID === "30") {
        this.deviceControl.syncTouristHistory(this.touristHistoryDataInterface)
      } else {
        let userModel = new PPUserModel();
        userModel.userID = userID;
        userModel.memberID = memberID;
        this.deviceControl.syncUserHistory(userModel, this.userHistoryDataInterface);
      }
    } else if (this.deviceControl instanceof PPIceDeviceControl) {
      this.deviceControl.syncHistory(this.touristHistoryDataInterface)
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-fetchConnectedDevice-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}-`)
    }
  }

  //游客
  touristHistoryDataInterface: PPHistoryDataInterface = {
    // 监控历史数据
    monitorHistoryData: (bodyBaseModel: PPBodyBaseModel | null) => {
      if (bodyBaseModel != null) {
        this.addLog(`游客历史数据:${bodyBaseModel.getPpWeightKg()}`)
        this.historyModels.push(bodyBaseModel);
      }
    },

    // 监控历史结束
    monitorHistoryEnd: () => {
      this.addLog(`游客历史数据结束`)
      const dataDict = PPLefuBleExtensionData.sendHistoryData(this.historyModels)
      this.historyStreamHandler?.success({ dataList: dataDict })
    },

    // 监控历史失败
    monitorHistoryFail: () => {
      this.addLog(`游客历史数据失败`)
      const dataDict = PPLefuBleExtensionData.sendHistoryData(this.historyModels)
      this.historyStreamHandler?.success({ dataList: dataDict })
    },

  }
  //用户
  userHistoryDataInterface: PPHistoryDataInterface = {
    // 监控历史数据
    monitorHistoryData: (bodyBaseModel: PPBodyBaseModel | null) => {
      if (bodyBaseModel != null) {
        this.addLog(`用户历史数据:${bodyBaseModel.getPpWeightKg()}`)
        this.historyModels.push(bodyBaseModel);
      }
    },

    // 监控历史结束
    monitorHistoryEnd: () => {
      this.addLog(`用户历史数据结束`)
      const dataDict = PPLefuBleExtensionData.sendHistoryData(this.historyModels)
      this.historyStreamHandler?.success({ dataList: dataDict })
    },

    // 监控历史失败
    monitorHistoryFail: () => {
      this.addLog(`用户历史数据失败`);
      const dataDict = PPLefuBleExtensionData.sendHistoryData(this.historyModels)
      this.historyStreamHandler?.success({ dataList: dataDict })
    },

  }

  deleteHistory() {
    this.addLog(`deleteHistory`)
    if (this.deviceControl instanceof PPAppleDeviceControl) {
      this.deviceControl.deleteHistory();
    } else if (this.deviceControl instanceof PPIceDeviceControl) {
      this.deviceControl.deleteHistory();
    } else if (this.deviceControl instanceof PPBananaDeviceControl) {
      // this.deviceControl.deleteHistory();
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-fetchConnectedDevice-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}-`)
    }
  }

  configWifi(domain: string, ssId: string, password: string | null = null, result: MethodResult) {
    this.addLog(`configWifi domain:${domain},ssId:${ssId},password:${password}`)
    if (this.deviceControl instanceof PPAppleDeviceControl) {

      this.deviceControl?.modifyServerDomain(domain, (modifyResult) => {
        if (modifyResult) {
          this.addLog(`修改域名成功`)
          if (this.deviceControl instanceof PPAppleDeviceControl) {
            this.deviceControl?.configWifi(ssId, password, (sn, stateMenu) => {
              this.addLog(`配置Wifi Success sn:${sn} ${stateMenu}`);
              result.success({ sn: sn, erroCode: 0, success: true })
            })
          }
        } else {
          this.addLog(`修改域名失败`)
        }
      })

    } else if (this.deviceControl instanceof PPTorreDeviceControl) {
      this.deviceControl.configWifi(domain, ssId, password, (configState: PPConfigWifiStateMenu, resultCode: string) => {

        if (configState == PPConfigWifiStateMenu.CONFIG_STATE_SUCCESS) {
          result.success({ sn: resultCode, erroCode: 0, success: true })

        } else {

          result.success({ sn: resultCode, erroCode: 1, success: false })

        }

      });
    } else if (this.deviceControl instanceof PPBorreDeviceControl) {
      this.deviceControl.configWifi(domain, ssId, password, (configState: PPConfigWifiStateMenu, resultCode: string) => {

        if (configState == PPConfigWifiStateMenu.CONFIG_STATE_SUCCESS) {
          result.success({ sn: resultCode, erroCode: 0, success: true })
        } else {
          result.success({ sn: resultCode, erroCode: 1, success: false })
        }

      });
    } else if (this.deviceControl instanceof PPIceDeviceControl) {

      const deviceControlIce = this.deviceControl as PPIceDeviceControl;

      deviceControlIce.modifyServerDomain(domain, (success: boolean) => {
        if (success) {
          this.addLog("Ice modifyServerDomain 修改域名成功")

          deviceControlIce.configWifi(ssId, password ?? "", (sn: string | null, configState: PPConfigWifiStateMenu) => {
            this.addLog(`Ice configWifi result ${configState} sn:${sn}`)
            if (configState == PPConfigWifiStateMenu.CONFIG_STATE_SUCCESS) {
              result.success({ sn: sn, erroCode: 0, success: true })
            } else {
              result.success({ sn: "", erroCode: 1, success: false })
            }

          });

        } else {
          this.addLog("Ice modifyServerDomain 修改域名失败")
        }
      })

    }
  }

  async changeBuzzerGate(isOpen: boolean, result: MethodResult): Promise<void> {
    if (this.deviceControl instanceof PPFishDeviceControl) {
      const syncResult = await this.deviceControl.buzzerGate(isOpen)
      this.sendCommonState(syncResult, result)

    }else{

      this.loggerStreamHandler?.success(`不支持该功能-changeBuzzerGate`)

    }
  }

  async syncTime(is24Hour: boolean, result: MethodResult): Promise<void> {
    this.addLog(`syncTime is24Hour:${is24Hour}`)
    if (this.deviceControl instanceof PPAppleDeviceControl) {
      const syncResult = await this.deviceControl.syncTime(systemDateTime.getTime())
      this.sendCommonState(syncResult, result)
    } else if (this.deviceControl instanceof PPCoconutDeviceControl) {
      const syncResult = await this.deviceControl.syncTime(systemDateTime.getTime())
      this.sendCommonState(syncResult, result)
    } else if (this.deviceControl instanceof PPTorreDeviceControl) {
      const syncResult = await this.deviceControl.syncTime(systemDateTime.getTime(), is24Hour ? TimeFormat.HOUR_24 : TimeFormat.HOUR_12)
      this.sendCommonState(syncResult, result)
    } else if (this.deviceControl instanceof PPBorreDeviceControl) {
      const syncResult = await this.deviceControl.syncTime(systemDateTime.getTime(), is24Hour ? TimeFormat.HOUR_24 : TimeFormat.HOUR_12)
      this.sendCommonState(syncResult, result)
    } else if (this.deviceControl instanceof PPIceDeviceControl) {
      const syncResult = await this.deviceControl.syncTime(systemDateTime.getTime())
      this.sendCommonState(syncResult, result)
    } else if (this.deviceControl instanceof PPFishDeviceControl) {
      const syncResult = await this.deviceControl.syncTime(systemDateTime.getTime())

    } else if (this.deviceControl instanceof PPBananaDeviceControl) {
      // this.deviceControl.syncTime(systemDateTime.getTime())
    } else if (this.deviceControl instanceof PPJambulDeviceControl) {
      // this.deviceControl.syncUnit(systemDateTime.getTime())
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-fetchConnectedDevice-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}-`)
    }
  }

  async syncUnit(unit: number, sex: number, age: number, height: number, isPregnantMode: boolean, isAthleteMode: boolean, result: MethodResult): Promise<void> {
    this.addLog(`同步单位 unit:${unit},sex:${sex},age:${age},height:${height},isPregnantMode:${isPregnantMode},isAthleteMode:${isAthleteMode} 222`)
    if (this.deviceControl instanceof PPAppleDeviceControl) {
      let userModel = new PPUserModel();
      userModel.sex = sex;
      userModel.age = age;
      userModel.userHeight = height;
      const syncResult =
        await this.deviceControl.syncUnit(UnitUtil.getUnitType(unit, this.deviceControl.deviceModel?.deviceName ?? ""),
          userModel)
      this.sendCommonState(syncResult, result)

    } else if (this.deviceControl instanceof PPCoconutDeviceControl) {

      let userModel = new PPUserModel();
      userModel.sex = sex;
      userModel.age = age;
      userModel.userHeight = height;
      const syncResult =
        await this.deviceControl.syncUnit(UnitUtil.getUnitType(unit, this.deviceControl.deviceModel?.deviceName ?? ""),
          userModel)
      this.sendCommonState(syncResult, result)
    } else if (this.deviceControl instanceof PPFishDeviceControl) {
      const syncResult = await this.deviceControl.changeUnit(UnitUtil.getUnitTypeSimple(unit))
      this.sendCommonState(syncResult, result)

    } else if (this.deviceControl instanceof PPEggDeviceControl) {
      const syncResult = await this.deviceControl.changeUnit(UnitUtil.getUnitTypeSimple(unit))
      this.sendCommonState(syncResult, result)

    } else if (this.deviceControl instanceof PPTorreDeviceControl) {
      const syncResult = await this.deviceControl.syncUnit(UnitUtil.getUnitTypeSimple(unit))
    } else if (this.deviceControl instanceof PPBorreDeviceControl) {
      const syncResult = await this.deviceControl.syncUnit(UnitUtil.getUnitTypeSimple(unit))
      this.sendCommonState(syncResult, result)
    } else if (this.deviceControl instanceof PPIceDeviceControl) {
      const syncResult = await this.deviceControl.syncUnit(UnitUtil.getUnitTypeSimple(unit))
      this.sendCommonState(syncResult, result)
    } else if (this.deviceControl instanceof PPBananaDeviceControl) {
      // this.deviceControl.syncUnit(systemDateTime.getTime())
    } else if (this.deviceControl instanceof PPJambulDeviceControl) {
      let userModel = new PPUserModel();
      userModel.sex = sex;
      userModel.age = age;
      userModel.userHeight = height;
      const syncResult = await this.deviceControl.syncUnit(UnitUtil.getUnitType(unit, this.deviceControl.deviceModel?.deviceName ?? ""),
        userModel)
      this.sendCommonState(syncResult, result)
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-fetchConnectedDevice-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}-`)
      this.sendCommonState(false, result)
    }
  }

  fetchWifiInfo(result: MethodResult) {
    this.addLog('获取WiFi信息')
    if (this.deviceControl instanceof PPAppleDeviceControl) {
      this.deviceControl.readWifiInfo((ssid: string | null) => {
        result.success({
          ssId: ssid ?? "",
          isConnectWIFI: (!ssid) ? false : true,
        });
      })
    } else if (this.deviceControl instanceof PPTorreDeviceControl) {
      this.deviceControl.getWifiSSID((ssid: string | null) => {
        result.success({ ssId: ssid ?? "", isConnectWIFI: (!ssid) ? false : true });
      })
    } else if (this.deviceControl instanceof PPBorreDeviceControl) {
      this.deviceControl.getWifiSSID((ssid: string | null) => {
        result.success({ ssId: ssid ?? "", isConnectWIFI: (!ssid) ? false : true });
      })
    } else if (this.deviceControl instanceof PPIceDeviceControl) {
      this.deviceControl.getWifiSSID((ssid: string | null) => {
        result.success({ ssId: ssid ?? "", isConnectWIFI: (!ssid) ? false : true });
      })
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-fetchConnectedDevice-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}-`)

    }
  }

  async fetchDeviceInfo(result: MethodResult) {
    this.addLog('获取设备信息');
    if (this.deviceControl instanceof PPAppleDeviceControl) {
      const deviceModel = await this.deviceControl.readDeviceInfo()
      result.success(PPLefuBleExtensionData.convertDeviceDict(deviceModel));

    } else if (this.deviceControl instanceof PPCoconutDeviceControl) {
      const deviceModel = await this.deviceControl.readDeviceInfo()
      result.success(PPLefuBleExtensionData.convertDeviceDict(deviceModel));

    } else if (this.deviceControl instanceof PPFishDeviceControl) {
      const deviceModel = await this.deviceControl.readDeviceInfo()
      result.success(PPLefuBleExtensionData.convertDeviceDict(deviceModel));
    } else if (this.deviceControl instanceof PPEggDeviceControl) {
      const deviceModel = await this.deviceControl.readDeviceInfo()
      result.success(PPLefuBleExtensionData.convertDeviceDict(deviceModel));
    } else if (this.deviceControl instanceof PPTorreDeviceControl) {
      const deviceModel = await this.deviceControl.readDeviceInfo()
      result.success(PPLefuBleExtensionData.convertDeviceDict(deviceModel));
    } else if (this.deviceControl instanceof PPBorreDeviceControl) {
      const deviceModel = await this.deviceControl.readDeviceInfo()
      result.success(PPLefuBleExtensionData.convertDeviceDict(deviceModel));
    } else if (this.deviceControl instanceof PPIceDeviceControl) {
      const deviceModel = await this.deviceControl.readDeviceInfo()
      result.success(PPLefuBleExtensionData.convertDeviceDict(deviceModel));
    } else if (this.deviceControl instanceof PPBananaDeviceControl) {
    } else if (this.deviceControl instanceof PPJambulDeviceControl) {
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-fetchDeviceInfo-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}-`)
    }
  }

  async fetchBatteryInfo(result: MethodResult) {
    this.addLog('获取电池信息')
    if (this.deviceControl instanceof PPAppleDeviceControl) {
      const battery = await this.deviceControl.readBatteryLevel();
      this.batteryStreamHandler?.success({ power: battery })
    } else if (this.deviceControl instanceof PPCoconutDeviceControl) {
      const battery = await this.deviceControl.readBatteryLevel((battery,lightIntensity) => {
        this.addLog(`光照强度 ${lightIntensity}`)
        this.batteryStreamHandler?.success({ power: battery,lumen: lightIntensity})

      });
      this.batteryStreamHandler?.success({ power: battery })

    } else if (this.deviceControl instanceof PPFishDeviceControl) {
      const battery = await this.deviceControl.readBatteryLevel();
      this.batteryStreamHandler?.success({ power: battery })
    } else if (this.deviceControl instanceof PPEggDeviceControl) {
      const battery = await this.deviceControl.readBatteryLevel();
      this.batteryStreamHandler?.success({ power: battery })


    } else if (this.deviceControl instanceof PPTorreDeviceControl) {
      const battery = await this.deviceControl.readBatteryLevel();
      this.batteryStreamHandler?.success({ power: battery })
    } else if (this.deviceControl instanceof PPBorreDeviceControl) {
      const battery = await this.deviceControl.readBatteryLevel();
      this.batteryStreamHandler?.success({ power: battery })
    } else if (this.deviceControl instanceof PPIceDeviceControl) {
      const battery = await this.deviceControl.readBatteryLevel();
      this.batteryStreamHandler?.success({ power: battery })
    } else if (this.deviceControl instanceof PPBananaDeviceControl) {
    } else if (this.deviceControl instanceof PPJambulDeviceControl) {
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-fetchConnectedDevice-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}-`)

    }
  }

  resetDevice(): void {
    this.addLog('重置设备');
    if (this.deviceControl instanceof PPAppleDeviceControl) {
      this.deviceControl.resetDevice();
    } else if (this.deviceControl instanceof PPTorreDeviceControl) {
      this.deviceControl.resetDevice();
    } else if (this.deviceControl instanceof PPBorreDeviceControl) {
      this.deviceControl.resetDevice();
    } else if (this.deviceControl instanceof PPIceDeviceControl) {
      this.deviceControl.resetDevice();
    } else if (this.deviceControl instanceof PPBananaDeviceControl) {
    } else if (this.deviceControl instanceof PPJambulDeviceControl) {
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-fetchConnectedDevice-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}-`)

    }
  }

  async fetchConnectedDevice(result: MethodResult) {
    this.addLog('获取已连接设备')
    if (this.deviceControl instanceof PPAppleDeviceControl) {
      const deviceModel = await this.deviceControl.deviceModel
      result.success(PPLefuBleExtensionData.convertDeviceDict(deviceModel));
    } else if (this.deviceControl instanceof PPCoconutDeviceControl) {
      const deviceModel = await this.deviceControl.deviceModel
      result.success(PPLefuBleExtensionData.convertDeviceDict(deviceModel));
    } else if (this.deviceControl instanceof PPTorreDeviceControl) {
      const deviceModel = await this.deviceControl.deviceModel
      result.success(PPLefuBleExtensionData.convertDeviceDict(deviceModel));
    } else if (this.deviceControl instanceof PPBorreDeviceControl) {
      const deviceModel = await this.deviceControl.deviceModel
      result.success(PPLefuBleExtensionData.convertDeviceDict(deviceModel));
    } else if (this.deviceControl instanceof PPIceDeviceControl) {
      const deviceModel = await this.deviceControl.deviceModel
      result.success(PPLefuBleExtensionData.convertDeviceDict(deviceModel));
    } else if (this.deviceControl instanceof PPBananaDeviceControl) {
      const deviceModel = await this.deviceControl.deviceModel
      result.success(PPLefuBleExtensionData.convertDeviceDict(deviceModel));
    } else if (this.deviceControl instanceof PPJambulDeviceControl) {
      const deviceModel = await this.deviceControl.deviceModel
      result.success(PPLefuBleExtensionData.convertDeviceDict(deviceModel));
    } else if (this.deviceControl instanceof PPFishDeviceControl) {
      const deviceModel = await this.deviceControl.deviceModel
      result.success(PPLefuBleExtensionData.convertDeviceDict(deviceModel));
    } else if (this.deviceControl instanceof PPEggDeviceControl) {
      const deviceModel = await this.deviceControl.deviceModel
      result.success(PPLefuBleExtensionData.convertDeviceDict(deviceModel));
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-fetchConnectedDevice-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}-`)

    }
  }

  ///蓝牙权限变化监听，0:未知，1：未授权，2:蓝牙-开，3：蓝牙-关
  async addBlePermissionListener(): Promise<void> {
    this.addLog('addBlePermissionListener 蓝牙权限监听')
    let checkPermission: Permissions = "ohos.permission.ACCESS_BLUETOOTH";
    let isPermission: boolean = await this.checkSelfPermission(checkPermission);
    this.addLog(`addBlePermissionListener isPermission:${isPermission}`)
    if (isPermission) {
      if (this.isAdapterOn()) {
        this.addLog('addBlePermissionListener 蓝牙可以使用');
        this.sendBlePermissionState(2);
      } else {
        this.addLog('addBlePermissionListener 蓝牙开关未打开');
        this.sendBlePermissionState(3);
      }
    } else {
      let permissions = new Array<Permissions>();
      permissions.push("ohos.permission.ACCESS_BLUETOOTH");
      await this.ensurePermissions(permissions);
      this.sendBlePermissionState(1);
    }
  }

  fetchWifiMac(result: MethodResult): void {
    this.addLog('获取WiFi MAC地址')
    if (this.deviceControl instanceof PPTorreDeviceControl) {
      this.deviceControl.getWifiMac((mac: string | null) => {
        result.success({ wifiMac: mac });
      })
    } else if (this.deviceControl instanceof PPBorreDeviceControl) {
      this.deviceControl.getWifiMac((mac: string | null) => {
        result.success({ wifiMac: mac });
      })
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-fetchWifiMac-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}-`)
    }
  }

  scanWifiNetworks(result: MethodResult): void {
    this.addLog('扫描WiFi网络')
    if (this.deviceControl instanceof PPTorreDeviceControl) {
      this.deviceControl.getWifiList((wifiModels: PPWifiModel[] | null) => {
        const networks: string[] = [];
        if (wifiModels) {
          wifiModels.forEach((wifiModel: PPWifiModel) => {
            if (wifiModel?.ssid) {
              networks.push(wifiModel?.ssid);
            }
          });
        }
        result.success({ wifiList: networks });
      })
    } else if (this.deviceControl instanceof PPBorreDeviceControl) {
      this.deviceControl.getWifiList((wifiModels: PPWifiModel[] | null) => {
        const networks: string[] = [];
        if (wifiModels) {
          wifiModels.forEach((wifiModel: PPWifiModel) => {
            if (wifiModel?.ssid) {
              networks.push(wifiModel?.ssid);
            }
          });
        }
        result.success({ wifiList: networks });
      })
    } else if (this.deviceControl instanceof PPIceDeviceControl) {
      this.deviceControl.getWifiList((wifiModels: PPWifiModel[] | null) => {
        const networks: string[] = [];
        if (wifiModels) {
          wifiModels.forEach((wifiModel: PPWifiModel) => {
            if (wifiModel?.ssid) {
              networks.push(wifiModel?.ssid);
            }
          });
        }
        result.success({ wifiList: networks });
      })
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-scanWifiNetworks-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}-`)
    }
  }

  async wifiOTA(result: MethodResult) {
    this.addLog('WiFi OTA升级')
    if (this.deviceControl instanceof PPTorreDeviceControl) {
      const callResult = await this.deviceControl.startUserOTA({
        onUpdateFail: (errorCode: number) => {
          this.loggerStreamHandler?.success(`onUpdateFail errorCode:${errorCode}`)
          result.success({ isSuccess: false, errorCode: errorCode });
        },
        onUpdateSuccess: () => {
          this.loggerStreamHandler?.success(`onUpdateSuccess`)
          result.success({ isSuccess: result, errorCode: 0 });
        },

      });
      if (!callResult) {
        result.success({ isSuccess: callResult, errorCode: 3 });
      }
    } else if (this.deviceControl instanceof PPBorreDeviceControl) {
      const callResult = await this.deviceControl.startUserOTA({
        onUpdateFail: (errorCode: number) => {
          this.loggerStreamHandler?.success(`onUpdateFail errorCode:${errorCode}`)
          result.success({ isSuccess: false, errorCode: errorCode });
        },
        onUpdateSuccess: () => {
          this.loggerStreamHandler?.success(`onUpdateSuccess`)
          result.success({ isSuccess: result, errorCode: 0 });
        },

      });
      if (!callResult) {
        result.success({ isSuccess: callResult, errorCode: 3 });
      }
    } else if (this.deviceControl instanceof PPIceDeviceControl) {
      const callResult = await this.deviceControl.startUserOTA({
        onUpdateFail: (errorCode: number) => {
          this.loggerStreamHandler?.success(`onUpdateFail errorCode:${errorCode}`)
          result.success({ isSuccess: false, errorCode: errorCode });
        },
        onUpdateSuccess: () => {
          this.loggerStreamHandler?.success(`onUpdateSuccess`)
          result.success({ isSuccess: result, errorCode: 0 });
        }
      });
      if (!callResult) {
        result.success({ isSuccess: callResult, errorCode: 3 });
      }
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-wifiOTA-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}-`)
    }
  }

  heartRateSwitchControl(open: boolean, result: MethodResult): void {
    this.addLog(` 心率开关控制 open:${open}`);
    if (this.deviceControl instanceof PPTorreDeviceControl) {
      // 心率0打开 1关闭
      this.deviceControl.controlHeartRate(open, (isSuccess: boolean) => {
        result.success({ state: isSuccess });
      });

    }
    if (this.deviceControl instanceof PPBorreDeviceControl) {
      // 心率0打开 1关闭
      this.deviceControl.controlHeartRate(open, (isSuccess: boolean) => {
        result.success({ state: isSuccess });
      });
    } else if (this.deviceControl instanceof PPIceDeviceControl) {
      // 心率0打开 1关闭
      this.deviceControl.controlHeartRate(open, (isSuccess: boolean) => {
        result.success({ state: isSuccess });
      });
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-heartRateSwitchControl-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}-`)
    }
  }

  fetchHeartRateSwitch(result: MethodResult): void {
    this.addLog('获取心率开关状态')
    if (this.deviceControl instanceof PPTorreDeviceControl) {
      this.deviceControl.getHeartRateState((isOn: boolean) => {
        result.success({ open: isOn });
      });
    } else if (this.deviceControl instanceof PPBorreDeviceControl) {
      this.deviceControl.getHeartRateState((isOn: boolean) => {
        result.success({ open: isOn });
      });
    } else if (this.deviceControl instanceof PPIceDeviceControl) {
      this.deviceControl.getHeartRateState((isOn: boolean) => {
        result.success({ open: isOn });
      });
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-fetchHeartRateSwitch-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}-`)
    }
  }

  impedanceSwitchControl(open: boolean, result: MethodResult): void {
    this.addLog(`阻抗开关控制 open:${open}`)
    if (this.deviceControl instanceof PPTorreDeviceControl) {
      // 阻抗0打开 1关闭
      this.deviceControl.controlImpedance(open, (isSuccess: boolean) => {
        this.sendCommonState(isSuccess, result);
      });
    } else if (this.deviceControl instanceof PPBorreDeviceControl) {
      // 阻抗0打开 1关闭
      this.deviceControl.controlImpedance(open, (isSuccess: boolean) => {
        this.sendCommonState(isSuccess, result);
      });
    } else if (this.deviceControl instanceof PPIceDeviceControl) {
      // 阻抗0打开 1关闭
      this.deviceControl.controlImpedance(open, (isSuccess: boolean) => {
        this.sendCommonState(isSuccess, result);
      });
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-impedanceSwitchControl-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}-`)
    }
  }

  fetchImpedanceSwitch(result: MethodResult): void {
    this.addLog('获取阻抗开关状态')
    if (this.deviceControl instanceof PPTorreDeviceControl) {
      this.deviceControl.getImpedanceState((isOn: boolean) => {

        result.success({ open: isOn });

      });
    } else if (this.deviceControl instanceof PPBorreDeviceControl) {
      this.deviceControl.getImpedanceState((isOn: boolean) => {
        result.success({ open: isOn });
      });
    } else if (this.deviceControl instanceof PPIceDeviceControl) {
      this.deviceControl.getImpedanceState((isOn: boolean) => {
        result.success({ open: isOn });
      });
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-fetchImpedanceSwitch-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}-`)
    }
  }

  setBindingState(binding: boolean, result: MethodResult): void {
    this.addLog(`设置绑定状态 binding:${binding}`)
    if (this.deviceControl instanceof PPTorreDeviceControl) {
      // 绑定0解绑 1绑定
      this.deviceControl.deviceBindStatus(binding, (isSuccess: boolean) => {
        this.sendCommonState(isSuccess, result);
      });
    } else if (this.deviceControl instanceof PPBorreDeviceControl) {
      // 绑定0解绑 1绑定
      this.deviceControl.deviceBindStatus(binding, (isSuccess: boolean) => {
        this.sendCommonState(isSuccess, result);
      });
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-setBindingState-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}-`)
    }
  }

  fetchBindingState(result: MethodResult): void {
    this.addLog('获取绑定状态')
    if (this.deviceControl instanceof PPTorreDeviceControl) {
      this.deviceControl.getDeviceBindStatus((isBind: boolean) => {
        result.success({ binding: isBind });
      });
    } else if (this.deviceControl instanceof PPBorreDeviceControl) {
      this.deviceControl.getDeviceBindStatus((isBind: boolean) => {
        result.success({ binding: isBind });
      });
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-fetchBindingState-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}-`)
    }
  }

  setScreenBrightness(brightness: number, result: MethodResult): void {
    this.addLog(`设置屏幕亮度 brightness:${brightness}`)
    if (this.deviceControl instanceof PPTorreDeviceControl) {
      this.deviceControl.setLight(brightness, (isSuccess: boolean) => {
        this.sendCommonState(isSuccess, result);
      });
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-getScreenBrightness-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}-`)
    }
  }

  getScreenBrightness(result: MethodResult): void {
    this.addLog('获取屏幕亮度')
    if (this.deviceControl instanceof PPTorreDeviceControl) {
      this.deviceControl.getLight((brightness: number) => {
        result.success({ brightness: brightness });
      });
    }
  }

  toZero(result: MethodResult): void {
    this.addLog('去皮')
    if (this.deviceControl instanceof PPFishDeviceControl) {
      this.deviceControl.toZero();
    }

    if (this.deviceControl instanceof PPEggDeviceControl) {
      this.deviceControl.toZero();
    }
  }

  async setRGBMode(lightEnable:number,lightMode:number,defaultColor:string,gainColor:string,lossColor:string, result: MethodResult) {
    if (this.deviceControl instanceof PPBorreDeviceControl) {
      let cmdResult = await this.deviceControl?.setRGBMode(lightEnable,lightMode,defaultColor,gainColor,lossColor,((state: number | null)=>{


      }))
      this.sendCommonState(cmdResult, result);

    }
  }


    async syncUserInfo(model: PPUserModel, result: MethodResult) {
    this.addLog(`同步用户信息 model:${JSON.stringify(model)}`)
    if (this.deviceControl instanceof PPTorreDeviceControl) {
      const syncResult = await this.deviceControl.syncUserInfo(model);
      result.success({ state: syncResult });
    } else if (this.deviceControl instanceof PPBorreDeviceControl) {
      const syncResult = await this.deviceControl.syncUserInfo(model);
      result.success({ state: syncResult });
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-syncUserInfo-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}-`)
    }
  }

  async syncLast7DaysDataUserInfo(userModel: PPUserModel, recentList: Array<PPUserRecentBodyData>, result: MethodResult) {
    this.addLog(`同步用户7天数据信息 model:${JSON.stringify(userModel)}`)
    if (this.deviceControl instanceof PPBorreDeviceControl) {
      const syncResult = await this.deviceControl.syncLast7DaysDataUserInfo(userModel, recentList);
      result.success({ state: syncResult });
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-syncUserInfo-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}-`)
    }
  }

  async setDisplayMetrics(metrics : PPDisplayMetrics) {
    this.loggerStreamHandler?.success(`metrics2 ${metrics}`)

    if (this.deviceControl instanceof PPBorreDeviceControl) {
       this.deviceControl.setDisplayMetrics(metrics);
    }

  }

  async getDisplayMetrics(result: MethodResult){
    if (this.deviceControl instanceof PPBorreDeviceControl) {
      this.deviceControl.getDisplayMetrics((met) => {

        result.success({ metrics: met })

      });

    }

  }


  async syncBorreCLast7DaysDataUserInfo(userModel: PPUserModel, recentList: Array<PPUserRecentBodyData>,type:PPUserBodyDataType, result: MethodResult) {
    this.addLog(`同步用户7天数据信息 model:${JSON.stringify(userModel)}`)
    if (this.deviceControl instanceof PPBorreDeviceControl) {
      const syncResult = await this.deviceControl.syncBorreCLast7DaysDataUserInfo(userModel, recentList,type);
      result.success({ state: syncResult });
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-syncUserInfo-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}-`)
    }
  }

  syncUserList(userArray: PPUserModel[], result: MethodResult): void {
    this.addLog(`同步用户列表 userArray:${JSON.stringify(userArray)}`)
    const deviceModel = this.deviceControl?.deviceModel;
    this.loggerStreamHandler?.success(`不支持该功能-syncUserList-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}-`)

  }

  // syncLast7Data(model: PPUserRecentBodyData, result: MethodResult): void {
  //   this.addLog(`同步最近7天数据 model:${JSON.stringify(model)}`)

  //   if (this.deviceControl instanceof PPBorreDeviceControl) {
  //     const syncResult = await this.deviceControl.syncUserInfo(model);
  //     result.success({ state: syncResult });
  //   }
  // }

  fetchUserIDList(result: MethodResult): void {
    this.addLog('获取用户ID列表')
    if (this.deviceControl instanceof PPTorreDeviceControl) {
      this.deviceControl.getUserList((userIDList: string[]) => {
        result.success({ userIDList: userIDList });
      });
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-fetchUserIDList-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}-`)
    }
  }

  async selectUser(user: PPUserModel, result: MethodResult): Promise<void> {
    this.addLog(`选择用户 user:${JSON.stringify(user)}`)
    if (this.deviceControl instanceof PPTorreDeviceControl) {
      const selectResult = await this.deviceControl.sendCurrentUserInfo(user);
      this.sendCommonState(selectResult, result);
    } else if (this.deviceControl instanceof PPBorreDeviceControl) {
      const selectResult = await this.deviceControl.sendCurrentUserInfo(user);
      this.sendCommonState(selectResult, result);
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-selectUser-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}-`)
    }
  }

  async deleteUser(user: PPUserModel, result: MethodResult): Promise<void> {
    this.addLog(`删除用户 user:${JSON.stringify(user)}`)
    if (this.deviceControl instanceof PPTorreDeviceControl) {
      const deleteResult = await this.deviceControl.deleteUserInfo(user);
      this.sendCommonState(deleteResult, result);
    } else if (this.deviceControl instanceof PPBorreDeviceControl) {
      const deleteResult = await this.deviceControl.deleteUserInfo(user);
      this.sendCommonState(deleteResult, result);
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-deleteUser-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}-`)
    }
  }

  startMeasure(result: MethodResult): void {
    this.addLog('开始测量')
    if (this.deviceControl instanceof PPTorreDeviceControl) {
      this.deviceControl.startMeasure((state: number) => {
        // 0x00：成功
        // 0x01：设备配网中，开始测量失败
        // 0x02：设备OTA中，开始测量失败
        result.success({ state: state == 0 });
      });
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-startMeasure-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}`)
    }
  }

  async stopMeasure(result: MethodResult): Promise<void> {
    this.addLog('停止测量')
    if (this.deviceControl instanceof PPTorreDeviceControl) {
      const stopResult = await this.deviceControl.stopMeasure();
      this.addLog(`停止测量 stopResult：${stopResult}`);
      this.sendCommonState(stopResult, result);
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-stopMeasure-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}`)
    }
  }

  async startBabyModel(step: number, weight: number, result: MethodResult): Promise<void> {
    this.addLog(`开始婴儿模式 step:${step},weight:${weight}`)
    if (this.deviceControl instanceof PPTorreDeviceControl) {
      const startResult = await this.deviceControl.startBabyModel(step, weight, (isSuccess: boolean) => {
        this.sendCommonState(isSuccess, result);
      });
      if (!startResult) {
        this.sendCommonState(false, result);
      }
    } else if (this.deviceControl instanceof PPBorreDeviceControl) {
      const startResult = await this.deviceControl.startBabyModel(step, weight, (isSuccess: boolean) => {
        this.sendCommonState(isSuccess, result);
      });
      if (!startResult) {
        this.sendCommonState(false, result);
      }
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-startBabyModel-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}`)
    }
  }

  async exitBabyModel(result: MethodResult): Promise<void> {
    this.addLog('退出婴儿模式')
    if (this.deviceControl instanceof PPTorreDeviceControl) {
      const exitResult = await this.deviceControl.exitBabyModel((isSuccess: boolean) => {
        this.sendCommonState(isSuccess, result);
      });
      if (!exitResult) {
        this.sendCommonState(false, result);
      }
    } else if (this.deviceControl instanceof PPBorreDeviceControl) {
      const exitResult = await this.deviceControl.exitBabyModel((isSuccess: boolean) => {
        this.sendCommonState(isSuccess, result);
      });
      if (!exitResult) {
        this.sendCommonState(false, result);
      }
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-exitBabyModel-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}-`)
    }
  }

  startDFU(filePath: string, deviceFirmwareVersion: string, isForceCompleteUpdate: boolean,
    result: MethodResult): void {
    this.addLog(`开始DFU升级 filePath:${filePath},deviceFirmwareVersion:${deviceFirmwareVersion},isForceCompleteUpdate:${isForceCompleteUpdate}`)
  }

  async syncDeviceLog(logFolder: string): Promise<void> {
    this.addLog(`同步设备日志 logFolder:${logFolder}`)
    if (this.deviceControl instanceof PPTorreDeviceControl) {
      const syncLogReslut = await this.deviceControl.syncLog(logFolder, (progress: number, logFilePath: string, isEnd: boolean) => {
        if (isEnd) {
          this.deviceLogStreamHandler?.success({ progress: 100, isFailed: false, filePath: logFilePath })
        } else {
          this.deviceLogStreamHandler?.success({ progress: progress, isFailed: false, filePath: "" })
        }
      });
      if (!syncLogReslut) {
        this.deviceLogStreamHandler?.success({ progress: -1, isFailed: true, filePath: logFolder })
      }
    } else if (this.deviceControl instanceof PPBorreDeviceControl) {
      const syncLogReslut = await this.deviceControl.syncLog(logFolder, (progress: number, logFilePath: string, isEnd: boolean) => {
        if (isEnd) {
          this.deviceLogStreamHandler?.success({ progress: 100, isFailed: false, filePath: logFilePath })
        } else {
          this.deviceLogStreamHandler?.success({ progress: progress, isFailed: false, filePath: "" })
        }
      });
      if (!syncLogReslut) {
        this.deviceLogStreamHandler?.success({ progress: -1, isFailed: true, filePath: logFolder })
      }
    } else if (this.deviceControl instanceof PPIceDeviceControl) {
      const syncLogReslut = await this.deviceControl.syncLog(logFolder, (progress: number, logFilePath: string, isEnd: boolean) => {
        if (isEnd) {
          this.deviceLogStreamHandler?.success({ progress: 100, isFailed: false, filePath: logFilePath })
        } else {
          this.deviceLogStreamHandler?.success({ progress: progress, isFailed: false, filePath: "" })
        }
      });
      if (!syncLogReslut) {
        this.deviceLogStreamHandler?.success({ progress: -1, isFailed: true, filePath: logFolder })
      }
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-syncDeviceLog-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}-`)
    }
  }

  keepAlive(): void {
    this.addLog('保活')
    if (this.deviceControl instanceof PPTorreDeviceControl) {
      this.deviceControl.keepAlive();
    } else if (this.deviceControl instanceof PPBorreDeviceControl) {
      this.deviceControl.keepAlive();
    } else if (this.deviceControl instanceof PPIceDeviceControl) {
      this.deviceControl.keepAlive();
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-keepAlive-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}`)
    }
  }

  /**
   * 0：清除所有设备数据(用户信息、历史数据、配网数据、设置信息)
   1：清除用户信息
   2：清除历史数据
   3：清除配网状态
   4：清除设置信息
   * @param type
   * @param result
   */
  async clearDeviceData(type: number, result: MethodResult): Promise<void> {
    this.addLog(`清除设备数据 type:${type}`)

    if (this.deviceControl instanceof PPTorreDeviceControl) {
      if (type == 0) {
        const clearResult = await this.deviceControl.clearAllDeviceInfo((isSuccess: boolean) => {
          this.sendCommonState(isSuccess, result);
        });
      } else if (type == 1) {
        const clearResult = await this.deviceControl.clearDeviceUserInfo((isSuccess: boolean) => {
          this.sendCommonState(isSuccess, result);
        });
      } else if (type == 2) {
        const clearResult = await this.deviceControl.clearHistoryData((isSuccess: boolean) => {
          this.sendCommonState(isSuccess, result);
        });
      } else if (type == 3) {
        const clearResult = await this.deviceControl.clearConfigWifiInfo((isSuccess: boolean) => {
          this.sendCommonState(isSuccess, result);
        });
      } else if (type == 4) {
        const clearResult = await this.deviceControl.clearSettingInfo((isSuccess: boolean) => {
          this.sendCommonState(isSuccess, result);
        });
      }
    } else if (this.deviceControl instanceof PPBorreDeviceControl) {
      if (type == 0) {
        const clearResult = await this.deviceControl.clearAllDeviceInfo((isSuccess: boolean) => {
          this.sendCommonState(isSuccess, result);
        });
      } else if (type == 1) {
        const clearResult = await this.deviceControl.clearDeviceUserInfo((isSuccess: boolean) => {
          this.sendCommonState(isSuccess, result);
        });
      } else if (type == 2) {
        const clearResult = await this.deviceControl.clearHistoryData((isSuccess: boolean) => {
          this.sendCommonState(isSuccess, result);
        });
      } else if (type == 3) {
        const clearResult = await this.deviceControl.clearConfigWifiInfo((isSuccess: boolean) => {
          this.sendCommonState(isSuccess, result);
        });
      } else if (type == 4) {
        const clearResult = await this.deviceControl.clearSettingInfo((isSuccess: boolean) => {
          this.sendCommonState(isSuccess, result);
        });
      }
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-clearDeviceData-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}`)
    }
  }

  /**
   *  0, // 中文简体
   1, // 英文
   2, // 中文繁体
   3, // 日语
   4, // 西班牙语
   5, // 葡萄牙语
   6, // 阿拉伯语
   7 // 韩语
   * @param language
   * @param result
   */
  setDeviceLanguage(language: number, result: MethodResult): void {
    this.addLog(`设置设备语言 language:${language}`)
    if (this.deviceControl instanceof PPTorreDeviceControl) {
      this.deviceControl.setLanguage(language, (isSuccess: boolean) => {
        this.sendCommonState(isSuccess, result);
      });
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-setDeviceLanguage-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}`)
    }
  }

  fetchDeviceLanguage(result: MethodResult): void {
    this.addLog('获取设备语言')
    if (this.deviceControl instanceof PPTorreDeviceControl) {
      this.deviceControl.getLanguage((language: number) => {
        result.success({ language: language });
      });
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-fetchDeviceLanguage-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}`)
    }
  }

  async setDisplayBodyFat(bodyFat: number, result: MethodResult): Promise<void> {
    this.addLog(`设置显示体脂 bodyFat:${bodyFat}`)
    if (this.deviceControl instanceof PPIceDeviceControl) {
      const syncResult = await this.deviceControl.syncFat(bodyFat);
      this.sendCommonState(syncResult, result);
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-setDisplayBodyFat-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}`)
    }
  }

  async exitScanWifiNetworks(result: MethodResult): Promise<void> {
    this.addLog('退出WiFi扫描')
    if (this.deviceControl instanceof PPIceDeviceControl) {
      const exitResult = await this.deviceControl.exitWifiList();
      this.sendCommonState(exitResult, result);
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-exitScanWifiNetworks-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}`)
    }
  }

  async exitNetworkConfig(result: MethodResult): Promise<void> {
    this.addLog('退出网络配置')
    if (this.deviceControl instanceof PPTorreDeviceControl) {
      const exitResult = await this.deviceControl.exitConfigWifi();
      this.sendCommonState(exitResult, result);
    } else if (this.deviceControl instanceof PPBorreDeviceControl) {
      const exitResult = await this.deviceControl.exitConfigWifi();
      this.sendCommonState(exitResult, result);
    } else if (this.deviceControl instanceof PPIceDeviceControl) {
      const exitResult = await this.deviceControl.exitConfigWifi();
      this.sendCommonState(exitResult, result);
    } else {
      const deviceModel = this.deviceControl?.deviceModel;
      this.loggerStreamHandler?.success(`不支持该功能-exitScanWifiNetworks-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}`)
    }
  }

  sendBroadcastData(cmd: string, unit: number, result: MethodResult): void {
    this.addLog(`发送广播数据 cmd:${cmd},unit:${unit}`)
    const deviceModel = this.deviceControl?.deviceModel;
    this.loggerStreamHandler?.success(`不支持该功能-sendBroadcastData-deviceName:${deviceModel?.deviceName}-peripheralType:${deviceModel?.getDevicePeripheralType()}`)
  }

  addLog(message: string) {
    this.loggerStreamHandler?.success(`OHOS_SDK ${message}`);
    PPLoggerPluginOhos.d(`OHOS_SDK ${message}`)
  }
}