//
//  PPDurianMeasurementHandler.swift
//  Pods
//
//  Created by lefu on 2025/5/7
//  


import Foundation
import PPBluetoothKit
import PPBaseKit

class PPDurianMeasurementHandler:NSObject {
    
    var monitorProcessDataHandler:((_ model: PPBluetoothScaleBaseModel, _ advModel: PPBluetoothAdvDeviceModel)->Void)?
    var monitorLockDataHandler:((_ model: PPBodyFatModel, _ advModel: PPBluetoothAdvDeviceModel)->Void)?
    var monitorBatteryInfoChangeHandler:((_ model: PPBatteryInfoModel, _ advModel: PPBluetoothAdvDeviceModel)->Void)?
    
}

extension PPDurianMeasurementHandler:PPBluetoothCalculateInScaleDataDelegate {
    
    func monitorProcessData(_ model: PPBluetoothScaleBaseModel!, advModel: PPBluetoothAdvDeviceModel!) {
        self.monitorProcessDataHandler?(model, advModel)
    }

    
    func monitorLockData(_ model: PPBodyFatModel!, advModel: PPBluetoothAdvDeviceModel!) {
        self.monitorLockDataHandler?(model, advModel)
    }
    
    
    func monitorBatteryInfoChange(_ model: PPBatteryInfoModel!, advModel: PPBluetoothAdvDeviceModel!) {
        self.monitorBatteryInfoChangeHandler?(model, advModel)
    }
    
}
