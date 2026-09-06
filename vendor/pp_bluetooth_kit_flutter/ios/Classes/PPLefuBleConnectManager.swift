//
//  LefuBleConnectManager.swift
//  Pods
//
//  Created by lefu on 2025/3/25
//

import Flutter
import Foundation
import PPBaseKit
import PPBluetoothKit

enum PPLefuScanType: Int {
    case scan = 0

}

public class PPLefuBleConnectManager: NSObject {

    var scanResultStreamHandler: PPLefuStreamHandler?
    var loggerStreamHandler: PPLefuStreamHandler?
    var connectStateStreamHandler: PPLefuStreamHandler?
    var measureStreamHandler: PPLefuStreamHandler?
    var historyStreamHandler: PPLefuStreamHandler?
    var batteryStreamHandler: PPLefuStreamHandler?
    var blePermissionStreamHandler: PPLefuStreamHandler?
    var dfuStreamHandler: PPLefuStreamHandler?
    var deviceLogStreamHandler: PPLefuStreamHandler?
    var scanStateStreamHandler: PPLefuStreamHandler?

    var kitchenStreamHandler: PPLefuStreamHandler?

    lazy var scaleManager: PPBluetoothConnectManager = PPBluetoothConnectManager()

    private var bluetoothState: PPBluetoothState?
    private var needScan = false
    private var scanType: PPLefuScanType = .scan
    private var isScaning: Bool = false

    private var connectState: Int = 0
    private var tempScaleHistoryList: [PPBluetoothScaleBaseModel]?

    private var lastDisconnectTime: TimeInterval = 0
    private var isProcessingDisconnect: Bool = false

    private var durianMeasurementHandler: PPDurianMeasurementHandler?

    var currentDevice: PPBluetoothAdvDeviceModel?
    var appleControl: PPBluetoothPeripheralApple?
    var coconutControl: PPBluetoothPeripheralCoconut?
    var torreControl: PPBluetoothPeripheralTorre?
    var iceControl: PPBluetoothPeripheralIce?
    var bananaControl: PPBluetoothPeripheralBanana?
    var jambulControl: PPBluetoothPeripheralJambul?
    var borreControl: PPBluetoothPeripheralBorre?
    var forreControl: PPBluetoothPeripheralForre?
    var fishControl: PPBluetoothPeripheralFish?
    var eggControl: PPBluetoothPeripheralEgg?
    var hamburgerControl: PPBluetoothPeripheralHamburger?
    var grapesControl: PPBluetoothPeripheralGrapes?
    var durianControl: PPBluetoothPeripheralDurian?
    var dorreControl: PPBluetoothPeripheralDorre?

    var unzipFilePath: String?
    var dfuConfig: PPDfuPackageModel?
    var current180A: PPBluetooth180ADeviceModel?

    private var tempDeviceDict = [String: (PPBluetoothAdvDeviceModel, CBPeripheral)]()

    override init() {
        super.init()

        PPLog.setLogEnable(false)
        PPLog.sharedInstance().logBlock = { [weak self] logStr in
            guard let `self` = self else {
                return
            }
            print(logStr)

            self.loggerStreamHandler?.event?(logStr)

        }
    }

    func startScan(callBack: @escaping FlutterResult) {

        self.stopScan()
        self.disconnect()

        self.tempDeviceDict.removeAll()

        scanDevice(type: .scan, callBack: callBack)
    }

    func scanDevice(type: PPLefuScanType, callBack: @escaping FlutterResult) {

        self.scanType = type
        self.needScan = true

        self.scaleManager = PPBluetoothConnectManager()
        self.scaleManager.updateStateDelegate = self
        self.scaleManager.surroundDeviceDelegate = self

        self.sendCommonState(true, callBack: callBack)
    }

