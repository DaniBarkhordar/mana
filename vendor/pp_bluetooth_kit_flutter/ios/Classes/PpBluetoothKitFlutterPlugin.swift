import Flutter
import PPBaseKit
import PPBluetoothKit
import UIKit

public class PpBluetoothKitFlutterPlugin: NSObject, FlutterPlugin {

    var bleManager: PPLefuBleConnectManager = PPLefuBleConnectManager()

    public static func register(with registrar: FlutterPluginRegistrar) {

        let channel = FlutterMethodChannel(
            name: "pp_bluetooth_kit_flutter", binaryMessenger: registrar.messenger())
        let instance = PpBluetoothKitFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        let bleChannel = FlutterMethodChannel(
            name: "pp_ble_channel", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: bleChannel)

        let measureStreamHandler = PPLefuStreamHandler()
        instance.bleManager.measureStreamHandler = measureStreamHandler
        let measureEventChannel = FlutterEventChannel(
            name: "pp_measurement_streams", binaryMessenger: registrar.messenger())
        measureEventChannel.setStreamHandler(measureStreamHandler)

        let loggerStreamHandler = PPLefuStreamHandler()
        instance.bleManager.loggerStreamHandler = loggerStreamHandler
        let loggerEventChannel = FlutterEventChannel(
            name: "pp_logger_streams", binaryMessenger: registrar.messenger())
        loggerEventChannel.setStreamHandler(loggerStreamHandler)

        let connectStateStreamHandler = PPLefuStreamHandler()
        instance.bleManager.connectStateStreamHandler = connectStateStreamHandler
        let connectStateEventChannel = FlutterEventChannel(
            name: "pp_connect_state_streams", binaryMessenger: registrar.messenger())
        connectStateEventChannel.setStreamHandler(connectStateStreamHandler)

        let scanResultStreamHandler = PPLefuStreamHandler()
        instance.bleManager.scanResultStreamHandler = scanResultStreamHandler
        let scanEventChannel = FlutterEventChannel(
            name: "pp_device_list_streams", binaryMessenger: registrar.messenger())
        scanEventChannel.setStreamHandler(scanResultStreamHandler)

        let historyStreamHandler = PPLefuStreamHandler()
        instance.bleManager.historyStreamHandler = historyStreamHandler
        let historyEventChannel = FlutterEventChannel(
            name: "pp_history_data_streams", binaryMessenger: registrar.messenger())
        historyEventChannel.setStreamHandler(historyStreamHandler)

        let batteryStreamHandler = PPLefuStreamHandler()
        instance.bleManager.batteryStreamHandler = batteryStreamHandler
        let batteryEventChannel = FlutterEventChannel(
            name: "pp_battery_streams", binaryMessenger: registrar.messenger())
        batteryEventChannel.setStreamHandler(batteryStreamHandler)

        let blePermissionStreamHandler = PPLefuStreamHandler()
        instance.bleManager.blePermissionStreamHandler = blePermissionStreamHandler
        let blePermissionEventChannel = FlutterEventChannel(
            name: "pp_ble_permission_streams", binaryMessenger: registrar.messenger())
        blePermissionEventChannel.setStreamHandler(blePermissionStreamHandler)

        let dfuStreamHandler = PPLefuStreamHandler()
        instance.bleManager.dfuStreamHandler = dfuStreamHandler
        let dfuEventChannel = FlutterEventChannel(
            name: "pp_dfu_streams", binaryMessenger: registrar.messenger())
        dfuEventChannel.setStreamHandler(dfuStreamHandler)

        let deviceLogStreamHandler = PPLefuStreamHandler()
        instance.bleManager.deviceLogStreamHandler = deviceLogStreamHandler
        let deviceLogEventChannel = FlutterEventChannel(
            name: "device_log_streams", binaryMessenger: registrar.messenger())
        deviceLogEventChannel.setStreamHandler(deviceLogStreamHandler)

        let scanStateStreamHandler = PPLefuStreamHandler()
        instance.bleManager.scanStateStreamHandler = scanStateStreamHandler
        let scanStateEventChannel = FlutterEventChannel(
            name: "pp_scan_state_streams", binaryMessenger: registrar.messenger())
        scanStateEventChannel.setStreamHandler(scanStateStreamHandler)

        let kitchenStreamHandler = PPLefuStreamHandler()
        instance.bleManager.kitchenStreamHandler = kitchenStreamHandler
        let kitchenEventChannel = FlutterEventChannel(
            name: "pp_kitchen_streams", binaryMessenger: registrar.messenger())
        kitchenEventChannel.setStreamHandler(kitchenStreamHandler)

    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let method = call.method

        let params = call.arguments as? [String: Any?]
        //      let peripheralType = params?["peripheralType"] as? Int

        if method == "getPlatformVersion" {
            result("iOS 桥接返回结果:" + UIDevice.current.systemVersion)

        } else if method == "initSDK" {

            let appKey = params?["appKey"] as? String
            let appSecret = params?["appSecret"] as? String
            let deviceContent = params?["deviceContent"] as? String

            guard let appKey = appKey else {
                self.bleManager.loggerStreamHandler?.event?("appKey为空")
                return
            }
            guard let appSecret = appSecret else {
                self.bleManager.loggerStreamHandler?.event?("appSecret为空")
                return
            }
            guard let deviceContent = deviceContent else {
                self.bleManager.loggerStreamHandler?.event?("deviceContent为空")
                return
            }

            PPBluetoothManager.loadDevice(
                withAppKey: appKey, appSecrect: appSecret, configContent: deviceContent)
            self.bleManager.sendCommonState(true, callBack: result)

        } else if method == "setDeviceSetting" {

            let deviceContent = params?["deviceContent"] as? String

            guard let deviceContent = deviceContent else {
                self.bleManager.loggerStreamHandler?.event?("deviceContent为空")
                return
            }

            if let jsonData = deviceContent.data(using: .utf8) {
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
                    if let array = jsonObject as? [Any] {

                        PPBluetoothManager.loadDevice(withJsonData: array)

                    } else {
                        self.bleManager.loggerStreamHandler?.event?("设备列表-转JSON失败")
                    }
                } catch {
                    self.bleManager.loggerStreamHandler?.event?("转JSON异常: \(error)")
                }
            } else {
                self.bleManager.loggerStreamHandler?.event?("转JSON DATA失败")
            }

        } else if method == "startScan" {

            bleManager.startScan(callBack: result)

        } else if method == "stopScan" {

            bleManager.stopScan()
            self.bleManager.sendCommonState(true, callBack: result)
        } else if method == "connectDevice" {

            let deviceMac = params?["deviceMac"] as? String
            let deviceName = params?["deviceName"] as? String

            guard let deviceMac = deviceMac else {
                self.bleManager.loggerStreamHandler?.event?("deviceMac为空")
                return
            }
            guard let deviceName = deviceName else {
                self.bleManager.loggerStreamHandler?.event?("deviceName为空")
                return
            }

            self.bleManager.connectDevice(deviceMac: deviceMac, deviceName: deviceName)

        } else if method == "disconnect" {

            self.bleManager.disconnect()

            result([:])

        } else if method == "fetchHistory" {

            let userID = params?["userID"] as? String ?? ""
            let memberID = params?["memberID"] as? String ?? ""

            let model = PPTorreSettingModel()
            model.userID = userID
            model.memberID = memberID
            self.bleManager.fetchHistory(model: model)

        }  else if method == "deleteHistory" {
            self.bleManager.deleteHistory()
        } else if method == "syncUnit" {

            let unit = params?["unit"] as? Int
            let sex = params?["sex"] as? Int
            let age = params?["age"] as? Int
            let height = params?["height"] as? Int
            let isPregnantMode = params?["isPregnantMode"] as? Bool
            let isAthleteMode = params?["isAthleteMode"] as? Bool

            //           self.bleManager.loggerStreamHandler?.event?("同步单位，参数：\(params ?? [:])")

            let model = PPBluetoothDeviceSettingModel()
            model.unit = PPDeviceUnit(rawValue: UInt(unit ?? 0)) ?? .unitKG
            model.gender = PPDeviceGenderType(rawValue: UInt(sex ?? 0)) ?? .female
            model.age = age ?? 0
            model.height = height ?? 0
            model.isPregnantMode = isPregnantMode ?? false
            model.isAthleteMode = isAthleteMode ?? false

            self.bleManager.syncUnit(model: model, callBack: result)

        } else if method == "syncTime" {

            let is24Hour = params?["is24Hour"] as? Bool ?? true
            self.bleManager.syncTime(is24Hour: is24Hour, callBack: result)

        } else if method == "configWifi" {
            let domain = params?["domain"] as? String
            let ssId = params?["ssId"] as? String
            var password = params?["password"] as? String ?? ""

            guard let domain = domain else {
                result(["success": false, "errorCode": -1])
                return
            }

            guard let ssId = ssId else {
                result(["success": false, "errorCode": -1])
                return
            }

            //          guard let pwd = password else {
            //              password = ""
            //          }

            self.bleManager.configWifi(
                domain: domain, ssId: ssId, password: password, callBack: result)

        } else if method == "fetchWifiInfo" {

            self.bleManager.fetchWifiInfo(result)
        } else if method == "fetchDeviceInfo" {

            self.bleManager.fetchDeviceInfo(result)
        } else if method == "fetchBatteryInfo" {

            self.bleManager.fetchBatteryInfo()
        } else if method == "resetDevice" {

            self.bleManager.resetDevice()
        } else if method == "fetchConnectedDevice" {

            self.bleManager.fetchConnectedDevice(callBack: result)
        } else if method == "addBlePermissionListener" {

            self.bleManager.addBlePermissionListener()
        } else if method == "fetchWifiMac" {

            self.bleManager.fetchWifiMac(result)
        } else if method == "scanWifiNetworks" {

            self.bleManager.scanWifiNetworks(result)
        } else if method == "wifiOTA" {

            self.bleManager.wifiOTA(result)
        } else if method == "heartRateSwitchControl" {

            let open = params?["open"] as? Bool ?? false
            self.bleManager.heartRateSwitchControl(open: open, result)
        } else if method == "fetchHeartRateSwitch" {

            self.bleManager.fetchHeartRateSwitch(result)
        } else if method == "impedanceSwitchControl" {

            let open = params?["open"] as? Bool ?? false
            self.bleManager.impedanceSwitchControl(open: open, result)
        } else if method == "fetchImpedanceSwitch" {

            self.bleManager.fetchImpedanceSwitch(result)
        } else if method == "setBindingState" {

            let binding = params?["binding"] as? Bool ?? false
            self.bleManager.setBindingState(binding: binding, result)
        } else if method == "fetchBindingState" {

            self.bleManager.fetchBindingState(result)
        } else if method == "setScreenBrightness" {

            let brightness = params?["brightness"] as? Int ?? 50
            self.bleManager.setScreenBrightness(brightness, result)
        } else if method == "getScreenBrightness" {

            self.bleManager.getScreenBrightness(result)
        } else if method == "syncUserInfo" {

            let model = getUserInfo(params: params)

            self.bleManager.syncUserInfo(model, callBack: result)
        } else if method == "syncUserList" {

            self.bleManager.loggerStreamHandler?.event?("不支持 syncUserList 方法")
            result(["state": false])

            //          var userArray = [PPTorreSettingModel]()
            //
            //          let array = params?["userList"] as? [[String:Any?]] ?? []
            //          for item in array {
            //              let model = getUserInfo(params: item)
            //              userArray.append(model)
            //          }
            //
            //          self.bleManager.loggerStreamHandler?.event?("下发用户数量:\(userArray.count)")
            //          self.bleManager.syncUserList(userArray, callBack: result)
        } else if method == "fetchUserIDList" {

            self.bleManager.fetchUserIDList(result)
        } else if method == "selectUser" {

            let userID = params?["userID"] as? String ?? ""
            let memberID = params?["memberID"] as? String ?? ""

            let user = PPTorreSettingModel()
            user.userID = userID
            user.memberID = memberID

            self.bleManager.selectUser(user: user, callBack: result)

        } else if method == "deleteUser" {

            let userID = params?["userID"] as? String ?? ""
            var memberID = params?["memberID"] as? String ?? ""

            if memberID == "" {
                memberID = "ff"
            }

            let user = PPTorreSettingModel()
            user.userID = userID
            user.memberID = memberID

            self.bleManager.deleteUser(user: user, callBack: result)
        } else if method == "startMeasure" {

            self.bleManager.startMeasure(result)
        } else if method == "stopMeasure" {

            self.bleManager.stopMeasure(result)
        } else if method == "startBabyModel" {

            let step = params?["step"] as? Int ?? 0
            let weight = params?["weight"] as? Int ?? 0

            self.bleManager.startBabyModel(step: step, weight: weight, result)
        } else if method == "exitBabyModel" {

            self.bleManager.exitBabyModel(result)
        } else if method == "startDFU" {

            let filePath = params?["filePath"] as? String ?? ""
            let deviceFirmwareVersion = params?["deviceFirmwareVersion"] as? String ?? ""
            let isForceCompleteUpdate = params?["isForceCompleteUpdate"] as? Bool ?? false

            self.bleManager.startDFU(
                filePath: filePath, deviceFirmwareVersion: deviceFirmwareVersion,
                isForceCompleteUpdate: isForceCompleteUpdate, result)

        } else if method == "syncDeviceLog" {

            let logFolder = params?["logFolder"] as? String ?? ""
            self.bleManager.syncDeviceLog(logFolder: logFolder)
        } else if method == "keepAlive" {

            self.bleManager.keepAlive()
        } else if method == "clearDeviceData" {

            let type = params?["type"] as? Int ?? 0
            self.bleManager.clearDeviceData(type: type, callBack: result)
        } else if method == "setDeviceLanguage" {

            let type = params?["type"] as? Int ?? 0
            self.bleManager.setDeviceLanguage(type: type, callBack: result)

        } else if method == "fetcgDeviceLanguage" {
            self.bleManager.fetchDeviceLanguage(callBack: result)
        } else if method == "setDisplayBodyFat" {

            let bodyFat = params?["bodyFat"] as? Int ?? 0
            self.bleManager.setDisplayBodyFat(bodyFat, callBack: result)
        } else if method == "exitScanWifiNetworks" {

            self.bleManager.exitScanWifiNetworks(callBack: result)
        } else if method == "exitNetworkConfig" {

            self.bleManager.exitNetworkConfig(callBack: result)
        } else if method == "receiveBroadcastData" {

            let deviceMac = params?["deviceMac"] as? String

            guard let deviceMac = deviceMac else {
                self.bleManager.loggerStreamHandler?.event?("deviceMac为空")
                self.bleManager.sendCommonState(false, callBack: result)
                return
            }

            self.bleManager.receiveBroadcastData(deviceMac: deviceMac, callBack: result)
        } else if method == "unReceiveBroadcastData" {

            let deviceMac = params?["deviceMac"] as? String

            guard let deviceMac = deviceMac else {
                self.bleManager.loggerStreamHandler?.event?("deviceMac为空")
                self.bleManager.sendCommonState(false, callBack: result)
                return
            }

            self.bleManager.unReceiveBroadcastData(deviceMac: deviceMac, callBack: result)
        } else if method == "sendBroadcastData" {

            let cmd = params?["cmd"] as? String
            let unit = params?["unit"] as? Int
            let unitType = PPDeviceUnit(rawValue: UInt(unit ?? 0)) ?? .unitKG

            guard let cmd = cmd else {
                self.bleManager.loggerStreamHandler?.event?("cmd为空")
                self.bleManager.sendCommonState(false, callBack: result)
                return
            }

            self.bleManager.sendBroadcastData(cmd: cmd, unitType: unitType, callBack: result)

        } else if method == "changeBuzzerGate" {

            let open = params?["open"] as? Bool ?? true
            self.bleManager.changeBuzzerGate(isOpen: open, callBack: result)

        } else if method == "toZero" {
            self.bleManager.toZero(callBack: result)
        } else if method == "syncLast7Data" {

            var recentList = [PPUserRecentBodyData]()
            let list = params?["weightList"] as? [[String: Any]] ?? []
            for item in list {
                let data = PPUserRecentBodyData()
                data.timeStamp = Double(item["timeStamp"] as? Int64 ?? 0)
                data.value = item["value"] as? Int ?? 0
                recentList.append(data)
            }

            let last = PPUserRecentBodyData()
            last.bmi = CGFloat(params?["lastBMI"] as? Int ?? 0)
            last.muscleRate = CGFloat(params?["lastMuscleRate"] as? Int ?? 0)
            last.waterRate = CGFloat(params?["lastWaterRate"] as? Int ?? 0)
            last.bodyfat = CGFloat(params?["lastBodyFat"] as? Int ?? 0)
            last.heartRate = CGFloat(params?["lastHeartRate"] as? Int ?? 0)
            last.muscle = CGFloat(params?["lastMuscle"] as? Int ?? 0)
            last.bone = CGFloat(params?["lastBone"] as? Int ?? 0)
            last.boneRate = CGFloat(params?["lastBoneRate"] as? Int ?? 0)

            let typeValue = params?["type"] as? Int ?? 0
            let type = PPUserBodyDataType(rawValue: typeValue) ?? .weight

            let user = PPTorreSettingModel()
            user.userID = params?["userID"] as? String ?? ""
            user.memberID = params?["memberID"] as? String ?? ""
            user.targetWeight = params?["targetWeight"] as? CGFloat ?? 0
            user.idealWeight = params?["idealWeight"] as? CGFloat ?? 0

            self.bleManager.syncLast7Data(
                recentList: recentList, lastBodyData: last, type: type, user: user, callBack: result
            )

        } else if method == "syncBorreCLast7Data" {

            var recentList = [PPUserBodyData]()
            let list = params?["weightList"] as? [[String: Any]] ?? []
            for item in list {
                let data = PPUserBodyData()
                data.timeStamp = Double(item["timeStamp"] as? Int64 ?? 0)
                data.value = item["value"] as? CGFloat ?? 0
                recentList.append(data)
            }

            let typeValue = params?["type"] as? Int ?? 0
            let type = PPUserBodyDataType(rawValue: typeValue) ?? .weight

            let lastBody = recentList.last

            let user = PPTorreSettingModel()
            user.userID = params?["userID"] as? String ?? ""
            user.memberID = params?["memberID"] as? String ?? ""
            user.targetWeight = params?["targetWeight"] as? CGFloat ?? 0
            user.idealWeight = params?["idealWeight"] as? CGFloat ?? 0

            self.bleManager.syncBorreCLast7DaysData(
                recentList: recentList, lastBodyData: lastBody ?? PPUserBodyData(), type: type,
                user: user, callBack: result)
        } else if method == "setRGBMode" {

            let defalutColor = params?["defalutColor"] as? String ?? ""
            let gainColor = params?["gainColor"] as? String ?? ""
            let lossColor = params?["lossColor"] as? String ?? ""
            let lightEnable = params?["lightEnable"] as? Int ?? 0
            let lightMode = params?["lightMode"] as? Int ?? 0

            self.bleManager.setRGBMode(
                lightEnable: lightEnable, lightMode: lightMode, defalutColor: defalutColor,
                gainColor: gainColor, lossColor: lossColor, callBack: result)

        } else if method == "fetchUserInfoList" {

            self.bleManager.fetchUserInfoList(callBack: result)
        } else if method == "foodScaleUnit" {

            let weightG = params?["weightG"] as? CGFloat ?? 0
            let accuracyType = params?["accuracyType"] as? Int ?? 0
            let unitType = params?["unitType"] as? Int ?? 4
            let deviceName = params?["deviceName"] as? String ?? ""

            self.bleManager.foodScaleUnit(
                weightG: weightG, accuracyType: accuracyType, unitType: unitType,
                deviceName: deviceName, callBack: result)

        } else if method == "getDisplayMetrics" {

            self.bleManager.getDisplayMetrics(callBack: result)

        } else if method == "setDisplayMetrics" {

            let metrics = params?["metrics"] as? Int ?? 0

            self.bleManager.setDisplayMetrics(metrics, callBack: result)

        } else if method == "registerFingerprint" {

            let userID = params?["userID"] as? String ?? ""
            let memberID = params?["memberID"] as? String ?? ""

            let user = PPTorreSettingModel()
            user.userID = userID
            user.memberID = memberID

            self.bleManager.registerFingerprint(user: user, callBack: result)

        } else if method == "deleteFingerprint" {

            let userID = params?["userID"] as? String ?? ""
            let memberID = params?["memberID"] as? String ?? ""

            let user = PPTorreSettingModel()
            user.userID = userID
            user.memberID = memberID

            self.bleManager.deleteFingerprint(user: user, callBack: result)

        } else if method == "fetchFingerprintList" {

            self.bleManager.fetchFingerprintList(callBack: result)
        }

    }

    func getUserInfo(params: [String: Any?]?) -> PPTorreSettingModel {

        let userID = params?["userID"] as? String ?? ""
        let memberID = params?["memberID"] as? String ?? ""
        let isPregnantMode = params?["isPregnantMode"] as? Bool ?? false
        let isAthleteMode = params?["isAthleteMode"] as? Bool ?? false
        let unitType = params?["unitType"] as? Int ?? 0
        let age = params?["age"] as? Int ?? 0
        let sex = params?["sex"] as? Int ?? 0
        let userHeight = params?["userHeight"] as? Int ?? 0
        let userName = params?["userName"] as? String ?? ""
        let deviceHeaderIndex = params?["deviceHeaderIndex"] as? Int ?? 0
        let currentWeight = params?["currentWeight"] as? CGFloat ?? 0
        let targetWeight = params?["targetWeight"] as? CGFloat ?? 0
        let idealWeight = params?["idealWeight"] as? CGFloat ?? 0
        let recentData = params?["recentData"] as? [[String: Any?]] ?? []
        let pIndex = params?["pIndex"] as? Int ?? 0

        var historyList = [PPUserHistoryData]()
        for item in recentData {
            let weightKg = item["weightKg"] as? CGFloat ?? 0
            let timeStamp = item["timeStamp"] as? Double ?? 0

            let history = PPUserHistoryData()
            history.weightKg = weightKg
            history.timeStamp = timeStamp

            historyList.append(history)
        }

        let model = PPTorreSettingModel()
        model.isPregnantMode = isPregnantMode
        model.isAthleteMode = isAthleteMode
        model.unit = PPDeviceUnit(rawValue: UInt(unitType)) ?? .unitKG
        model.age = age
        model.gender = PPDeviceGenderType(rawValue: UInt(sex)) ?? .female
        model.height = userHeight
        model.userID = userID
        model.memberID = memberID
        model.userName = userName
        model.deviceHeaderIndex = deviceHeaderIndex
        model.currentWeight = currentWeight
        model.targetWeight = targetWeight
        model.idealWeight = idealWeight
        model.recentData = historyList
        model.pIndex = pIndex

        return model
    }
    
 
}
