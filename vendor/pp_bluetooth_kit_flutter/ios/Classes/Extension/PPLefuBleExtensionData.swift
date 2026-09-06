//
//  PPLefuBleDataExtension.swift
//  Pods
//
//  Created by lefu on 2025/4/16
//  


import Foundation
import PPBaseKit
import PPBluetoothKit
import Flutter

extension PPLefuBleConnectManager {
    
    func convert180A(model:PPBluetooth180ADeviceModel)->[String:Any] {
        let dict:[String:Any?] = [
            "modelNumber":model.modelNumber,
            "firmwareRevision":model.firmwareRevision,
            "softwareRevision":model.softwareRevision,
            "hardwareRevision":model.hardwareRevision,
            "serialNumber":model.serialNumber,
            "manufacturerName":model.manufacturerName
        ]
        
        
        let filtedDict = dict.compactMapValues { $0 }
        
        return filtedDict
    }
    
    func convertDeviceDict(_ device:PPBluetoothAdvDeviceModel)->[String:Any] {

        let dict:[String:Any?] = [
            "deviceSettingId":device.deviceSettingId,
            "deviceMac":device.deviceMac,
            "deviceName":device.deviceName,
            "customDeviceName":device.customDeviceName,
            "devicePower":device.devicePower,
            "rssi":device.rssi,
            "deviceType":device.deviceType.rawValue,
            "deviceProtocolType":device.deviceProtocolType.rawValue,
            "deviceCalculateType":device.deviceCalcuteType.rawValue,
            "deviceAccuracyType":device.deviceAccuracyType.rawValue,
            "devicePowerType":device.devicePowerType.rawValue,
            "deviceConnectType":device.deviceConnectType.rawValue,
            "deviceFuncType":device.deviceFuncType.rawValue,
            "deviceUnitType":device.deviceUnitList,
            "peripheralType":device.peripheralType.rawValue,
            "sign":device.sign,
            "advLength":device.advLength,
            "macAddressStart":device.macAddressStart,
            "standardType":device.standardType.rawValue,
            "productModel":device.productModel,
            "brandId":device.brandId,
            "imgUrl":device.imgUrl,
            "avatarType":device.avatarType.rawValue,
            "advancedConfig":device.advancedConfig,
        ]
        
        let filtedDict = dict.compactMapValues { $0 }
        
        return filtedDict
    }
    
    func convertMeasurementDict(_ model:PPBluetoothScaleBaseModel)->[String:Any] {
        
        let dateTimeInterval = Int(model.dateTimeInterval * 1000)
        let memberId = model.memberId
        let isPowerOff = model.isPowerOff
        
        let dict:[String:Any?] = [
            "weight":model.weight,
            "impedance":model.impedance,
            "impedance100EnCode":model.impedance100EnCode,
            "isHeartRating":model.isHeartRating,
            "heartRate":model.heartRate,
            "isOverload":model.isOverload,
            "isPlus":model.isPlus,
            "measureTime":dateTimeInterval,
            "memberId":memberId,
            "footLen":model.footLen,
            "unit":model.unit.rawValue,
            "z100KhzLeftArmEnCode":model.z100KhzLeftArmEnCode,
            "z100KhzLeftLegEnCode":model.z100KhzLeftLegEnCode,
            "z100KhzRightArmEnCode":model.z100KhzRightArmEnCode,
            "z100KhzRightLegEnCode":model.z100KhzRightLegEnCode,
            "z100KhzTrunkEnCode":model.z100KhzTrunkEnCode,
            "z20KhzLeftArmEnCode":model.z20KhzLeftArmEnCode,
            "z20KhzLeftLegEnCode":model.z20KhzLeftLegEnCode,
            "z20KhzRightArmEnCode":model.z20KhzRightArmEnCode,
            "z20KhzRightLegEnCode":model.z20KhzRightLegEnCode,
            "z20KhzTrunkEnCode":model.z20KhzTrunkEnCode,
            "isPowerOff":isPowerOff,
            "hasLightStrength":model.hasLightStrength,
            "lightStrength":model.lightStrength,
         
                
        ]
        
        
        let filtedDict = dict.compactMapValues { $0 }
        
        return filtedDict
    }
    