    func connectDevice(deviceMac: String, deviceName: String) {

        if self.currentDevice?.deviceMac == deviceMac {
            self.loggerStreamHandler?.event?("\(deviceMac)-该设备已连接，继续使用")
            sendConnectState(1)

            return
        }

        self.stopScan()
        self.disconnect()

        if let model = self.tempDeviceDict[deviceMac] {

            let device = model.0
            let peripheral = model.1

            self.currentDevice = device
            self.scaleManager.connectDelegate = self

            self.loggerStreamHandler?.event?(
                "开始连接设备:\(device.deviceName) mac:\(device.deviceMac) \(device.peripheralType)")

            let peripheralType = device.peripheralType
            switch peripheralType {
            case .peripheralApple:
                self.scaleManager.connect(peripheral, withDevice: device)

                self.appleControl = PPBluetoothPeripheralApple(
                    peripheral: peripheral, andDevice: device)
                self.appleControl?.serviceDelegate = self
                self.appleControl?.cmdDelegate = self
            case .peripheralCoconut:
                self.scaleManager.connect(peripheral, withDevice: device)

                self.coconutControl = PPBluetoothPeripheralCoconut(
                    peripheral: peripheral, andDevice: device)
                self.coconutControl?.serviceDelegate = self
                self.coconutControl?.cmdDelegate = self
            case .peripheralTorre:
                self.scaleManager.connect(peripheral, withDevice: device)

                self.torreControl = PPBluetoothPeripheralTorre(
                    peripheral: peripheral, andDevice: device)
                self.torreControl?.serviceDelegate = self
            case .peripheralIce:
                self.scaleManager.connect(peripheral, withDevice: device)

                self.iceControl = PPBluetoothPeripheralIce(
                    peripheral: peripheral, andDevice: device)
                self.iceControl?.serviceDelegate = self
            case .peripheralBorre:
                self.scaleManager.connect(peripheral, withDevice: device)

                self.borreControl = PPBluetoothPeripheralBorre(
                    peripheral: peripheral, andDevice: device)
                self.borreControl?.serviceDelegate = self
            case .peripheralForre:
                self.scaleManager.connect(peripheral, withDevice: device)

                self.forreControl = PPBluetoothPeripheralForre(
                    peripheral: peripheral, andDevice: device)
                self.forreControl?.serviceDelegate = self
            case .peripheralFish:
                self.scaleManager.connect(peripheral, withDevice: device)
                self.fishControl = PPBluetoothPeripheralFish(
                    peripheral: peripheral, andDevice: device)
                self.fishControl?.serviceDelegate = self
            case .peripheralEgg:
                self.scaleManager.connect(peripheral, withDevice: device)
                self.eggControl = PPBluetoothPeripheralEgg(
                    peripheral: peripheral, andDevice: device)
                self.eggControl?.serviceDelegate = self
            case .peripheralDurian:
                self.scaleManager.connect(peripheral, withDevice: device)

                self.durianControl = PPBluetoothPeripheralDurian(
                    peripheral: peripheral, andDevice: device)
                self.durianControl?.serviceDelegate = self
                self.durianControl?.cmdDelegate = self
            case .peripheralDorre:
                self.scaleManager.connect(peripheral, withDevice: device)

                self.dorreControl = PPBluetoothPeripheralDorre(
                    peripheral: peripheral, andDevice: device)
                self.dorreControl?.serviceDelegate = self

            default:
                self.loggerStreamHandler?.event?(
                    "不支持的设备类型-peripheralType:\(device.peripheralType)-\(deviceMac)")
                sendConnectState(2)
            }

        } else {

            self.loggerStreamHandler?.event?("找不到设备-\(deviceMac)")
            sendConnectState(2)

        }

    }

    func stopScan() {

        self.needScan = false
        self.scaleManager.stopSearch()

        if self.isScaning {
            self.isScaning = false
            sendScanState(scaning: false)
        }
    }

