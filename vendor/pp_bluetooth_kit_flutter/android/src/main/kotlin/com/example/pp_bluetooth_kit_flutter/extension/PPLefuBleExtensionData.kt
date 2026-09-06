package com.example.pp_bluetooth_kit_flutter.extension

import com.example.pp_bluetooth_kit_flutter.PPLefuBleConnectManager
import com.example.pp_bluetooth_kit_flutter.util.PPBluetoothState
import com.lefu.ppbase.PPBodyBaseModel
import com.lefu.ppbase.PPDeviceModel
import com.lefu.ppbase.PPScaleDefine.PPDeviceAccuracyType
import com.lefu.ppbase.util.Logger
import com.lefu.ppbase.vo.PPScaleStatePowerType
import com.peng.ppscale.PPBluetoothKit
import com.peng.ppscale.util.DateUtil
import com.peng.ppscale.vo.LFFoodScaleGeneral
import io.flutter.plugin.common.MethodChannel.Result


/**
 * PPLefuBleConnectManager的数据处理扩展
 * Created by lefu on 2023/4/16
 */
fun PPLefuBleConnectManager.convert180A(model: PPDeviceModel?): Map<String, Any> {
    val map = mutableMapOf<String, Any?>()
    map["modelNumber"] = model?.modelNumber
    map["firmwareRevision"] = model?.firmwareVersion
    map["softwareRevision"] = model?.softwareVersion
    map["hardwareRevision"] = model?.hardwareVersion
    map["serialNumber"] = model?.serialNumber
    map["manufacturerName"] = model?.manufacturerName

    return map.filterValues { it != null } as Map<String, Any>
}

fun PPLefuBleConnectManager.convertDeviceDict(device: PPDeviceModel): Map<String, Any> {
    val map = mutableMapOf<String, Any?>()
    map["deviceSettingId"] = device.deviceSettingId
    map["deviceMac"] = device.deviceMac
    map["deviceName"] = device.deviceName
    map["devicePower"] = device.devicePower
    map["rssi"] = device.rssi
    map["deviceType"] = device.deviceType.ordinal
    map["deviceProtocolType"] = device.deviceProtocolType.getType()
    map["deviceCalculateType"] = device.deviceCalcuteType.getType()
    map["deviceAccuracyType"] = device.deviceAccuracyType.getType()
    map["devicePowerType"] = device.devicePowerType.getType()
    map["deviceConnectType"] = device.deviceConnectType.getType()
    map["deviceFuncType"] = device.deviceFuncType
    map["deviceUnitType"] = device.deviceUnitType
    map["peripheralType"] = device.getDevicePeripheralType().ordinal
    map["sign"] = device.sign
    map["advLength"] = device.advLength
    map["macAddressStart"] = device.macAddressStart
    map["standardType"] = device.standardType
    map["productModel"] = device.productModel
    val deviceConfig = PPBluetoothKit.getDeviceConfigVo(device.deviceSettingId);
    map["brandId"] = (deviceConfig?.brandId ?: "0").toInt()
    map["imgUrl"] = device.imgUrl
    map["avatarType"] = deviceConfig?.avatarType ?: 0
    map["customDeviceName"] = deviceConfig?.customDeviceName ?: ""

    return map.filterValues { it != null } as Map<String, Any>
}

fun PPLefuBleConnectManager.convertMeasurementDict(model: PPBodyBaseModel): Map<String, Any> {
    val map = mutableMapOf<String, Any?>()
    if (model.dateStr.isNullOrEmpty()) {
        val dateTimeInterval = System.currentTimeMillis()
        map["measureTime"] = dateTimeInterval
    } else {
        map["measureTime"] = DateUtil.stringToLong(model.dateStr)
    }
    val memberId = model.userModel?.memberID

    map["weight"] = model.weight
    map["impedance"] = model.impedance
    map["impedance100EnCode"] = model.ppImpedance100EnCode
    map["isHeartRating"] = model.isHeartRating
    map["heartRate"] = model.heartRate
    map["isOverload"] = model.isOverload
    map["memberId"] = memberId
    map["footLen"] = model.footLen
    map["unit"] = model.unit?.type ?: 0
    map["z100KhzLeftArmEnCode"] = model.z100KhzLeftArmEnCode
    map["z100KhzLeftLegEnCode"] = model.z100KhzLeftLegEnCode
    map["z100KhzRightArmEnCode"] = model.z100KhzRightArmEnCode
    map["z100KhzRightLegEnCode"] = model.z100KhzRightLegEnCode
    map["z100KhzTrunkEnCode"] = model.z100KhzTrunkEnCode
    map["z20KhzLeftArmEnCode"] = model.z20KhzLeftArmEnCode
    map["z20KhzLeftLegEnCode"] = model.z20KhzLeftLegEnCode
    map["z20KhzRightArmEnCode"] = model.z20KhzRightArmEnCode
    map["z20KhzRightLegEnCode"] = model.z20KhzRightLegEnCode
    map["z20KhzTrunkEnCode"] = model.z20KhzTrunkEnCode

    if (model.scaleState?.powerType != PPScaleStatePowerType.PP_SCALE_STATE_POWER_OFF) {
        map["isPowerOff"] = true
    } else {
        map["isPowerOff"] = true
    }
    return map.filterValues { it != null } as Map<String, Any>
}

