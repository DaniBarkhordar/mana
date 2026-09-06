package com.example.pp_bluetooth_kit_flutter.extension

import com.example.pp_bluetooth_kit_flutter.PPLefuBleConnectManager
import com.lefu.ppbase.*
import com.lefu.ppbase.PPScaleDefine.*
import com.lefu.ppbase.util.PPUtil
import com.lefu.ppbase.vo.PPUnitType
import com.lefu.ppbase.vo.PPUserModel

import com.peng.ppscale.business.ble.configWifi.PPConfigStateMenu
import com.peng.ppscale.business.ble.configWifi.PPConfigWifiInfoInterface
import com.peng.ppscale.business.ble.listener.PPBleSendResultCallBack
import com.peng.ppscale.business.ble.listener.PPDeviceInfoInterface
import com.peng.ppscale.business.ble.listener.PPDeviceSetInfoInterface
import com.peng.ppscale.business.ble.listener.PPTorreDeviceModeChangeInterface
import com.peng.ppscale.business.ble.listener.PPUserInfoInterface
import com.peng.ppscale.business.ota.OnOTAStateListener
import com.peng.ppscale.business.torre.listener.PPClearDataInterface
import com.peng.ppscale.business.torre.listener.PPTorreConfigWifiInterface
import com.peng.ppscale.util.UnitUtil
import com.peng.ppscale.vo.PPScaleSendState
import com.peng.ppscale.vo.PPWifiModel
import io.flutter.plugin.common.MethodChannel.Result
import java.math.BigDecimal
import android.content.Context
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.util.zip.ZipInputStream

import com.example.pp_bluetooth_kit_flutter.model.PPDfuPackageModel
import kotlin.math.absoluteValue

/**
 * PPLefuBleConnectManager的命令处理扩展
 * Created by lefu on 2023/4/16
 */