    func disconnect() {

        if let apple = self.appleControl?.peripheral {
            self.scaleManager.disconnect(apple)
        }
        if let coconutControl = self.coconutControl?.peripheral {
            self.scaleManager.disconnect(coconutControl)
        }
        if let torreControl = self.torreControl?.peripheral {
            self.scaleManager.disconnect(torreControl)
        }
        if let iceControl = self.iceControl?.peripheral {
            self.scaleManager.disconnect(iceControl)
        }
        if let borreControl = self.borreControl?.peripheral {
            self.scaleManager.disconnect(borreControl)
        }
        if let forreControl = self.forreControl?.peripheral {
            self.scaleManager.disconnect(forreControl)
        }
        if let durianControl = self.durianControl?.peripheral {
            self.scaleManager.disconnect(durianControl)
        }
        if let dorreControl = self.dorreControl?.peripheral {
            self.scaleManager.disconnect(dorreControl)
        }

        self.clearData()
    }

    func clearData() {

        self.appleControl = nil
        self.coconutControl = nil
        self.torreControl = nil
        self.iceControl = nil
        self.borreControl = nil
        self.forreControl = nil
        self.fishControl = nil
        self.eggControl = nil
        self.durianControl = nil
        self.dorreControl = nil

        self.bananaControl?.scaleDataDelegate = nil
        self.bananaControl?.updateStateDelegate = nil
        self.bananaControl?.stopSearch()

        self.jambulControl?.scaleDataDelegate = nil
        self.jambulControl?.updateStateDelegate = nil
        self.jambulControl?.stopSearch()

        self.hamburgerControl?.scaleDataDelegate = nil
        self.hamburgerControl?.updateStateDelegate = nil
        self.hamburgerControl?.stopSearch()

        self.grapesControl?.scaleDataDelegate = nil
        self.grapesControl?.updateStateDelegate = nil
        self.grapesControl?.stopSearch()

        self.needScan = false
        self.currentDevice = nil
        self.current180A = nil

    }

    /// 连接状态 0:断开连接 1:连接成功 2:连接错误
    func sendConnectState(_ state: Int) {
        // 防抖：如果是断开连接状态，检查是否在500ms内已经发送过
        if state == 0 {
            let currentTime = Date().timeIntervalSince1970
            if isProcessingDisconnect || (currentTime - lastDisconnectTime) < 0.5 {
                self.loggerStreamHandler?.event?("连接状态:\(state) - 重复事件，忽略")
                return
            }
            lastDisconnectTime = currentTime
            isProcessingDisconnect = true

            // 500ms后重置标志
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.isProcessingDisconnect = false
            }
        }

        self.loggerStreamHandler?.event?("连接状态:\(state)")

        self.connectState = state

        let mac = self.currentDevice?.deviceMac ?? ""
        let params: [String: Any] = [
            "deviceMac": mac,
            "state": state,
        ]