    func sendMeasureData(_ model:PPBluetoothScaleBaseModel, advModel: PPBluetoothAdvDeviceModel, measureState:Int) {
        
        let deviceDict:[String:Any] = self.convertDeviceDict(advModel)
        var dataDict:[String:Any] = self.convertMeasurementDict(model)
        
        
        
        if(model.impedanceFailReason != nil){
            
            print(model.impedanceFailReason.exceptionCode ?? "")
            
            
            if(model.impedanceFailReason.exceptionCode == "01" || model.impedanceFailReason.exceptionCode ==  "04"){
                dataDict["imErrorType"] = 5
            }else if(model.impedanceFailReason.exceptionCode == "02" || model.impedanceFailReason.exceptionCode ==  "08"){
                dataDict["imErrorType"] = 6
            }else if(model.impedanceFailReason.exceptionCode == "10" || model.impedanceFailReason.exceptionCode ==  "40"){
                dataDict["imErrorType"] = 4
            }else if(model.impedanceFailReason.exceptionCode == "20" || model.impedanceFailReason.exceptionCode ==  "80"){
                dataDict["imErrorType"] = 3
            }else{
                dataDict["imErrorType"] = 7

            }
        }
        
        self.loggerStreamHandler?.event?("测量状态:\(measureState)")
        
        let dict:[String:Any] = [
            "measurementState":measureState,
            "device":deviceDict,
            "data":dataDict
        ]
        
        self.measureStreamHandler?.event?(dict)
    }
    
    func sendHistoryData(_ models:[PPBluetoothScaleBaseModel]) {
        
        var array:[[String:Any]] = []
        
        for model in models {
            let dict = self.convertMeasurementDict(model)
            array.append(dict)
        }

        let dataList = array
        
        
        self.loggerStreamHandler?.event?("历史数据-数量:\(dataList.count)")
        let dict = [
            "dataList":dataList
        ]
        self.historyStreamHandler?.event?(dict)
    }
    
    func sendBlePermissionState(state:PPBluetoothState) {
        
        var stateValue:Int = 0
        if state == .unauthorized {
            stateValue = 1
        } else if state == .poweredOn {
            stateValue = 2
        } else if state == .poweredOff {
            stateValue = 3
        }
        
        let dict:[String:Any] = [
            "state":stateValue
        ]
        
        self.blePermissionStreamHandler?.event?(dict)
    }
    
    func sendWIFIResult(isSuccess:Bool, sn:String?, errorCode:Int?, callBack: @escaping FlutterResult) {
        
        let dict:[String:Any?] = [
            "success":isSuccess,
            "errorCode":errorCode,
            "sn":sn
        ]
        
        let filtedDict = dict.compactMapValues { $0 }
        
        callBack(filtedDict)
    }
    
    func sendWIFISSID(_ ssId:String?, isConnectWIFI:Bool, callBack: @escaping FlutterResult) {
        
        let dict:[String:Any?] = ["ssId": ssId, "isConnectWIFI":isConnectWIFI]
        let filtedDict = dict.compactMapValues { $0 }
        
        callBack(filtedDict)
    }
    
    func sendWifiList(_ wifiList:[PPWifiInfoModel], callBack: @escaping FlutterResult) {
        
        var array = [String]()
        for model in wifiList {
            array.append(model.ssid)
        }
        let dict:[String:Any] = ["wifiList":array]
        callBack(dict)
    }
    
    func sendWifiOTA(isSuccess:Bool, errorCode:Int, callBack: @escaping FlutterResult) {

        let dict:[String:Any] = [
            "isSuccess":isSuccess,
            "errorCode":errorCode
        ]
        
        callBack(dict)
    }
    
    func sendCommonState(_ state:Bool, callBack: @escaping FlutterResult) {
        
        let dict:[String:Any] = [
            "state":state
        ]
        
        callBack(dict)
    }
    
    func sendDfuResult(progress:Float, isSuccess:Bool) {
        
        let dict:[String:Any] = [
            "progress":progress,
            "isSuccess":isSuccess,
        ]
        
        self.dfuStreamHandler?.event?(dict)
    }
    
    func sendScanState(scaning:Bool) {
        let code:Int = scaning ? 1 : 0
        self.scanStateStreamHandler?.event?(["state":code])
    }
    
    
    func sendKitchenData(_ model:PPBluetoothScaleBaseModel, advModel: PPBluetoothAdvDeviceModel, measureState:Int) {
        
        let deviceDict:[String:Any] = self.convertDeviceDict(advModel)
        let dataDict:[String:Any] = self.convertMeasurementDict(model)
        
        self.loggerStreamHandler?.event?("厨房秤-测量状态:\(measureState)")
        
        let dict:[String:Any] = [
            "measurementState":measureState,
            "device":deviceDict,
            "data":dataDict
        ]
        
        self.kitchenStreamHandler?.event?(dict)
    }
    
   

}