fun PPLefuBleConnectManager.syncUnit(unit: Int, model: PPUserModel, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }
    val unit = UnitUtil.getUnitType(unit, currentDevice.deviceName);
    when (currentDevice.getDevicePeripheralType()) {

        PPDevicePeripheralType.PeripheralApple -> {
            this.appleControl?.syncUnit(unit, model, object : PPBleSendResultCallBack {
                override fun onResult(sendState: PPScaleSendState?) {
                    sendCommonState(sendState == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralCoconut -> {
            this.coconutControl?.sendSyncUserAndUnitData(unit, model, object : PPBleSendResultCallBack {
                override fun onResult(sendState: PPScaleSendState?) {
                    sendCommonState(sendState == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.syncUnit(unit, object : PPBleSendResultCallBack {
                override fun onResult(sendState: PPScaleSendState?) {
                    sendCommonState(sendState == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }


        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.syncUnit(unit, object : PPBleSendResultCallBack {
                override fun onResult(sendState: PPScaleSendState?) {
                    sendCommonState(sendState == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.syncUnit(unit, object : PPBleSendResultCallBack {
                override fun onResult(sendState: PPScaleSendState?) {
                    sendCommonState(sendState == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.syncUnit(unit, object : PPBleSendResultCallBack {
                override fun onResult(sendState: PPScaleSendState?) {
                    sendCommonState(sendState == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.syncUnit(unit, object : PPBleSendResultCallBack {
                override fun onResult(sendState: PPScaleSendState?) {
                    sendCommonState(sendState == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralFish -> {

            var unitArray = currentDevice.deviceUnitType.split(",").filter { it.isNotEmpty() }

            val nextUnit = getNextUnitIndex(unit.type,unitArray)

            val next = UnitUtil.getUnitType(nextUnit, currentDevice.deviceName);


            this.fishControl?.changeKitchenScaleUnit(next, object : PPBleSendResultCallBack {
                override fun onResult(sendState: PPScaleSendState?) {
                    sendCommonState(sendState == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralEgg -> {

            val unitArray = currentDevice.deviceUnitType.split(",").filter { it.isNotEmpty() }

            val nextUnit = getNextUnitIndex(unit.type,unitArray)

            val next = UnitUtil.getUnitType(nextUnit, currentDevice.deviceName);


            this.eggControl?.changeKitchenScaleUnit(next, object : PPBleSendResultCallBack {
                override fun onResult(sendState: PPScaleSendState?) {
                    sendCommonState(sendState == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDurian -> {
            this.durianControl?.syncUnit(unit, model, object : PPBleSendResultCallBack {
                override fun onResult(sendState: PPScaleSendState?) {
                    sendCommonState(sendState == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            sendCommonState(false, callBack)
        }
    }
}

fun getNextUnitIndex(currentUnit: Int, unitArray: List<String>): Int {
    // 1. 格式化数值为字符串（等价 OC 的 stringWithFormat）
    val unitStr = currentUnit.toString()

    // 2. 查找索引（处理未找到的情况：indexOf 返回 -1 时默认设为 0）
    val index = unitArray.indexOf(unitStr).takeIf { it != -1 } ?: 0

    // 3. 计算下一个索引并处理循环
    var nextIndex = index + 1
    if (nextIndex > unitArray.lastIndex) {
        nextIndex = 0
    }

    val nextUnit = unitArray[nextIndex].toInt()

    return nextUnit
}

fun PPLefuBleConnectManager.syncTime(is24Hour: Boolean, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralApple -> {
            this.appleControl?.syncTime(object : PPBleSendResultCallBack {
                override fun onResult(sendState: PPScaleSendState?) {
                    sendCommonState(sendState == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralCoconut -> {
            this.coconutControl?.sendSyncTime(object : PPBleSendResultCallBack {
                override fun onResult(sendState: PPScaleSendState?) {
                    sendCommonState(sendState == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.syncTime(object : PPBleSendResultCallBack {
                override fun onResult(sendState: PPScaleSendState?) {
                    sendCommonState(sendState == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralTorre -> {
            val code = if (is24Hour) 0 else 1
            this.torreControl?.getTorreDeviceManager()?.syncTime24(code, object : PPBleSendResultCallBack {
                override fun onResult(sendState: PPScaleSendState?) {
                    sendCommonState(sendState == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            val code = if (is24Hour) 0 else 1
            this.borreControl?.getTorreDeviceManager()?.syncTime24(code, object : PPBleSendResultCallBack {
                override fun onResult(sendState: PPScaleSendState?) {
                    sendCommonState(sendState == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            val code = if (is24Hour) 0 else 1
            this.dorreControl?.getTorreDeviceManager()?.syncTime24(code, object : PPBleSendResultCallBack {
                override fun onResult(sendState: PPScaleSendState?) {
                    sendCommonState(sendState == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            val code = if (is24Hour) 0 else 1
            this.forreControl?.getTorreDeviceManager()?.syncTime24(code, object : PPBleSendResultCallBack {
                override fun onResult(sendState: PPScaleSendState?) {
                    sendCommonState(sendState == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }

            })
        }

        PPDevicePeripheralType.PeripheralFish -> {
            this.fishControl?.sendSyncTime(object : PPBleSendResultCallBack {
                override fun onResult(sendState: PPScaleSendState?) {
                    sendCommonState(sendState == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            sendCommonState(false, callBack)
        }
    }
}

fun PPLefuBleConnectManager.configWifi(domain: String, ssId: String, password: String, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        callBack.success(mapOf("success" to false, "errorCode" to -1))
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralApple -> {
            this.appleControl?.sendModifyServerDomain(domain, object : PPConfigWifiInfoInterface {
                override fun monitorModifyServerDomainSuccess() {
                    appleControl?.configWifiData(ssId, password, this)
                }

                override fun monitorConfigSn(sn: String?, deviceModel: PPDeviceModel?) {
                    val success = sn.isNullOrEmpty().not()
                    if (!success) {
                        sendWIFIResult(success, sn, 0, callBack)
                    } else {
                        sendWIFIResult(success, sn, -1, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.configWifi(domain, ssId, password, object : PPTorreConfigWifiInterface() {
                override fun configResult(stateMenu: PPConfigStateMenu?, errorCodeStr: String?) {
                    if (stateMenu == PPConfigStateMenu.CONFIG_STATE_SUCCESS) {
                        sendWIFIResult(true, "", 0, callBack)
                    } else if (stateMenu == PPConfigStateMenu.CONFIG_STATE_EXIT) {

                    } else {
                        sendWIFIResult(false, errorCodeStr, -1, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.sendModifyServerDomain(domain, object : PPConfigWifiInfoInterface {
                override fun monitorModifyServerDomainSuccess() {
                    iceControl?.configWifiData(ssId, password, this)
                }

                override fun monitorConfigSn(sn: String?, deviceModel: PPDeviceModel?) {
                    val success = sn.isNullOrEmpty().not()
                    if (!success) {
                        sendWIFIResult(success, sn, 0, callBack)
                    } else {
                        sendWIFIResult(success, sn, -1, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.configWifi(domain, ssId, password, object : PPTorreConfigWifiInterface() {
                override fun configResult(stateMenu: PPConfigStateMenu?, errorCodeStr: String?) {
                    if (stateMenu == PPConfigStateMenu.CONFIG_STATE_SUCCESS) {
                        sendWIFIResult(true, "", 0, callBack)
                    } else if (stateMenu == PPConfigStateMenu.CONFIG_STATE_EXIT) {

                    } else {
                        sendWIFIResult(false, errorCodeStr, -1, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.configWifi(domain, ssId, password, object : PPTorreConfigWifiInterface() {
                override fun configResult(stateMenu: PPConfigStateMenu?, errorCodeStr: String?) {
                    if (stateMenu == PPConfigStateMenu.CONFIG_STATE_SUCCESS) {
                        sendWIFIResult(true, "", 0, callBack)
                    } else if (stateMenu == PPConfigStateMenu.CONFIG_STATE_EXIT) {

                    } else {
                        sendWIFIResult(false, errorCodeStr, -1, callBack)
                    }
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf("success" to false, "errorCode" to -1))
        }
    }
}

fun PPLefuBleConnectManager.syncLast7Data(lastBodyData: PPUserModel, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.borreControl?.getTorreDeviceManager()?.syncUserSevenWeighInfo(lastBodyData, object : PPUserInfoInterface {
                override fun syncUserSevenWeightInfoFail() {
                    sendCommonState(false, callBack)
                }

                override fun syncUserSevenWeightInfoSuccess() {
                    sendCommonState(true, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.syncUserSevenWeighInfo(lastBodyData, object : PPUserInfoInterface {
                override fun syncUserSevenWeightInfoFail() {
                    sendCommonState(false, callBack)
                }

                override fun syncUserSevenWeightInfoSuccess() {
                    sendCommonState(true, callBack)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            this.sendCommonState(false, callBack)
        }
    }
}

fun PPLefuBleConnectManager.heartRateSwitchControl(open: Boolean, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            //心率0打开 1关闭
            torreControl?.getTorreDeviceManager()?.controlHeartRate(if (open) 0 else 1, object : PPTorreDeviceModeChangeInterface {
                /**
                 * 心率开关状态
                 *
                 * @param type  1设置开关 2获取开关
                 * @param state 0打开 1关闭
                 */
                override fun readHeartRateStateCallBack(type: Int, state: Int) {
                    if (type == 1) {
                        val success = state == 0
                        sendCommonState(success, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralIce -> {
            //心率0打开 1关闭
            iceControl?.controlHeartRate(if (open) 0 else 1, object : PPTorreDeviceModeChangeInterface {
                /**
                 * 心率开关状态
                 *
                 * @param type  1设置开关 2获取开关
                 * @param state 0打开 1关闭
                 */
                override fun readHeartRateStateCallBack(type: Int, state: Int) {
                    if (type == 1) {
                        val success = state == 0
                        sendCommonState(success, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            //心率0打开 1关闭
            borreControl?.getTorreDeviceManager()?.controlHeartRate(if (open) 0 else 1, object : PPTorreDeviceModeChangeInterface {
                /**
                 * 心率开关状态
                 *
                 * @param type  1设置开关 2获取开关
                 * @param state 0打开 1关闭
                 */
                override fun readHeartRateStateCallBack(type: Int, state: Int) {
                    if (type == 1) {
                        val success = state == 0
                        sendCommonState(success, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            //心率0打开 1关闭
            dorreControl?.getTorreDeviceManager()?.controlHeartRate(if (open) 0 else 1, object : PPTorreDeviceModeChangeInterface {
                /**
                 * 心率开关状态
                 *
                 * @param type  1设置开关 2获取开关
                 * @param state 0打开 1关闭
                 */
                override fun readHeartRateStateCallBack(type: Int, state: Int) {
                    if (type == 1) {
                        val success = state == 0
                        sendCommonState(success, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            //心率0打开 1关闭
            forreControl?.getTorreDeviceManager()?.controlHeartRate(if (open) 0 else 1, object : PPTorreDeviceModeChangeInterface {
                /**
                 * 心率开关状态
                 *
                 * @param type  1设置开关 2获取开关
                 * @param state 0打开/成功 1关闭/失败
                 */
                override fun readHeartRateStateCallBack(type: Int, state: Int) {
                    if (type == 1) {
                        val success = state == 0
                        sendCommonState(success, callBack)
                    }
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.fetchWifiInfo(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralApple -> {
            this.appleControl?.getWiFiParmameters(object : PPConfigWifiInfoInterface {
                override fun monitorConfigSsid(ssid: String?, deviceModel: PPDeviceModel?) {
                    sendWIFISSID(ssid, ssid.isNullOrEmpty().not(), callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralTorre -> {
            torreControl?.getTorreDeviceManager()?.getWifiSSID(object : PPTorreConfigWifiInterface() {
                /**
                 * 读取设备的SSID
                 *
                 * @param ssid
                 * @param state 0 成功 1失败
                 */
                override fun readDeviceSsidCallBack(ssid: String?, state: Int) {
                    sendWIFISSID(ssid, ssid.isNullOrEmpty().not(), callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            borreControl?.getTorreDeviceManager()?.getWifiSSID(object : PPTorreConfigWifiInterface() {
                /**
                 * 读取设备的SSID
                 *
                 * @param ssid
                 * @param state 0 成功 1失败
                 */
                override fun readDeviceSsidCallBack(ssid: String?, state: Int) {
                    sendWIFISSID(ssid, ssid.isNullOrEmpty().not(), callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            dorreControl?.getTorreDeviceManager()?.getWifiSSID(object : PPTorreConfigWifiInterface() {
                /**
                 * 读取设备的SSID
                 *
                 * @param ssid
                 * @param state 0 成功 1失败
                 */
                override fun readDeviceSsidCallBack(ssid: String?, state: Int) {
                    sendWIFISSID(ssid, ssid.isNullOrEmpty().not(), callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.getWifiInfo(object : PPConfigWifiInfoInterface {
                override fun monitorConfigSsid(ssid: String?, deviceModel: PPDeviceModel?) {
                    sendWIFISSID(ssid, ssid.isNullOrEmpty().not(), callBack)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.fetchDeviceInfo(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralApple -> {
            this.appleControl?.readDeviceInfo(object : PPDeviceInfoInterface() {
                override fun readDeviceInfoComplete(deviceModel: PPDeviceModel) {
                    val deviceInfo = convert180A(deviceModel)
                    callBack.success(deviceInfo)
                }
            })
        }

        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.readDeviceInfoFromCharacter(object : PPTorreDeviceModeChangeInterface {
                override fun onReadDeviceInfo(deviceModel: PPDeviceModel?) {
                    val deviceInfo = convert180A(deviceModel)
                    callBack.success(deviceInfo)
                }
            })
        }

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.readDeviceInfo(object : PPDeviceInfoInterface() {
                override fun readDeviceInfoComplete(deviceModel: PPDeviceModel) {
                    val deviceInfo = convert180A(deviceModel)
                    callBack.success(deviceInfo)
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.readDeviceInfoFromCharacter(object : PPTorreDeviceModeChangeInterface {
                override fun onReadDeviceInfo(deviceModel: PPDeviceModel?) {
                    val deviceInfo = convert180A(deviceModel)
                    callBack.success(deviceInfo)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.readDeviceInfoFromCharacter(object : PPTorreDeviceModeChangeInterface {
                override fun onReadDeviceInfo(deviceModel: PPDeviceModel?) {
                    val deviceInfo = convert180A(deviceModel)
                    callBack.success(deviceInfo)
                }
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.readDeviceInfoFromCharacter(object : PPTorreDeviceModeChangeInterface {
                override fun onReadDeviceInfo(deviceModel: PPDeviceModel?) {
                    val deviceInfo = convert180A(deviceModel)
                    callBack.success(deviceInfo)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.fetchWifiMac(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            torreControl?.getTorreDeviceManager()?.getWifiMac(object : PPTorreConfigWifiInterface() {
                override fun readDeviceWifiMacCallBack(wifiMac: String?) {
                    val dict = mapOf("wifiMac" to wifiMac)
                    callBack.success(dict)
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            torreControl?.getTorreDeviceManager()?.getWifiMac(object : PPTorreConfigWifiInterface() {
                override fun readDeviceWifiMacCallBack(wifiMac: String?) {
                    val dict = mapOf("wifiMac" to wifiMac)
                    callBack.success(dict)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            dorreControl?.getTorreDeviceManager()?.getWifiMac(object : PPTorreConfigWifiInterface() {
                override fun readDeviceWifiMacCallBack(wifiMac: String?) {
                    val dict = mapOf("wifiMac" to wifiMac)
                    callBack.success(dict)
                }
            })
        }


        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.scanWifiNetworks(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.getWifiList(object : PPTorreConfigWifiInterface() {
                override fun monitorWiFiListSuccess(wifoModels: List<PPWifiModel?>?) {
                    sendWifiList(wifoModels, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.getWifiList(object : PPConfigWifiInfoInterface {

                override fun monitorWiFiListSuccess(wifiModels: MutableList<PPWifiModel>?) {
                    sendWifiList(wifiModels, callBack)
                }

                override fun monitorWiFiListFail(state: Int?) {
                    sendCommonState(false, callBack)
                }

            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.getWifiList(object : PPTorreConfigWifiInterface() {
                override fun monitorWiFiListSuccess(wifoModels: List<PPWifiModel?>?) {
                    sendWifiList(wifoModels, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.getWifiList(object : PPTorreConfigWifiInterface() {
                override fun monitorWiFiListSuccess(wifoModels: List<PPWifiModel?>?) {
                    sendWifiList(wifoModels, callBack)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.wifiOTA(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.startUserOTA(object : OnOTAStateListener() {
                override fun onStartUpdate() {
                    sendWifiOTA(true, 0, callBack)
                }

                /**
                 * @param state 0普通的失败 1设备已在升级中不能再次启动升级 2设备低电量无法启动升级 3未配网 4 充电中
                 */
                override fun onUpdateFail(state: Int) {
                    if (state == 0) {
                        sendWifiOTA(true, -1, callBack)
                    } else {
                        sendWifiOTA(true, state, callBack)
                    }
                }

            })
        }

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.startUserOTA(object : OnOTAStateListener() {
                override fun onStartUpdate() {
                    sendWifiOTA(true, 0, callBack)
                }

                /**
                 * @param state 0普通的失败 1设备已在升级中不能再次启动升级 2设备低电量无法启动升级 3未配网 4 充电中
                 */
                override fun onUpdateFail(state: Int) {
                    if (state == 0) {
                        sendWifiOTA(true, -1, callBack)
                    } else {
                        sendWifiOTA(true, state, callBack)
                    }
                }

            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.startUserOTA(object : OnOTAStateListener() {
                override fun onStartUpdate() {
                    sendWifiOTA(true, 0, callBack)
                }

                /**
                 * @param state 0普通的失败 1设备已在升级中不能再次启动升级 2设备低电量无法启动升级 3未配网 4 充电中
                 */
                override fun onUpdateFail(state: Int) {
                    if (state == 0) {
                        sendWifiOTA(true, -1, callBack)
                    } else {
                        sendWifiOTA(true, state, callBack)
                    }
                }

            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.startUserOTA(object : OnOTAStateListener() {
                override fun onStartUpdate() {
                    sendWifiOTA(true, 0, callBack)
                }

                /**
                 * @param state 0普通的失败 1设备已在升级中不能再次启动升级 2设备低电量无法启动升级 3未配网 4 充电中
                 */
                override fun onUpdateFail(state: Int) {
                    if (state == 0) {
                        sendWifiOTA(true, -1, callBack)
                    } else {
                        sendWifiOTA(true, state, callBack)
                    }
                }

            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.fetchHeartRateSwitch(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            //心率0打开 1关闭
            this.torreControl?.getTorreDeviceManager()?.getHeartRateState(object : PPTorreDeviceModeChangeInterface {
                override fun readHeartRateStateCallBack(type: Int, state: Int) {
                    if (type == 2) {
                        callBack.success(mapOf("open" to (state == 0)))
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.getHeartRateState(object : PPTorreDeviceModeChangeInterface {
                override fun readHeartRateStateCallBack(type: Int, state: Int) {
                    if (type == 2) {
                        callBack.success(mapOf("open" to (state == 0)))
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.getHeartRateState(object : PPTorreDeviceModeChangeInterface {
                override fun readHeartRateStateCallBack(type: Int, state: Int) {
                    if (type == 2) {
                        callBack.success(mapOf("open" to (state == 0)))
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.getHeartRateState(object : PPTorreDeviceModeChangeInterface {
                override fun readHeartRateStateCallBack(type: Int, state: Int) {
                    if (type == 2) {
                        callBack.success(mapOf("open" to (state == 0)))
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.getHeartRateState(object : PPTorreDeviceModeChangeInterface {
                override fun readHeartRateStateCallBack(type: Int, state: Int) {
                    if (type == 2) {
                        callBack.success(mapOf("open" to (state == 0)))
                    }
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.impedanceSwitchControl(open: Boolean, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            //阻抗0打开可以测脂 1关闭不测脂
            torreControl?.getTorreDeviceManager()?.controlImpendance(if (open) 0 else 1, object : PPTorreDeviceModeChangeInterface {
                override fun controlImpendanceCallBack(type: Int, state: Int) {
                    if (type == 1) {
                        val success = state == 0
                        sendCommonState(success, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralIce -> {
            iceControl?.controlImpendance(if (open) 0 else 1, object : PPTorreDeviceModeChangeInterface {
                override fun controlImpendanceCallBack(type: Int, state: Int) {
                    if (type == 1) {
                        val success = state == 0
                        sendCommonState(success, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            borreControl?.getTorreDeviceManager()?.controlImpendance(if (open) 0 else 1, object : PPTorreDeviceModeChangeInterface {
                override fun controlImpendanceCallBack(type: Int, state: Int) {
                    if (type == 1) {
                        val success = state == 0
                        sendCommonState(success, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            dorreControl?.getTorreDeviceManager()?.controlImpendance(if (open) 0 else 1, object : PPTorreDeviceModeChangeInterface {
                override fun controlImpendanceCallBack(type: Int, state: Int) {
                    if (type == 1) {
                        val success = state == 0
                        sendCommonState(success, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            forreControl?.getTorreDeviceManager()?.controlImpendance(if (open) 0 else 1, object : PPTorreDeviceModeChangeInterface {
                override fun controlImpendanceCallBack(type: Int, state: Int) {
                    if (type == 1) {
                        val success = state == 0
                        sendCommonState(success, callBack)
                    }
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.fetchImpedanceSwitch(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.getImpendanceState(object : PPTorreDeviceModeChangeInterface {
                override fun controlImpendanceCallBack(type: Int, state: Int) {
                    callBack.success(mapOf("open" to (state == 0)))

                }
            })
        }

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.getImpendanceState(object : PPTorreDeviceModeChangeInterface {
                override fun controlImpendanceCallBack(type: Int, state: Int) {
                    if (type == 2) {
                        callBack.success(mapOf("open" to (state == 0)))
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.getImpendanceState(object : PPTorreDeviceModeChangeInterface {
                override fun controlImpendanceCallBack(type: Int, state: Int) {
                    if (type == 2) {
                        callBack.success(mapOf("open" to (state == 0)))
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.getImpendanceState(object : PPTorreDeviceModeChangeInterface {
                override fun controlImpendanceCallBack(type: Int, state: Int) {
                    if (type == 2) {
                        callBack.success(mapOf("open" to (state == 0)))
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.getImpendanceState(object : PPTorreDeviceModeChangeInterface {
                override fun controlImpendanceCallBack(type: Int, state: Int) {
                    if (type == 2) {
                        callBack.success(mapOf("open" to (state == 0)))
                    }
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.setBindingState(binding: Boolean, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    /**
     * 设备绑定状态
     *
     * @param type  1设置  2获取
     * @param state 0设备未绑定 1已绑定
     */
    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.deviceBindStatus(1, if (binding) 1 else 0, object : PPTorreDeviceModeChangeInterface {
                override fun bindStateCallBack(type: Int, state: Int) {
                    if (type == 1) {
                        val success = state == 1
                        sendCommonState(success, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.deviceBindStatus(1, if (binding) 1 else 0, object : PPTorreDeviceModeChangeInterface {
                override fun bindStateCallBack(type: Int, state: Int) {
                    if (type == 1) {
                        val success = state == 1
                        sendCommonState(success, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.deviceBindStatus(1, if (binding) 1 else 0, object : PPTorreDeviceModeChangeInterface {
                override fun bindStateCallBack(type: Int, state: Int) {
                    if (type == 1) {
                        val success = state == 0
                        sendCommonState(success, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.deviceBindStatus(1, if (binding) 1 else 0, object : PPTorreDeviceModeChangeInterface {
                override fun bindStateCallBack(type: Int, state: Int) {
                    if (type == 1) {
                        val success = state == 0
                        sendCommonState(success, callBack)
                    }
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.fetchBindingState(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {

        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.deviceBindStatus(2, 0, object : PPTorreDeviceModeChangeInterface {
                override fun bindStateCallBack(type: Int, state: Int) {
                    if (type == 2) {
                        callBack.success(mapOf("binding" to (state == 1)))
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.deviceBindStatus(2, 0, object : PPTorreDeviceModeChangeInterface {
                override fun bindStateCallBack(type: Int, state: Int) {
                    if (type == 2) {
                        callBack.success(mapOf("binding" to (state == 1)))
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.deviceBindStatus(2, 0, object : PPTorreDeviceModeChangeInterface {
                override fun bindStateCallBack(type: Int, state: Int) {
                    if (type == 2) {
                        callBack.success(mapOf("binding" to (state == 1)))
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.deviceBindStatus(2, 0, object : PPTorreDeviceModeChangeInterface {
                override fun bindStateCallBack(type: Int, state: Int) {
                    if (type == 2) {
                        callBack.success(mapOf("binding" to (state == 1)))
                    }
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.setScreenBrightness(brightness: Int, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.setLight(brightness, object : PPDeviceSetInfoInterface {
                override fun monitorLightReviseSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun monitorLightReviseFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.setLight(brightness, object : PPDeviceSetInfoInterface {
                override fun monitorLightReviseSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun monitorLightReviseFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.setLight(brightness, object : PPDeviceSetInfoInterface {
                override fun monitorLightReviseSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun monitorLightReviseFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.setLight(brightness, object : PPDeviceSetInfoInterface {
                override fun monitorLightReviseSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun monitorLightReviseFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

// 辅助方法
private fun PPLefuBleConnectManager.sendWifiList(wifiList: List<PPWifiModel?>?, callBack: Result) {
    if (wifiList == null) {
        callBack.success(mapOf("wifiList" to emptyList<Map<String, Any>>()))
        return
    }
    val list = wifiList.map { wifi ->
        wifi?.ssid ?: ""
    }
    callBack.success(mapOf("wifiList" to list))
}

fun PPLefuBleConnectManager.fetchUserIDList(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.getUserList(object : PPUserInfoInterface {
                override fun getUserListSuccess(memberIDs: List<String?>?) {
                    callBack.success(mapOf("userIDList" to memberIDs))
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.getUserList(object : PPUserInfoInterface {
                override fun getUserListSuccess(memberIDs: List<String?>?) {
                    callBack.success(mapOf("userIDList" to memberIDs))
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.getUserList(object : PPUserInfoInterface {
                override fun getUserListSuccess(memberIDs: List<String?>?) {
                    callBack.success(mapOf("userIDList" to memberIDs))
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.selectUser(user: PPUserModel, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.confirmCurrentUser(user, object : PPUserInfoInterface {
                override fun confirmCurrentUserInfoSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun confirmCurrentUserInfoFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.confirmCurrentUser(user, object : PPUserInfoInterface {
                override fun confirmCurrentUserInfoSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun confirmCurrentUserInfoFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.confirmCurrentUser(user, object : PPUserInfoInterface {
                override fun confirmCurrentUserInfoSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun confirmCurrentUserInfoFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            this.sendCommonState(false, callBack)
        }
    }
}

fun PPLefuBleConnectManager.deleteUser(user: PPUserModel, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {

            this.torreControl?.getTorreDeviceManager()?.deleteUserInfo(user, object : PPUserInfoInterface {
                override fun deleteUserInfoSuccess(userModel: PPUserModel?) {
                    sendCommonState(true, callBack)
                }

                override fun deleteUserInfoFail(userModel: PPUserModel?) {
                    sendCommonState(false, callBack)
                }
            })



        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.deleteUserInfo(user, object : PPUserInfoInterface {
                override fun deleteUserInfoSuccess(userModel: PPUserModel?) {
                    sendCommonState(true, callBack)
                }

                override fun deleteUserInfoFail(userModel: PPUserModel?) {
                    sendCommonState(false, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.deleteUserInfo(user, object : PPUserInfoInterface {
                override fun deleteUserInfoSuccess(userModel: PPUserModel?) {
                    sendCommonState(true, callBack)
                }

                override fun deleteUserInfoFail(userModel: PPUserModel?) {
                    sendCommonState(false, callBack)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            this.sendCommonState(false, callBack)
        }
    }
}

fun PPLefuBleConnectManager.startMeasure(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.startMeasure(object : PPBleSendResultCallBack {
                override fun onResult(it: PPScaleSendState?) {
                    sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.torreControl?.getTorreDeviceManager()?.startMeasure(object : PPBleSendResultCallBack {
                override fun onResult(it: PPScaleSendState?) {
                    sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.startMeasure(object : PPBleSendResultCallBack {
                override fun onResult(it: PPScaleSendState?) {
                    sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.torreControl?.getTorreDeviceManager()?.startMeasure(object : PPBleSendResultCallBack {
                override fun onResult(it: PPScaleSendState?) {
                    sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            this.sendCommonState(false, callBack)
        }
    }
}

fun PPLefuBleConnectManager.stopMeasure(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.stopMeasure(object : PPBleSendResultCallBack {
                override fun onResult(it: PPScaleSendState?) {
                    sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.stopMeasure(object : PPBleSendResultCallBack {
                override fun onResult(it: PPScaleSendState?) {
                    sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.stopMeasure(object : PPBleSendResultCallBack {
                override fun onResult(it: PPScaleSendState?) {
                    sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.stopMeasure(object : PPBleSendResultCallBack {
                override fun onResult(it: PPScaleSendState?) {
                    sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            this.sendCommonState(false, callBack)
        }
    }
}

fun PPLefuBleConnectManager.startBabyModel(step: Int, weight: Double, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            /**
             * 切换婴儿模式
             *
             * @param mode   00使能抱婴模式 01退出抱婴模式
             * @param step   0x00：第一步  0x01：第二步
             * @param weight 重量[单位10g]：当步骤为0x01[第一步]时重量发0 当步骤为0x02[第二步]时重量发第一步测得的重量
             */
            this.torreControl?.getTorreDeviceManager()?.switchBaby(0, step, weight, object : PPBleSendResultCallBack {
                override fun onResult(it: PPScaleSendState?) {
                    sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.startBaby()
            this.sendCommonState(true, callBack)
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.switchBaby(0, step, weight, object : PPBleSendResultCallBack {
                override fun onResult(it: PPScaleSendState?) {
                    sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.switchBaby(0, step, weight, object : PPBleSendResultCallBack {
                override fun onResult(it: PPScaleSendState?) {
                    sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.switchBaby(0, step, weight, object : PPBleSendResultCallBack {
                override fun onResult(it: PPScaleSendState?) {
                    sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            this.sendCommonState(false, callBack)
        }
    }
}

fun PPLefuBleConnectManager.exitBabyModel(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.switchBaby(1, 0, 0.0, object : PPBleSendResultCallBack {
                override fun onResult(it: PPScaleSendState?) {
                    sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.exitBaby()
            this.sendCommonState(true, callBack)
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.switchBaby(1, 0, 0.0, object : PPBleSendResultCallBack {
                override fun onResult(it: PPScaleSendState?) {
                    sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.switchBaby(1, 0, 0.0, object : PPBleSendResultCallBack {
                override fun onResult(it: PPScaleSendState?) {
                    sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.switchBaby(1, 0, 0.0, object : PPBleSendResultCallBack {
                override fun onResult(it: PPScaleSendState?) {
                    sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            this.sendCommonState(false, callBack)
        }
    }
}

//fun PPLefuBleConnectManager.startDFU(filePath: String, deviceFirmwareVersion: String, isForceCompleteUpdate: Boolean, callBack: Result) {
//
//
//
//
//
//    val currentDevice = deviceControl?.deviceModel
//    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
//        this.loggerStreamHandler?.sendEvent("当前无连接设备")
//        this.sendCommonState(false, callBack)
//        return
//    }
//
//    when (currentDevice.getDevicePeripheralType()) {
//        PPDevicePeripheralType.PeripheralTorre -> {
//            if (isForceCompleteUpdate) {
//                this.torreControl?.getTorreDeviceManager()?.startDFU(filePath, onDFUStateListener)
//            } else {
//                this.torreControl?.getTorreDeviceManager()?.startSmartDFU(filePath, deviceFirmwareVersion, onDFUStateListener)
//            }
//        }
//
//        PPDevicePeripheralType.PeripheralBorre -> {
//            if (isForceCompleteUpdate) {
//                this.borreControl?.getTorreDeviceManager()?.startDFU(filePath, onDFUStateListener)
//            } else {
//                this.borreControl?.getTorreDeviceManager()?.startSmartDFU(filePath, deviceFirmwareVersion, onDFUStateListener)
//            }
//        }
//
//        PPDevicePeripheralType.PeripheralDorre -> {
//            if (isForceCompleteUpdate) {
//                this.dorreControl?.getTorreDeviceManager()?.startDFU(filePath, onDFUStateListener)
//            } else {
//                this.dorreControl?.getTorreDeviceManager()?.startSmartDFU(filePath, deviceFirmwareVersion, onDFUStateListener)
//            }
//        }
//
//        PPDevicePeripheralType.PeripheralForre -> {
//            if (isForceCompleteUpdate) {
//                this.forreControl?.getTorreDeviceManager()?.startDFU(filePath, onDFUStateListener)
//            } else {
//                this.forreControl?.getTorreDeviceManager()?.startSmartDFU(filePath, deviceFirmwareVersion, onDFUStateListener)
//            }
//        }
//
//        else -> {
//            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
//            this.sendCommonState(false, callBack)
//        }
//    }
//}



fun PPLefuBleConnectManager.syncDeviceLog(logFolder: String, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }
    com.lefu.ppbase.util.Logger.e("syncDeviceLog logFolder:${logFolder}")
    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.syncLog(logFolder, deviceLogInterface)
        }

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.syncLog(logFolder, deviceLogInterface)
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.syncLog(logFolder, deviceLogInterface)
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.syncLog(logFolder, deviceLogInterface)
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.syncLog(logFolder, deviceLogInterface)
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.keepAlive() {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.startKeepAlive()
        }

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.startKeepAlive()
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.startKeepAlive()
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.startKeepAlive()
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.startKeepAlive()
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
        }
    }
}

fun PPLefuBleConnectManager.clearDeviceData(type: Int, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.clearSettingInfo(object : PPClearDataInterface {
                override fun onClearSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun onClearFail() {
                    sendCommonState(false, callBack)
                }

            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.clearSettingInfo(object : PPClearDataInterface {
                override fun onClearSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun onClearFail() {
                    sendCommonState(false, callBack)
                }

            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.clearSettingInfo(object : PPClearDataInterface {
                override fun onClearSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun onClearFail() {
                    sendCommonState(false, callBack)
                }

            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.clearSettingInfo(object : PPClearDataInterface {
                override fun onClearSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun onClearFail() {
                    sendCommonState(false, callBack)
                }

            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            this.sendCommonState(false, callBack)
        }
    }
}

fun PPLefuBleConnectManager.setDeviceLanguage(type: Int, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.setLanguage(type, object : PPDeviceSetInfoInterface {
                override fun monitorLanguageReviseSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun monitorLanguageReviseFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.setLanguage(type, object : PPDeviceSetInfoInterface {
                override fun monitorLanguageReviseSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun monitorLanguageReviseFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.setLanguage(type, object : PPDeviceSetInfoInterface {
                override fun monitorLanguageReviseSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun monitorLanguageReviseFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.setLanguage(type, object : PPDeviceSetInfoInterface {
                override fun monitorLanguageReviseSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun monitorLanguageReviseFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            this.sendCommonState(false, callBack)
        }
    }
}

fun PPLefuBleConnectManager.fetchDeviceLanguage(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.getLanguage(object : PPDeviceSetInfoInterface {
                override fun monitorLanguageValueChange(language: Int) {
                    val dict = mapOf(
                        "success" to true,
                        "languageType" to language
                    )
                    callBack.success(dict)
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.getLanguage(object : PPDeviceSetInfoInterface {
                override fun monitorLanguageValueChange(language: Int) {
                    val dict = mapOf(
                        "success" to true,
                        "languageType" to language
                    )
                    callBack.success(dict)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.getLanguage(object : PPDeviceSetInfoInterface {
                override fun monitorLanguageValueChange(language: Int) {
                    val dict = mapOf(
                        "success" to true,
                        "languageType" to language
                    )
                    callBack.success(dict)
                }
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.getLanguage(object : PPDeviceSetInfoInterface {
                override fun monitorLanguageValueChange(language: Int) {
                    val dict = mapOf(
                        "success" to true,
                        "languageType" to language
                    )
                    callBack.success(dict)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.setDisplayBodyFat(bodyFat: Int, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.syncFat(bodyFat, object : PPBleSendResultCallBack {
                override fun onResult(state: PPScaleSendState?) {
                    val success = state == PPScaleSendState.PP_SEND_SUCCESS
                    sendCommonState(success, callBack)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            this.sendCommonState(false, callBack)
        }
    }
}

fun PPLefuBleConnectManager.exitScanWifiNetworks(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.exitWifiList()
            this.sendCommonState(true, callBack)
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            this.sendCommonState(false, callBack)
        }
    }
}

fun PPLefuBleConnectManager.exitNetworkConfig(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.exitConfigWifi()
            this.sendCommonState(true, callBack)
        }

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.exitConfigWifi()
            this.sendCommonState(true, callBack)
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.exitConfigWifi()
            this.sendCommonState(true, callBack)
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.exitConfigWifi()
            this.sendCommonState(true, callBack)
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            this.sendCommonState(false, callBack)
        }
    }
}

fun PPLefuBleConnectManager.getScreenBrightness(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.getLight(object : PPDeviceSetInfoInterface {
                override fun monitorLightValueChange(light: Int) {
                    val dict = mapOf(
                        "success" to true,
                        "light" to light
                    )
                    callBack.success(dict)
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.getLight(object : PPDeviceSetInfoInterface {
                override fun monitorLightValueChange(light: Int) {
                    val dict = mapOf(
                        "success" to true,
                        "light" to light
                    )
                    callBack.success(dict)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.borreControl?.getTorreDeviceManager()?.getLight(object : PPDeviceSetInfoInterface {
                override fun monitorLightValueChange(light: Int) {
                    val dict = mapOf(
                        "success" to true,
                        "light" to light
                    )
                    callBack.success(dict)
                }
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.getLight(object : PPDeviceSetInfoInterface {
                override fun monitorLightValueChange(light: Int) {
                    val dict = mapOf(
                        "success" to true,
                        "light" to light
                    )
                    callBack.success(dict)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.syncUserInfo(model: PPUserModel, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.syncUserInfo(model, object : PPUserInfoInterface {
                override fun syncUserInfoSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun syncUserInfoFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {

            this.borreControl?.getTorreDeviceManager()?.syncUserInfo(model, object : PPUserInfoInterface {
                override fun syncUserInfoSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun syncUserInfoFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.syncUserInfo(model, object : PPUserInfoInterface {
                override fun syncUserInfoSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun syncUserInfoFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.syncUserList(userList: List<PPUserModel>, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.dorreControl?.getTorreDeviceManager()?.syncUserInfo(userList[0], object : PPUserInfoInterface {
                override fun syncUserInfoSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun syncUserInfoFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.syncUserInfo(userList[0], object : PPUserInfoInterface {
                override fun syncUserInfoSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun syncUserInfoFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.syncUserInfo(userList[0], object : PPUserInfoInterface {
                override fun syncUserInfoSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun syncUserInfoFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }


}

fun PPLefuBleConnectManager.fetchFingerprintList(callBack: Result){

    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }


    when (currentDevice.getDevicePeripheralType()) {

        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()
                ?.getUserFingerprintList { result ->
                    result?.onSuccess { list ->
                        // 将 List<PPFingerprintInfo> 转换为 List<Map<String, Any>>
                        val retList = list.map { print ->
                            mapOf(
                                "memberID" to (print.memberID ?: ""),
                                "hasFingerprint" to if (print.hasFingerprint) 1 else 0
                            )
                        }

                        // 返回结果
                        callBack.success(mapOf("fingerprintList" to retList))
                    }?.onFailure {
                        // 处理失败情况
                        callBack.success(mapOf<String, Any>())
                    }
                }
        }

            else -> {
                this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
                callBack.success(mapOf<String, Any>())
            }
        }

}

fun PPLefuBleConnectManager.registerFingerprint(user: PPUserModel, callBack: Result){

    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }


    when (currentDevice.getDevicePeripheralType()) {

        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.inputUserFingerprintStart(user) { success ->
                if (success) {
                    callBack.success(mapOf("success" to true))
                } else {
                    callBack.success(mapOf("success" to false))
                }
            }
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }

}

fun PPLefuBleConnectManager.deleteFingerprint(user: PPUserModel, callBack: Result){

    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }


    when (currentDevice.getDevicePeripheralType()) {

        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.delUserFingerprintStart(user) { success ->
                if (success) {
                    callBack.success(mapOf("success" to true))
                } else {
                    callBack.success(mapOf("success" to false))
                }
            }
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }

}

fun PPLefuBleConnectManager.setRGBMode(lightEnable:Int,lightMode:Int,defalutColor:String,gainColor:String,lossColor:String, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()
                ?.setRGB(defalutColor, gainColor, lossColor, lightEnable, lightMode, null)
        }

            else -> {
                this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
                callBack.success(mapOf<String, Any>())
            }
        }







}


fun PPLefuBleConnectManager.setDisplayMetrics(metrics: Int, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
   

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.setSingleIndicatorDisPlay(metrics) { status ->
                sendCommonState(
                    status == 1,
                    callBack
                )
            }


        }

      

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}


fun PPLefuBleConnectManager.getDisplayMetrics(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {


        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.getSingleIndicatorDisPlay { metrics ->
                callBack.success(mapOf("metrics" to metrics))}

        }



        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}


/**
 * 启动 DFU 固件升级
 * @param filePath ZIP 文件路径
 * @param deviceFirmwareVersion 设备固件版本
 * @param isForceCompleteUpdate 是否强制完整更新
 * @param callBack 回调
 */
fun PPLefuBleConnectManager.startDFU(
    filePath: String,
    deviceFirmwareVersion: String,
    isForceCompleteUpdate: Boolean,
    callBack: Result
) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        callBack.success(emptyMap<String, Any>())
        return
    }

    var deviceVersion = deviceFirmwareVersion
    if (isForceCompleteUpdate) {
        deviceVersion = "0.0.0"
    }

    // 补充版本号格式（确保有4段）
    val dotCount = deviceVersion.count { it == '.' }
    if (dotCount < 3) {
        repeat(3 - dotCount) {
            deviceVersion += ".001"
        }
    }

    try {
        // 解压 ZIP 文件
        var unzipPath = unzipDFUFile(context, filePath)
        if (unzipPath == null) {
            this.loggerStreamHandler?.sendEvent("解压路径为空")
            this.sendDfuResult(0.0, false)
            return
        }

        // 遍历目录找到包含 package.json 的实际目录
        val actualPath = findActualDFUDirectory(unzipPath)
        if (actualPath == null) {
            this.loggerStreamHandler?.sendEvent("未找到 DFU 文件目录")
            this.sendDfuResult(0.0, false)
            return
        }

        this.loggerStreamHandler?.sendEvent("找到 DFU 目录: $actualPath")
        unzipPath = actualPath + "/"

        // 根据设备类型启动 DFU
        val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.sendEvent("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            if (isForceCompleteUpdate) {
                this.torreControl?.getTorreDeviceManager()?.startDFU(unzipPath, onDFUStateListener)
            } else {
                this.torreControl?.getTorreDeviceManager()?.startSmartDFU(unzipPath, deviceFirmwareVersion, onDFUStateListener)
            }
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            if (isForceCompleteUpdate) {
                this.borreControl?.getTorreDeviceManager()?.startDFU(unzipPath, onDFUStateListener)
            } else {
                this.borreControl?.getTorreDeviceManager()?.startSmartDFU(unzipPath, deviceFirmwareVersion, onDFUStateListener)
            }
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            if (isForceCompleteUpdate) {
                this.dorreControl?.getTorreDeviceManager()?.startDFU(unzipPath, onDFUStateListener)
            } else {
                this.dorreControl?.getTorreDeviceManager()?.startSmartDFU(unzipPath, deviceFirmwareVersion, onDFUStateListener)
            }
        }

        PPDevicePeripheralType.PeripheralForre -> {
            if (isForceCompleteUpdate) {
                this.forreControl?.getTorreDeviceManager()?.startDFU(unzipPath, onDFUStateListener)
            } else {
                this.forreControl?.getTorreDeviceManager()?.startSmartDFU(unzipPath, deviceFirmwareVersion, onDFUStateListener)
            }
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            this.sendCommonState(false, callBack)
        }
    }

    } catch (e: Exception) {
        this.loggerStreamHandler?.sendEvent("DFU 启动失败: ${e.message}")
        this.sendDfuResult(0.0, false)
    }
}

/**
 * 解压 DFU ZIP 文件
 */
private fun unzipDFUFile(context: Context, zipFilePath: String): String? {
    try {
        val cacheDir = context.cacheDir
        val destDir = File(cacheDir, "Torre")

        // 清空目标目录
        if (destDir.exists()) {
            destDir.deleteRecursively()
        }
        destDir.mkdirs()

        // 解压文件
        val zipFile = File(zipFilePath)
        if (!zipFile.exists()) {
            return null
        }

        ZipInputStream(FileInputStream(zipFile)).use { zis ->
            var entry = zis.nextEntry
            while (entry != null) {
                val file = File(destDir, entry.name)
                if (entry.isDirectory) {
                    file.mkdirs()
                } else {
                    file.parentFile?.mkdirs()
                    FileOutputStream(file).use { fos ->
                        zis.copyTo(fos)
                    }
                }
                zis.closeEntry()
                entry = zis.nextEntry
            }
        }

        return destDir.absolutePath
    } catch (e: Exception) {
        e.printStackTrace()
        return null
    }
}

/**
 * 遍历目录查找 package.json 并解析配置
 */


/**
 * 查找包含 package.json 的实际 DFU 目录
 * 解压后的文件结构通常是：/cache/Torre/[子目录]/package.json
 * 需要找到这个子目录的路径
 */
private fun findActualDFUDirectory(unzipPath: String): String? {
    val dir = File(unzipPath)
    if (!dir.exists() || !dir.isDirectory) {
        return null
    }

    // 递归查找包含 package.json 的目录
    dir.walkTopDown().forEach { file ->
        if (file.isFile && file.name == "package.json") {
            // 返回包含 package.json 的目录路径
            return file.parentFile?.absolutePath
        }
    }

    return null
}