        self.connectStateStreamHandler?.event?(params)

    }

    func fetchHistory(model: PPTorreSettingModel) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            return
        }

        switch currentDevice.peripheralType {
        case .peripheralApple:
            self.tempScaleHistoryList = []
            self.appleControl?.fetchDeviceHistoryData()
        case .peripheralCoconut:
            self.tempScaleHistoryList = []
            self.coconutControl?.fetchDeviceHistoryData()
        case .peripheralTorre:
            self.torreControl?.dataFetchHistoryData(
                model,
                withHandler: { [weak self] models in
                    guard let `self` = self else {
                        return
                    }

                    self.sendHistoryData(models)
                })
        case .peripheralIce:
            self.iceControl?.dataFetchHistoryData(handler: { [weak self] (models, error) in
                guard let `self` = self else {
                    return
                }
                self.sendHistoryData(models)
            })
        case .peripheralBorre:
            self.borreControl?.dataFetchHistoryData(
                model,
                withHandler: { [weak self] models in
                    guard let `self` = self else {
                        return
                    }

                    self.sendHistoryData(models)
                })
        case .peripheralDorre:
            self.dorreControl?.dataFetchHistoryData(
                model,
                withHandler: { [weak self] models in
                    guard let `self` = self else {
                        return
                    }

                    self.sendHistoryData(models)
                })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
        }
    }

    func deleteHistory() {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            return
        }

        switch currentDevice.peripheralType {
        case .peripheralApple:
            self.appleControl?.deleteDeviceHistoryData(handler: { [weak self] state in
                guard self != nil else {
                    return
                }

            })
        case .peripheralCoconut:
            self.coconutControl?.deleteDeviceHistoryData()
        case .peripheralIce:
            self.iceControl?.deleteDeviceHistoryData()

        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
        }
    }

    func fetchBatteryInfo() {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            self.batteryStreamHandler?.event?(["power": 0])

            return
        }

        if currentDevice.devicePowerType == .unknow {

            let dict: [String: Any?] = ["power": -1, "lumen": 0]
            let filtedDict = dict.compactMapValues { $0 }

            self.batteryStreamHandler?.event?(filtedDict)

            return
        }

        switch currentDevice.peripheralType {
        case .peripheralApple:
            self.appleControl?.fetchDeviceBatteryInfo()
        case .peripheralCoconut:
            self.coconutControl?.fetchDeviceBatteryInfo()
        case .peripheralTorre:
            // 在代理方法中统一持续回调
            self.torreControl?.fetchDeviceBatteryInfo(completion: { power in
            })
        case .peripheralIce:
            // 在代理方法中统一持续回调
            self.iceControl?.fetchDeviceBatteryInfo(completion: { power in

            })
        case .peripheralBorre:
            // 在代理方法中统一持续回调
            self.borreControl?.fetchDeviceBatteryInfo(completion: { power in
            })
        case .peripheralForre:
            // 在代理方法中统一持续回调
            self.forreControl?.fetchDeviceBatteryInfo(completion: { power in

            })

        case .peripheralFish:

            self.batteryStreamHandler?.event?(["power": self.currentDevice?.devicePower ?? 0])

        case .peripheralDorre:
            // 在代理方法中统一持续回调
            self.dorreControl?.fetchDeviceBatteryInfo(completion: { power in
            })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            self.batteryStreamHandler?.event?(["power": 0])
        }
    }

    func resetDevice() {

        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")

            return
        }

        switch currentDevice.peripheralType {
        case .peripheralApple:
            self.appleControl?.restoreFactory(handler: {
            })
        case .peripheralIce:
            self.iceControl?.restoreFactory(handler: {

            })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
        }

    }

    func receiveBroadcastData(deviceMac: String, callBack: @escaping FlutterResult) {

        guard let device = self.tempDeviceDict[deviceMac] else {

            self.loggerStreamHandler?.event?("找不到当前设备")
            self.sendCommonState(false, callBack: callBack)
            return
        }

        let advDevice = device.0

        if advDevice.peripheralType != .peripheralBanana
            && advDevice.peripheralType != .peripheralJambul
            && advDevice.peripheralType != .peripheralHamburger
            && advDevice.peripheralType != .peripheralGrapes
        {

            self.loggerStreamHandler?.event?("\(advDevice.deviceName)-\(advDevice.deviceMac)不是广播秤")
            self.sendCommonState(false, callBack: callBack)
            return
        }

        if self.bluetoothState == .poweredOff {

            self.loggerStreamHandler?.event?("接收广播失败-蓝牙权限未打开")
            self.sendCommonState(false, callBack: callBack)
            return

        }

        self.disconnect()

        self.currentDevice = advDevice

        let peripheralType = advDevice.peripheralType

        switch peripheralType {
        case .peripheralBanana:
            let banana = PPBluetoothPeripheralBanana.init(device: advDevice)
            banana.updateStateDelegate = self
            banana.scaleDataDelegate = self
            self.bananaControl = banana
        case .peripheralJambul:
            let jambul = PPBluetoothPeripheralJambul.init(device: advDevice)
            jambul.updateStateDelegate = self
            jambul.scaleDataDelegate = self
            self.jambulControl = jambul
        case .peripheralHamburger:
            let hamburger = PPBluetoothPeripheralHamburger.init(device: advDevice)
            hamburger.updateStateDelegate = self
            hamburger.scaleDataDelegate = self
            self.hamburgerControl = hamburger
        case .peripheralGrapes:
            let grapes = PPBluetoothPeripheralGrapes.init(device: advDevice)
            grapes.updateStateDelegate = self
            grapes.scaleDataDelegate = self
            self.grapesControl = grapes
        default:
            self.currentDevice = nil
        }

    }

    func unReceiveBroadcastData(deviceMac: String, callBack: @escaping FlutterResult) {

        self.disconnect()

    }

    func sendBroadcastData(cmd: String, unitType: PPDeviceUnit, callBack: @escaping FlutterResult) {

        guard let device = self.currentDevice else {

            self.loggerStreamHandler?.event?("当前设备为空")
            self.sendCommonState(false, callBack: callBack)
            return
        }

        if device.peripheralType == .peripheralJambul, let jambul = self.jambulControl {
            let user = PPTorreSettingModel()

            jambul.sendCBPeripheralDataCurrentUnit(unitType, scaleType: cmd, settingModel: user)
            self.sendCommonState(true, callBack: callBack)

        } else {

            self.loggerStreamHandler?.event?(
                "发送广播失败-jambul:\(String(describing: self.jambulControl))-peripheralType:\(device.peripheralType)"
            )
            self.sendCommonState(false, callBack: callBack)
        }

    }

    func changeBuzzerGate(isOpen: Bool, callBack: @escaping FlutterResult) {

        guard let device = self.currentDevice else {

            self.loggerStreamHandler?.event?("当前设备为空")
            self.sendCommonState(false, callBack: callBack)
            return
        }

        if device.peripheralType == .peripheralFish, let fish = self.fishControl {

            fish.changeBuzzerGate(isOpen)
            self.sendCommonState(true, callBack: callBack)

        } else {

            self.sendCommonState(false, callBack: callBack)
        }

    }

    func fetchConnectedDevice(callBack: @escaping FlutterResult) {
        if let device = self.currentDevice {

            let dict: [String: Any] = self.convertDeviceDict(device)
            callBack(dict)

        } else {

            callBack([:])
        }
    }

    func addBlePermissionListener() {
        if let state = self.bluetoothState {

            self.sendBlePermissionState(state: state)
        } else {

            self.scaleManager = PPBluetoothConnectManager()
            self.scaleManager.updateStateDelegate = self
        }
    }

    func toZero(callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            return
        }
        let peripheralType = currentDevice.peripheralType
        switch peripheralType {
        case .peripheralFish:
            self.fishControl?.toZero()
            self.sendCommonState(true, callBack: callBack)
        case .peripheralEgg:
            self.eggControl?.toZero()
            self.sendCommonState(true, callBack: callBack)
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(peripheralType)")
        }
    }

}

