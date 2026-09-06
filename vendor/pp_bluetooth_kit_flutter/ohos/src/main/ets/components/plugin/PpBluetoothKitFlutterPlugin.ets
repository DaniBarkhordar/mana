import { FlutterPlugin, FlutterPluginBinding, MethodCall, MethodCallHandler, MethodChannel, MethodResult, EventChannel, AbilityPluginBinding, Any } from '@ohos/flutter_ohos';

import { EventSink } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';

import { PPUserGender,PPUserBodyDataType } from 'ppsdkkit/src/main/ets/enums/PPDeviceEnums';

import { PPBluetoothKit } from 'ppsdkkit/src/main/ets/PPBluetoothKit';
import { PPUserModel } from 'ppsdkkit/src/main/ets/vo/PPUserModel';
import { PPUserRecentBodyData } from 'ppsdkkit/src/main/ets/vo/PPUserRecentBodyData';

import { PPLefuBleConnectManager } from './PPLefuBleConnectManager';
import { PPLefuStreamHandler } from './PPLefuStreamHandler';
import { PPLoggerPluginOhos } from './util/PPLoggerPluginOhos';


/** PpBluetoothKitFlutterPlugin **/
export default class PpBluetoothKitFlutterPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private bleChannel: MethodChannel | null = null;
  private bleManager: PPLefuBleConnectManager = new PPLefuBleConnectManager();// 这里需要实例化鸿蒙对应的蓝牙管理类

  // 事件通道
  private measurementEventChannel: EventChannel | null = null;
  private loggerEventChannel: EventChannel | null = null;
  private connectStateEventChannel: EventChannel | null = null;
  private scanResultEventChannel: EventChannel | null = null;
  private historyEventChannel: EventChannel | null = null;
  private batteryEventChannel: EventChannel | null = null;
  private blePermissionEventChannel: EventChannel | null = null;
  private dfuEventChannel: EventChannel | null = null;
  private deviceLogEventChannel: EventChannel | null = null;
  private scanStateEventChannel: EventChannel | null = null;
  private kitchenEventChannel: EventChannel | null = null;

  private context: Context = getContext(this);
  private pluginBinding: FlutterPluginBinding | null = null;
  private abilityPluginBinding: AbilityPluginBinding | null = null;

  constructor() {
  }

  getUniqueClassName(): string {
    return "PpBluetoothKitFlutterPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {

    this.pluginBinding = binding;
    this.context = this.pluginBinding.getApplicationContext();

    // 主通道
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "pp_bluetooth_kit_flutter");
    this.channel.setMethodCallHandler(this);

    // 蓝牙通道
    this.bleChannel = new MethodChannel(binding.getBinaryMessenger(), "pp_ble_channel");
    this.bleChannel.setMethodCallHandler(this);

    // 测量数据事件通道
    let measureStreamHandler = new PPLefuStreamHandler();
    this.measurementEventChannel = new EventChannel(binding.getBinaryMessenger(), "pp_measurement_streams");
    this.bleManager.measureStreamHandler = measureStreamHandler;
    this.measurementEventChannel.setStreamHandler(measureStreamHandler);

    // 日志事件通道
    let loggerStreamHandler = new PPLefuStreamHandler()
    this.loggerEventChannel = new EventChannel(binding.getBinaryMessenger(), "pp_logger_streams");
    this.bleManager.loggerStreamHandler = loggerStreamHandler;
    this.loggerEventChannel.setStreamHandler(loggerStreamHandler);

    // 连接状态事件通道
    let connectStateStreamHandler = new PPLefuStreamHandler();
    this.connectStateEventChannel = new EventChannel(binding.getBinaryMessenger(), "pp_connect_state_streams");
    this.bleManager.connectStateStreamHandler = connectStateStreamHandler;
    this.connectStateEventChannel.setStreamHandler(connectStateStreamHandler);

    // 扫描结果事件通道
    let scanResultStreamHandler = new PPLefuStreamHandler();
    this.scanResultEventChannel = new EventChannel(binding.getBinaryMessenger(), "pp_device_list_streams");
    this.bleManager.scanResultStreamHandler = scanResultStreamHandler;
    this.scanResultEventChannel.setStreamHandler(scanResultStreamHandler);
    // 历史数据事件通道
    let historyStreamHandler = new PPLefuStreamHandler()
    this.historyEventChannel = new EventChannel(binding.getBinaryMessenger(), "pp_history_data_streams");
    this.bleManager.historyStreamHandler = historyStreamHandler;
    this.historyEventChannel.setStreamHandler(historyStreamHandler);

    // 电池事件通道
    let batteryStreamHandler = new PPLefuStreamHandler()
    this.batteryEventChannel = new EventChannel(binding.getBinaryMessenger(), "pp_battery_streams");
    this.bleManager.batteryStreamHandler = batteryStreamHandler;

    this.batteryEventChannel.setStreamHandler(batteryStreamHandler);

    // 蓝牙权限事件通道
    let blePermissionStreamHandler = new PPLefuStreamHandler()
    this.blePermissionEventChannel = new EventChannel(binding.getBinaryMessenger(), "pp_ble_permission_streams");
    this.bleManager.blePermissionStreamHandler = blePermissionStreamHandler;

    this.blePermissionEventChannel.setStreamHandler(blePermissionStreamHandler);

    // DFU事件通道
    let dfuStreamHandler = new PPLefuStreamHandler()
    this.dfuEventChannel = new EventChannel(binding.getBinaryMessenger(), "pp_dfu_streams");
    this.bleManager.dfuStreamHandler = dfuStreamHandler;
    this.dfuEventChannel.setStreamHandler(dfuStreamHandler);

    // 设备日志事件通道
    let deviceLogStreamHandler = new PPLefuStreamHandler()
    this.deviceLogEventChannel = new EventChannel(binding.getBinaryMessenger(), "device_log_streams");
    this.bleManager.deviceLogStreamHandler = deviceLogStreamHandler;
    this.deviceLogEventChannel.setStreamHandler(deviceLogStreamHandler);

    // 扫描状态事件通道
    let scanStateStreamHandler = new PPLefuStreamHandler()
    this.scanStateEventChannel = new EventChannel(binding.getBinaryMessenger(), "pp_scan_state_streams");
    this.bleManager.scanStateStreamHandler = scanStateStreamHandler;

    this.scanStateEventChannel.setStreamHandler(scanStateStreamHandler);

    // 设备日志事件通道
    let kitchenStreamHandler = new PPLefuStreamHandler()
    this.kitchenEventChannel = new EventChannel(binding.getBinaryMessenger(), "pp_kitchen_streams");
    this.bleManager.kitchenStreamHandler = kitchenStreamHandler;
    this.kitchenEventChannel.setStreamHandler(kitchenStreamHandler);
  }

  onAttachedToAbility(binding: AbilityPluginBinding) {
    PPLoggerPluginOhos.i("onAttachedToAbility")
    this.bleManager.onAttachedToAbility(binding)
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null);
    }
    if (this.bleChannel != null) {
      this.bleChannel.setMethodCallHandler(null);
    }
  }

  async onMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    const method = call.method;
    let params: Map<string, Object> = call.args;

    PPLoggerPluginOhos.i("onMethodCall: " + method)

    if (params) {
      params.forEach((value, key) => {
        PPLoggerPluginOhos.m("onMethodCall params:" + key + ": " + value)
      })
    } else {
      PPLoggerPluginOhos.e("onMethodCall params is null")
    }

    if (method == "getPlatformVersion") {
      result.success("HarmonyOS 桥接返回结果");
    } else if (method == "initSDK") {
      const appKey = params.get("appKey") as string;
      const appSecret = params.get("appSecret") as string;
      const deviceContent = params.get("deviceContent") as string;

      if (!appKey) {
        this.bleManager.loggerStreamHandler?.error("appKey为空");
        return;
      }
      if (!appSecret) {
        this.bleManager.loggerStreamHandler?.error("appSecret为空");
        return;
      }
      if (!deviceContent) {
        this.bleManager.loggerStreamHandler?.error("deviceContent为空");
        return;
      }

      PPBluetoothKit.addLoggerListener({
        d: (msg: string) => {
          this.bleManager.loggerStreamHandler?.success(msg);
        },

        e: (msg: string) => {
          this.bleManager.loggerStreamHandler?.error(msg);
        },

        i: (msg: string) => {
          this.bleManager.loggerStreamHandler?.success(msg);
        },

        w: (msg: string) => {
          this.bleManager.loggerStreamHandler?.success(msg);
        }
      })
      PPBluetoothKit.setDebug(true)
      // 调用鸿蒙蓝牙SDK初始化方法
      // this.bleManager.loadDevice(appKey, appSecret, deviceContent);
      ///SDK初始化Appkey和AppSecret在你自己的App中请替换为为你自己的Appkey和AppSecret,Appkey获取方式:https://xinzhiyun.feishu.cn/docx/VxXUdI86sorr96xSdn1cakkZndd?from=from_copylink
      //configPath内部配置文件路径，请替换为真实路径, SDK内部暂时未实现,下个版本会支持.后续更新时请更换为你自己的Appkey和AppSecret和configPath
      // this.bleManager.checkPermission();
      PPBluetoothKit.initSdk(this.context, appKey, appSecret, 'Device.json');
      result.success(true);
    } else if (method == "setDeviceSetting") {

      const deviceContent = params.get("deviceContent") as string;
      PPLoggerPluginOhos.i("setDeviceSetting len: " + deviceContent.length)
      PPLoggerPluginOhos.m("setDeviceSetting deviceContent: " + deviceContent)
      if (!deviceContent) {
        this.bleManager.loggerStreamHandler?.error("deviceContent为空");
        return;
      }
      PPBluetoothKit.addLoggerListener({
        d: (msg: string) => {
          this.bleManager.loggerStreamHandler?.success(msg);
        },

        e: (msg: string) => {
          this.bleManager.loggerStreamHandler?.error(msg);
        },

        i: (msg: string) => {
          this.bleManager.loggerStreamHandler?.success(msg);
        },

        w: (msg: string) => {
          this.bleManager.loggerStreamHandler?.success(msg);
        }
      });
      PPBluetoothKit.setDebug(true)
      PPBluetoothKit.setDeviceSetting(deviceContent);
      // this.bleManager.checkPermission();
    } else if (method == "startScan") {
      this.bleManager.startScan(result);
    } else if (method == "stopScan") {

      this.bleManager.stopScan();
      this.bleManager.sendCommonState(true, result)

    } else if (method == "connectDevice") {
      const deviceMac = params.get("deviceMac") as string;
      const deviceName = params.get("deviceName") as string;
      PPLoggerPluginOhos.d(`connectDevice deviceMac:${deviceMac} deviceName:${deviceName}`)
      if (!deviceMac) {
        this.bleManager.loggerStreamHandler?.success("deviceMac为空");
        return;
      }

      this.bleManager.connectDevice(deviceMac);
      result.success(true);
    } else if (method == "disconnect") {
      this.bleManager.disconnect();
      result.success({});
    } else if (method == "fetchHistory") {
      let userID = params.get("userID") as string
      let memberID = params.get("memberID") as string
      this.bleManager.fetchHistory(userID, memberID, result)
    } else if (method == "deleteHistory") {
      this.bleManager.deleteHistory()
    } else if (method == "syncUnit") {
      let unit = params.get("unit") as number ?? 0;
      let sex = params.get("sex") as number ?? 0;
      let age = params.get("age") as number ?? 18;
      let height = params.get("height") as number ?? 100;
      let isPregnantMode = params.get("isPregnantMode") as boolean ?? false;
      let isAthleteMode = params.get("isAthleteMode") as boolean ?? false;

      this.bleManager.syncUnit(unit, sex, age, height, isPregnantMode, isAthleteMode, result)
    } else if (method == "syncTime") {
      let is24Hour = params.get("is24Hour") as boolean ?? true;
      this.bleManager.syncTime(is24Hour, result)

    } else if (method == "changeBuzzerGate") {
      let isOpen = params.get("open") as boolean ?? true;
      this.bleManager.changeBuzzerGate(isOpen, result)

    } else if (method == "configWifi") {
      let domain = params.get("domain") as string ?? "";
      let ssId = params.get("ssId") as string ?? "";
      let password = params.get("password") as string ?? "";
      if (!domain) {
        result.success({
          success: false, errorCode: -1
        });
      } else if (!ssId) {
        result.success({
          success: false, errorCode: -1
        });
      }
      this.bleManager.configWifi(domain, ssId, password, result)
    } else if (method == "fetchWifiInfo") {
      this.bleManager.fetchWifiInfo(result)
    } else if (method == "fetchDeviceInfo") {
      this.bleManager.fetchDeviceInfo(result)
    } else if (method == "fetchBatteryInfo") {
      this.bleManager.fetchBatteryInfo(result)
    } else if (method == "resetDevice") {
      this.bleManager.resetDevice()
    } else if (method == "fetchConnectedDevice") {
      this.bleManager.fetchConnectedDevice(result)
    } else if (method == "addBlePermissionListener") {
      this.bleManager.addBlePermissionListener()
    } else if (method == "fetchWifiMac") {
      this.bleManager.fetchWifiMac(result)
    } else if (method == "scanWifiNetworks") {
      this.bleManager.scanWifiNetworks(result)
    } else if (method == "wifiOTA") {
      this.bleManager.wifiOTA(result)
    } else if (method == "heartRateSwitchControl") {
      const open = params.get("open") as boolean ?? false
      this.bleManager.heartRateSwitchControl(open, result)
    } else if (method == "fetchHeartRateSwitch") {
      this.bleManager.fetchHeartRateSwitch(result)
    } else if (method == "impedanceSwitchControl") {
      const open = params.get("open") as boolean ?? false
      this.bleManager.impedanceSwitchControl(open, result)
    } else if (method == "fetchImpedanceSwitch") {
      this.bleManager.fetchImpedanceSwitch(result)
    } else if (method == "setBindingState") {
      const binding = params.get("binding") as boolean ?? false
      this.bleManager.setBindingState(binding, result)
    } else if (method == "fetchBindingState") {
      this.bleManager.fetchBindingState(result)
    } else if (method == "setScreenBrightness") {
      const brightness = params.get("brightness") as number ?? 50
      this.bleManager.setScreenBrightness(brightness, result)
    } else if (method == "getScreenBrightness") {
      this.bleManager.getScreenBrightness(result)
    } else if (method == "syncUserInfo") {
      const model = this.getUserInfo(params)
      this.bleManager.syncUserInfo(model, result)

    } else if (method == "setRGBMode") {

      let defalutColor = params.get("defalutColor") as string ?? ""
      let gainColor = params.get("gainColor") as string ?? ""
      let lossColor = params.get("lossColor") as string ?? ""
      let lightEnable = params.get("lightEnable") as number ?? 0
      let lightMode = params.get("lightMode") as number ?? 0
      this.bleManager.setRGBMode(lightEnable,lightMode,defalutColor,gainColor,lossColor, result)


    } else if (method == "syncLast7Data") {

      const array = params.get("weightList") as Array<Record<string, Any>> ?? []
      const last7DaysArray: PPUserRecentBodyData[] = []

      for (const item of array) {
        const model = this.getUserRecentBodyData(item);
        last7DaysArray.push(model)
      }

      let userID = params.get("userID") as string ?? ""
      let memberID = params.get("memberID") as string ?? ""
      let targetWeight = params.get("targetWeight") as number ?? 0
      let idealWeight = params.get("idealWeight") as number ?? 0

      let user = new PPUserModel()
      user.userID = userID
      user.memberID = memberID
      user.targetWeight = targetWeight
      user.ideaWeight = idealWeight

      this.bleManager.syncLast7DaysDataUserInfo(user, last7DaysArray,result)
      this.bleManager.loggerStreamHandler?.success(`syncLast7Data params:${last7DaysArray} user:${user} params ${params.get("userID")}}`)

    } else if (method == "syncBorreCLast7Data") {

      const array = params.get("weightList") as Array<Record<string, Any>> ?? []
      const last7DaysArray: PPUserRecentBodyData[] = []

      for (const item of array) {
        const model = this.getUserRecentBodyData(item);
        last7DaysArray.push(model)
      }

      let userID = params.get("userID") as string ?? ""
      let memberID = params.get("memberID") as string ?? ""
      let targetWeight = params.get("targetWeight") as number ?? 0
      let idealWeight = params.get("idealWeight") as number ?? 0

      let user = new PPUserModel()
      user.userID = userID
      user.memberID = memberID
      user.targetWeight = targetWeight
      user.ideaWeight = idealWeight

      let type = params.get("type") as number ?? 1

      type = type - 1

      this.bleManager.syncBorreCLast7DaysDataUserInfo(user, last7DaysArray,type,result)
      this.bleManager.loggerStreamHandler?.success(`syncLast7Data params:${last7DaysArray} user:${user} params ${params.get("userID")}}`)
    } else if (method == "syncUserList") {
      const userArray: PPUserModel[] = []
      const array = params.get("userList") as Array<Record<string, Any>> ?? []

      for (const item of array) {
        const model = this.getUserInfo(item)
        userArray.push(model)
      }

      this.bleManager.loggerStreamHandler?.success(`下发用户数量:${userArray.length}`)
      this.bleManager.syncUserList(userArray, result)
    } else if (method == "fetchUserIDList") {
      this.bleManager.fetchUserIDList(result)
    } else if (method == "selectUser") {
      const userID = params.get("userID") as string ?? ""
      const memberID = params.get("memberID") as string ?? ""

      const user = new PPUserModel()
      user.userID = userID
      user.memberID = memberID

      this.bleManager.selectUser(user, result)
    } else if (method == "deleteUser") {
      const userID = params.get("userID") as string ?? ""
      const memberID = params.get("memberID") as string ?? ""

      const user = new PPUserModel()
      user.userID = userID
      user.memberID = memberID

      this.bleManager.loggerStreamHandler?.success(`删除用户:${user.userID}  memberid ${user.memberID}`)


      this.bleManager.deleteUser(user, result)
    } else if (method == "startMeasure") {
      this.bleManager.startMeasure(result)
    } else if (method == "stopMeasure") {
      this.bleManager.stopMeasure(result)
    } else if (method == "startBabyModel") {
      const step = params.get("step") as number ?? 0
      const weight = params.get("weight") as number ?? 0

      this.bleManager.startBabyModel(step, weight, result)
    } else if (method == "exitBabyModel") {
      this.bleManager.exitBabyModel(result)
    } else if (method == "startDFU") {
      const filePath = params.get("filePath") as string ?? ""
      const deviceFirmwareVersion = params.get("deviceFirmwareVersion") as string ?? ""
      const isForceCompleteUpdate = params.get("isForceCompleteUpdate") as boolean ?? false

      this.bleManager.startDFU(filePath, deviceFirmwareVersion, isForceCompleteUpdate, result)
    } else if (method == "syncDeviceLog") {
      const logFolder = params.get("logFolder") as string ?? ""
      this.bleManager.syncDeviceLog(logFolder)
    } else if (method == "keepAlive") {
      this.bleManager.keepAlive()
    } else if (method == "clearDeviceData") {
      const type = params.get("type") as number ?? 0
      this.bleManager.clearDeviceData(type, result)
    } else if (method == "setDeviceLanguage") {
      const type = params.get("type") as number ?? 0
      this.bleManager.setDeviceLanguage(type, result)
    } else if (method == "fetchDeviceLanguage") {
      this.bleManager.fetchDeviceLanguage(result)
    } else if (method == "setDisplayBodyFat") {
      const bodyFat = params.get("bodyFat") as number ?? 0
      this.bleManager.setDisplayBodyFat(bodyFat, result)
    } else if (method == "exitScanWifiNetworks") {
      this.bleManager.exitScanWifiNetworks(result)
    } else if (method == "exitNetworkConfig") {
      this.bleManager.exitNetworkConfig(result)

    } else if (method == "toZero") {
      this.bleManager.toZero(result)
      this.bleManager.sendCommonState(true, result)
    } else if (method == "receiveBroadcastData") {
      const deviceMac = params.get("deviceMac") as string

      if (!deviceMac) {
        this.bleManager.loggerStreamHandler?.success("deviceMac为空")
        this.bleManager.sendCommonState(false, result)
        return
      }

      this.bleManager.receiveBroadcastData(deviceMac, result)
    } else if (method == "unReceiveBroadcastData") {
      const deviceMac = params.get("deviceMac") as string

      if (!deviceMac) {
        this.bleManager.loggerStreamHandler?.success("deviceMac为空")
        this.bleManager.sendCommonState(false, result)
        return
      }

      this.bleManager.unReceiveBroadcastData(deviceMac, result)

    } else if (method == "setDisplayMetrics") {

      const metrics = params.get("metrics") as number  ?? 1

      this.bleManager.loggerStreamHandler?.success(`metrics1 ${metrics}`)

      this.bleManager.setDisplayMetrics(metrics)


    } else if (method == "getDisplayMetrics") {

      this.bleManager.getDisplayMetrics(result)


    } else if (method == "sendBroadcastData") {
      const cmd = params.get("cmd") as string
      const unit = params.get("unit") as number ?? 0

      if (!cmd) {
        this.bleManager.loggerStreamHandler?.success("cmd为空")
        this.bleManager.sendCommonState(false, result)
        return
      }

      this.bleManager.sendBroadcastData(cmd, unit, result)
    }
  }

  private getUserInfo(params: Record<string, Any>): PPUserModel {
    const userID = params.get("userID") as string ?? ""
        const pIndex = params.get("pIndex") as number ?? 0

    const memberID = params.get("memberID") as string ?? ""
    const isPregnantMode = params.get("isPregnantMode") as boolean ?? false
    const isAthleteMode = params.get("isAthleteMode") as boolean ?? false
    const unitType = params.get("unitType") as number ?? 0
    const age = params.get("age") as number ?? 0
    const sex = params.get("sex") as number ?? 0
    const userHeight = params.get("userHeight") as number ?? 0
    const userName = params.get("userName") as string ?? ""
    const deviceHeaderIndex = params.get("deviceHeaderIndex") as number ?? 0
    const currentWeight = params.get("currentWeight") as number ?? 0
    const targetWeight = params.get("targetWeight") as number ?? 0
    const idealWeight = params.get("idealWeight") as number ?? 0
    const recentData = params.get("recentData") as Array<Record<string, Any>> ?? []

    const model = new PPUserModel()

    for (const item of recentData) {
      const weightKg = item["weightKg"] as number ?? 0
      const timeStamp = item["timeStamp"] as number ?? 0

      model.userWeightArray?.push(weightKg)
      model.userWeightTimeArray?.push(timeStamp)
    }

    model.isPregnantMode = isPregnantMode ?? false
    model.isAthleteMode = isAthleteMode ?? false
    model.age = age ?? 18
    model.sex = sex ?? PPUserGender.PPUserGenderFemale
    model.userHeight = userHeight
    model.userID = userID
    model.memberID = memberID
    model.userName = userName
    model.deviceHeaderIndex = deviceHeaderIndex
    model.weightKg = currentWeight
    model.targetWeight = targetWeight
    model.ideaWeight = idealWeight
    model.PIndex = pIndex
    return model  
  }

  private getUserRecentBodyData(record: Record<string, Any>): PPUserRecentBodyData {
    const data = new PPUserRecentBodyData();
    // 逐项解析record中的字段并赋值
    data.value = record.get("value") as number ?? 0;
    data.timeStamp = record.get("timeStamp") as number ?? 0;
    data.bmi = record.get("bmi") as number ?? 0;
    data.bodyfat = record.get("bodyfat") as number ?? 0;
    data.heartRate = record.get("heartRate") as number ?? 0;
    data.muscleRate = record.get("muscleRate") as number ?? 0;
    data.muscle = record.get("muscle") as number ?? 0;
    data.bone = record.get("bone") as number ?? 0;
    data.boneRate = record.get("boneRate") as number ?? 0;
    data.waterRate = record.get("waterRate") as number ?? 0;

    return data;
  }
}