fun PPLefuBleConnectManager.convertMeasurementDictFood(model: LFFoodScaleGeneral, deviceModel: PPDeviceModel?): Map<String, Any> {
    val map = mutableMapOf<String, Any?>()
    if (deviceModel?.deviceAccuracyType === PPDeviceAccuracyType.PPDeviceAccuracyTypePoint01G) {
        map["weight"] = kotlin.math.round(model.lfWeightKg * 10.0).toInt()
    } else {
        map["weight"] = kotlin.math.round(model.lfWeightKg).toInt()
    }
    Logger.v("convertMeasurementDictFood: ${model.lfWeightKg} weight:${ map["weight"]}")
    //正负 0表示负值 1 正值
    map["isPlus"] = model.thanZero == 1
    map["measureTime"] = System.currentTimeMillis()
    map["unit"] = model.unit?.type ?: 0

    return map.filterValues { it != null } as Map<String, Any>
}


fun PPLefuBleConnectManager.sendMeasureData(model: PPBodyBaseModel, advModel: PPDeviceModel, measureState: Int) {
    val deviceDict = this.convertDeviceDict(advModel)
    val dataDict = this.convertMeasurementDict(model)

    this.loggerStreamHandler?.sendEvent("测量状态:$measureState")

    val dict = mapOf(
        "measurementState" to measureState,
        "device" to deviceDict,
        "data" to dataDict
    )

    this.measureStreamHandler?.sendEvent(dict)
}

fun PPLefuBleConnectManager.sendHistoryData(models: List<PPBodyBaseModel>) {
    val array = mutableListOf<Map<String, Any>>()

    for (model in models) {
        val dict = this.convertMeasurementDict(model)
        array.add(dict)
    }

    val dataList = array

    this.loggerStreamHandler?.sendEvent("历史数据-数量:${dataList.size}")
    val dict = mapOf(
        "dataList" to dataList
    )
    this.historyStreamHandler?.sendEvent(dict)
}

fun PPLefuBleConnectManager.sendBlePermissionState(state: PPBluetoothState) {
    var stateValue = 0
    if (state == PPBluetoothState.UNAUTHORIZED) {
        stateValue = 1
    } else if (state == PPBluetoothState.POWERED_ON) {
        stateValue = 2
    } else if (state == PPBluetoothState.POWERED_OFF) {
        stateValue = 3
    } else if (state == PPBluetoothState.POSITIONING_ON) {
        stateValue = 4
    } else if (state == PPBluetoothState.POSITIONING_OFF) {
        stateValue = 5
    } else if (state == PPBluetoothState.PERMANENTLY_DENY) {
        stateValue = 6
    }

    val dict = mapOf(
        "state" to stateValue
    )

    this.blePermissionStreamHandler?.sendEvent(dict)
}

fun PPLefuBleConnectManager.sendWIFIResult(isSuccess: Boolean, sn: String?, errorCode: Int?, callBack: Result) {
    val map = mutableMapOf<String, Any?>()
    map["success"] = isSuccess
    map["errorCode"] = errorCode
    map["sn"] = sn

    val filteredMap = map.filterValues { it != null }

    callBack.success(filteredMap)
}

fun PPLefuBleConnectManager.sendWIFISSID(ssId: String?, isConnectWIFI: Boolean, callBack: Result) {
    val map = mutableMapOf<String, Any?>()
    map["ssId"] = ssId
    map["isConnectWIFI"] = isConnectWIFI

    val filteredMap = map.filterValues { it != null }

    callBack.success(filteredMap)
}

/**
 * 0-成功;
 * 1-设备已在升级中不能再次启动升级;
 * 2-设备低电量无法
 * 启动升级;
 * 3-未配网
 * 4-充电中
 */
fun PPLefuBleConnectManager.sendWifiOTA(isSuccess: Boolean, errorCode: Int, callBack: Result) {
    val dict = mapOf(
        "isSuccess" to isSuccess,
        "errorCode" to errorCode
    )

    callBack.success(dict)
}

fun PPLefuBleConnectManager.sendCommonState(state: Boolean, callBack: Result?) {
    val dict = mapOf(
        "state" to state
    )

    callBack?.success(dict)
}

fun PPLefuBleConnectManager.sendDfuResult(progress: Double, isSuccess: Boolean) {
    val dict = mapOf(
        "progress" to progress,
        "isSuccess" to isSuccess
    )

    this.dfuStreamHandler?.sendEvent(dict)
}

fun PPLefuBleConnectManager.sendScanState(scaning: Boolean) {
    val code = if (scaning) 1 else 0
    this.scanStateStreamHandler?.sendEvent(mapOf("state" to code))
}

fun PPLefuBleConnectManager.sendKitchenData(model: LFFoodScaleGeneral, deviceModel: PPDeviceModel, measureState: Int) {
    val deviceDict = this.convertDeviceDict(deviceModel)
    val dataDict = this.convertMeasurementDictFood(model, deviceModel)

    this.loggerStreamHandler?.sendEvent("厨房秤-测量状态:$measureState")

    val dict = mapOf(
        "measurementState" to measureState,
        "device" to deviceDict,
        "data" to dataDict
    )

    this.kitchenStreamHandler?.sendEvent(dict)
}