extension PPLefuBleConnectManager: PPBluetoothUpdateStateDelegate, PPBluetoothSurroundDeviceDelegate
{

    public func centralManagerDidUpdate(_ state: PPBluetoothState) {

        if self.bluetoothState != state {

            self.sendBlePermissionState(state: state)

        }

        self.bluetoothState = state

        self.loggerStreamHandler?.event?("蓝牙状态:\(state)")

        if self.needScan && state == .poweredOn {

            self.needScan = false
            self.scaleManager.searchSurroundDevice()
            self.isScaning = true
            sendScanState(scaning: true)

        } else if state == .poweredOff {
            self.needScan = false

            if self.isScaning {
                self.isScaning = false
                sendScanState(scaning: false)
            }
        } else if self.currentDevice != nil && state == .poweredOn {

            let peripheralType = self.currentDevice?.peripheralType
            if peripheralType == .peripheralBanana {

                self.bananaControl?.receivedDeviceData()
            } else if peripheralType == .peripheralJambul {

                self.jambulControl?.receivedDeviceData()
            } else if peripheralType == .peripheralHamburger {

                self.hamburgerControl?.receivedDeviceData()
            } else if peripheralType == .peripheralGrapes {

                self.grapesControl?.receivedDeviceData()
            }

        }

    }

    public func centralManagerDidFoundSurroundDevice(
        _ device: PPBluetoothAdvDeviceModel!, andPeripheral peripheral: CBPeripheral!
    ) {
        //        self.loggerStreamHandler?.event?("SDK中搜索到:\(device.deviceName) mac:\(device.deviceMac) \(device.peripheralType)")

        if self.scanType == .scan {

            self.tempDeviceDict[device.deviceMac] = (device, peripheral)

            let dict: [String: Any] = self.convertDeviceDict(device)

            self.scanResultStreamHandler?.event?(dict)

        }

    }

}

extension PPLefuBleConnectManager: PPBluetoothConnectDelegate {

    public func centralManagerDidConnect() {

        self.current180A = nil

        let peripheralType = self.currentDevice?.peripheralType

        switch peripheralType {
        case .peripheralApple:
            self.appleControl?.discoverDeviceInfoService({ [weak self] model in
                guard let `self` = self else {
                    return
                }

                self.current180A = model

                self.appleControl?.discoverFFF0Service()

            })
        case .peripheralCoconut:
            self.coconutControl?.discoverFFF0Service()
        case .peripheralTorre:
            self.torreControl?.discoverFFF0Service()
        case .peripheralIce:
            self.iceControl?.discoverFFF0Service()
        case .peripheralBorre:
            self.borreControl?.discoverFFF0Service()
        case .peripheralForre:
            self.forreControl?.discoverFFF0Service()
        case .peripheralFish:
            self.fishControl?.discoverDeviceInfoService({ [weak self] model in
                guard let `self` = self else {
                    return
                }
                self.current180A = model
                self.fishControl?.discoverFFF0Service()

            })
        case .peripheralEgg:
            self.eggControl?.discoverDeviceInfoService({ [weak self] model in
                guard let `self` = self else {
                    return
                }
                self.current180A = model
                self.eggControl?.discoverFFF0Service()

            })
        case .peripheralDurian:
            self.durianControl?.discoverFFF0Service()
        case .peripheralDorre:
            self.dorreControl?.discoverFFF0Service()
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(String(describing: peripheralType))")
        }

    }

    public func centralManagerDidDisconnect() {
        // 防止重复处理断开连接
        if connectState == 0 {
            self.loggerStreamHandler?.event?("设备已经是断开状态，忽略重复的断开事件")
            return
        }

        self.sendConnectState(0)
        self.clearData()
    }

    public func centralManagerDidFail(toConnect error: (any Error)!) {
        self.sendConnectState(2)
        self.clearData()
    }

}

extension PPLefuBleConnectManager: PPBluetoothServiceDelegate {

    func discoverDeviceInfoServiceSuccess(_ device: PPBluetooth180ADeviceModel!) {

    }

    public func discoverFFF0ServiceSuccess() {

        self.loggerStreamHandler?.event?("发现FFF0成功")

        let peripheralType = self.currentDevice?.peripheralType
        switch peripheralType {
        case .peripheralApple:
            self.appleControl?.scaleDataDelegate = self
            self.sendConnectState(1)
        case .peripheralCoconut:
            self.coconutControl?.scaleDataDelegate = self
            self.sendConnectState(1)
        case .peripheralTorre:
            self.torreControl?.codeUpdateMTU({ [weak self] mtu in
                guard let `self` = self else {
                    return
                }

                self.torreControl?.scaleDataDelegate = self
                self.sendConnectState(1)
            })
        case .peripheralIce:
            self.iceControl?.scaleDataDelegate = self
            self.sendConnectState(1)
        case .peripheralBorre:
            self.borreControl?.codeUpdateMTU({ [weak self] mtu in
                guard let `self` = self else {
                    return
                }

                self.borreControl?.scaleDataDelegate = self
                self.sendConnectState(1)
            })
        case .peripheralForre:
            self.forreControl?.codeUpdateMTU({ [weak self] mtu in
                guard let `self` = self else {
                    return
                }

                self.forreControl?.scaleDataDelegate = self
                self.sendConnectState(1)
            })
        case .peripheralFish:
            self.fishControl?.scaleDataDelegate = self
            self.sendConnectState(1)
        case .peripheralEgg:
            self.eggControl?.scaleDataDelegate = self
            self.sendConnectState(1)
        case .peripheralDurian:
            self.durianMeasurementHandler = PPDurianMeasurementHandler()

            self.durianMeasurementHandler?.monitorBatteryInfoChangeHandler = {
                [weak self] (model, advModel) in
                guard let `self` = self else {
                    return
                }

                let dict: [String: Any?] = ["power": model.power, "lumen": model.lumen]
                let filtedDict = dict.compactMapValues { $0 }

                self.batteryStreamHandler?.event?(filtedDict)
            }

            self.durianControl?.scaleDataDelegate = self.durianMeasurementHandler
            self.sendConnectState(1)
        case .peripheralDorre:
            self.dorreControl?.codeUpdateMTU({ [weak self] mtu in
                guard let `self` = self else {
                    return
                }

                self.dorreControl?.scaleDataDelegate = self
                self.sendConnectState(1)
            })
        default:
            self.loggerStreamHandler?.event?("未知类型:\(String(describing: peripheralType))")
        }

    }

}

extension PPLefuBleConnectManager: PPBluetoothCMDDataDelegate {

    public func syncDeviceHistorySuccess() {  //同步历史数据成功

        if let models = self.tempScaleHistoryList {

            self.sendHistoryData(models)
        }

        self.tempScaleHistoryList = []
    }

    public func syncDeviceTimeSuccess() {

    }

    public func deleteDeviceHistoryDataSuccess() {

    }

    public func deviceWillDisconnect() {

    }

    public func monitorBatteryInfoChange(
        _ model: PPBatteryInfoModel!, advModel: PPBluetoothAdvDeviceModel!
    ) {

        let dict: [String: Any?] = ["power": model.power, "lumen": model.lumen]
        let filtedDict = dict.compactMapValues { $0 }

        self.batteryStreamHandler?.event?(filtedDict)
    }
}

extension PPLefuBleConnectManager: PPBluetoothScaleDataDelegate {

    public func monitorProcessData(
        _ model: PPBluetoothScaleBaseModel!, advModel: PPBluetoothAdvDeviceModel!
    ) {

        // 0:过程数据，1:体脂测量中（部分设备无此状态），2:心率测量中，10:测量完成（获取阻抗、心率等数据进行身体数据计算）
        var measurementState = 0
        if model.isHeartRating {

            measurementState = 2
        } else if model.isFatting {

            measurementState = 1
        }

        self.sendMeasureData(model, advModel: advModel, measureState: measurementState)
    }

    public func monitorLockData(
        _ model: PPBluetoothScaleBaseModel!, advModel: PPBluetoothAdvDeviceModel!
    ) {

        //0:过程数据，1:体脂测量中（部分设备无此状态），2:心率测量中，10:测量完成（获取阻抗、心率等数据进行身体数据计算）
        let measurementState = 10

        self.sendMeasureData(model, advModel: advModel, measureState: measurementState)
    }

    public func monitorHistoryData(
        _ model: PPBluetoothScaleBaseModel!, advModel: PPBluetoothAdvDeviceModel!
    ) {
        self.tempScaleHistoryList?.append(model)
    }

}

extension PPLefuBleConnectManager: PPBluetoothFoodScaleDataDelegate {

    public func monitorData(
        _ model: PPBluetoothScaleBaseModel!, advModel: PPBluetoothAdvDeviceModel!
    ) {

        // 0:过程数据，10:测量完成（广播秤等可能没有这个状态）
        var measurementState = 0
        if model.isEnd {

            measurementState = 10
        }

        self.sendKitchenData(model, advModel: advModel, measureState: measurementState)
    }
}
