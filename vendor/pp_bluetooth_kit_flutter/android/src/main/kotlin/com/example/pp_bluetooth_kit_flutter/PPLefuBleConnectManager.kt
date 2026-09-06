package com.example.pp_bluetooth_kit_flutter

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import com.example.pp_bluetooth_kit_flutter.ble.GpsSwitchStateReceiver
import com.example.pp_bluetooth_kit_flutter.ble.LocationHelper
import com.example.pp_bluetooth_kit_flutter.extension.convertDeviceDict
import com.example.pp_bluetooth_kit_flutter.extension.convertMeasurementDict
import com.example.pp_bluetooth_kit_flutter.extension.convertMeasurementDictFood
import com.example.pp_bluetooth_kit_flutter.extension.sendBlePermissionState
import com.example.pp_bluetooth_kit_flutter.extension.sendCommonState
import com.example.pp_bluetooth_kit_flutter.extension.sendHistoryData
import com.example.pp_bluetooth_kit_flutter.extension.sendScanState
import com.example.pp_bluetooth_kit_flutter.model.PPDfuPackageModel
import com.example.pp_bluetooth_kit_flutter.util.PPBleHelper
import com.example.pp_bluetooth_kit_flutter.util.PPBluetoothState
import com.example.pp_bluetooth_kit_flutter.util.PermissionSettingUtil
import com.example.pp_bluetooth_kit_flutter.util.PermissionUtil
import com.example.pp_bluetooth_kit_flutter.util.PermissionUtil.isLocationEnabled
import com.lefu.bluetooth.library.Constants
import com.lefu.ppbase.ImpedanceErrorType
import com.lefu.ppbase.PPBodyBaseModel
import com.lefu.ppbase.PPDeviceModel
import com.lefu.ppbase.PPScaleDefine
import com.lefu.ppbase.PPScaleDefine.PPDeviceConnectType
import com.lefu.ppbase.PPScaleDefine.PPDevicePeripheralType
import com.lefu.ppbase.util.Logger
import com.lefu.ppbase.vo.PPScaleState
import com.lefu.ppbase.vo.PPScaleStateHeartRateType
import com.lefu.ppbase.vo.PPScaleStateImpedanceType
import com.lefu.ppbase.vo.PPUserModel
import com.peng.ppscale.PPBluetoothKit
import com.peng.ppscale.PPBluetoothKit.bluetoothClient
import com.peng.ppscale.business.ble.PPScaleHelper
import com.peng.ppscale.business.ble.listener.FoodScaleDataChangeListener
import com.peng.ppscale.business.ble.listener.PPBleSendResultCallBack
import com.peng.ppscale.business.ble.listener.PPBleStateInterface
import com.peng.ppscale.business.ble.listener.PPDataChangeListener
import com.peng.ppscale.business.ble.listener.PPDeviceInfoInterface
import com.peng.ppscale.business.ble.listener.PPDeviceLogInterface
import com.peng.ppscale.business.ble.listener.PPDeviceSetInfoInterface
import com.peng.ppscale.business.ble.listener.PPHistoryDataInterface
import com.peng.ppscale.business.ble.listener.PPSearchDeviceInfoInterface
import com.peng.ppscale.business.ble.listener.PPTorreDeviceModeChangeInterface
import com.peng.ppscale.business.state.PPBleSwitchState
import com.peng.ppscale.business.state.PPBleWorkState
import com.peng.ppscale.business.torre.listener.OnDFUStateListener
import com.peng.ppscale.device.PPBlutoothPeripheralBaseController
import com.peng.ppscale.device.PeripheralApple.PPBlutoothPeripheralAppleController
import com.peng.ppscale.device.PeripheralBanana.PPBlutoothPeripheralBananaController
import com.peng.ppscale.device.PeripheralBorre.PPBlutoothPeripheralBorreController
import com.peng.ppscale.device.PeripheralCoconut.PPBlutoothPeripheralCoconutController
import com.peng.ppscale.device.PeripheralDorre.PPBlutoothPeripheralDorreController
import com.peng.ppscale.device.PeripheralDurian.PPBlutoothPeripheralDurianController
import com.peng.ppscale.device.PeripheralEgg.PPBlutoothPeripheralEggController
import com.peng.ppscale.device.PeripheralFish.PPBlutoothPeripheralFishController
import com.peng.ppscale.device.PeripheralForre.PPBlutoothPeripheralForreController
import com.peng.ppscale.device.PeripheralGrapes.PPBlutoothPeripheralGrapesController
import com.peng.ppscale.device.PeripheralHamburger.PPBlutoothPeripheralHamburgerController
import com.peng.ppscale.device.PeripheralIce.PPBlutoothPeripheralIceController
import com.peng.ppscale.device.PeripheralJambul.PPBlutoothPeripheralJambulController
import com.peng.ppscale.device.PeripheralTorre.PPBlutoothPeripheralTorreController
import com.peng.ppscale.search.PPSearchManager
import com.peng.ppscale.util.UnitUtil
import com.peng.ppscale.util.UnitUtils
import com.peng.ppscale.vo.LFFoodScaleGeneral
import com.peng.ppscale.vo.PPScaleSendState
import io.flutter.plugin.common.MethodChannel.Result

/**
 * 蓝牙扫描类型枚举
 */
enum class PPLefuScanType(val value: Int) {
    SCAN(0)
}

/**
 * 蓝牙连接管理器
 * 负责处理蓝牙设备的扫描、连接和数据交互
 */
class PPLefuBleConnectManager private constructor(val context: Context) {

    companion object {
        @Volatile
        private var instance: PPLefuBleConnectManager? = null

        fun getInstance(context: Context): PPLefuBleConnectManager {
            return instance ?: synchronized(this) {
                instance ?: PPLefuBleConnectManager(context).also { instance = it }
            }
        }
    }

    // Stream handlers for Flutter event channels
    var scanResultStreamHandler: PPLefuStreamHandler? = null
    var loggerStreamHandler: PPLefuStreamHandler? = null
    var connectStateStreamHandler: PPLefuStreamHandler? = null
    var measureStreamHandler: PPLefuStreamHandler? = null
    var historyStreamHandler: PPLefuStreamHandler? = null
    var batteryStreamHandler: PPLefuStreamHandler? = null
    var blePermissionStreamHandler: PPLefuStreamHandler? = null
    var dfuStreamHandler: PPLefuStreamHandler? = null
    var deviceLogStreamHandler: PPLefuStreamHandler? = null
    var scanStateStreamHandler: PPLefuStreamHandler? = null
    var kitchenStreamHandler: PPLefuStreamHandler? = null

    var ppScale: PPSearchManager? = null


    // 蓝牙状态相关
    private var scanType: PPLefuScanType = PPLefuScanType.SCAN

    // 连接状态和历史数据
    private var connectState: Int = 0
    private var tempScaleHistoryList: MutableList<PPBodyBaseModel>? = null

    // 防抖相关
    private var lastDisconnectTime: Long = 0
    private var isProcessingDisconnect: Boolean = false

    // 光照强度
    private var currentLightStrength: Int? = null

    // 设备控制器
    var currentDevice: PPDeviceModel? = null

    //当前的Controller
    var deviceControl: PPBlutoothPeripheralBaseController? = null

    var appleControl: PPBlutoothPeripheralAppleController? = null
    var coconutControl: PPBlutoothPeripheralCoconutController? = null
    var torreControl: PPBlutoothPeripheralTorreController? = null
    var iceControl: PPBlutoothPeripheralIceController? = null
    var bananaControl: PPBlutoothPeripheralBananaController? = null
    var jambulControl: PPBlutoothPeripheralJambulController? = null
    var borreControl: PPBlutoothPeripheralBorreController? = null
    var dorreControl: PPBlutoothPeripheralDorreController? = null
    var forreControl: PPBlutoothPeripheralForreController? = null
    var fishControl: PPBlutoothPeripheralFishController? = null
    var eggControl: PPBlutoothPeripheralEggController? = null
    var hamburgerControl: PPBlutoothPeripheralHamburgerController? = null
    var grapesControl: PPBlutoothPeripheralGrapesController? = null
    var durianControl: PPBlutoothPeripheralDurianController? = null

    // DFU相关
    var unzipFilePath: String? = null
    var dfuConfig: PPDfuPackageModel? = null

    // 临时设备字典
    private val tempDeviceDict = mutableMapOf<String, PPDeviceModel>()

    fun initSDK() {
        Logger.e("PPLefuBleConnectManager initSDK")
        ppScale = PPSearchManager.getInstance()
        ppScale?.registerBluetoothStateListener(bleStateInterface)
    }

    fun isScanning(): Boolean {
        var b = false
        if (ppScale?.isSearching == true) {
            b = true
        }
        return b
    }

    fun isConnect(): Boolean {
        deviceControl?.deviceModel?.let {
            val connectState = PPBluetoothKit.bluetoothClient?.getConnectStatus(deviceControl?.deviceModel?.deviceMac)
            val isConnect: Boolean = connectState == Constants.STATUS_DEVICE_CONNECTED
            Logger.d("isConnect() deviceName:${deviceControl?.deviceModel?.deviceName} deviceMac:${deviceControl?.deviceModel?.deviceMac} isConnect  $isConnect connectState:$connectState")
            return isConnect
        }
        return false
    }

    fun isConnecting(): Boolean {
        deviceControl?.deviceModel?.let {
            val connectState = PPBluetoothKit.bluetoothClient?.getConnectStatus(deviceControl?.deviceModel?.deviceMac)
            val isConnect: Boolean = connectState == Constants.STATUS_DEVICE_CONNECTING
            Logger.d("isConnecting() deviceName:${deviceControl?.deviceModel?.deviceName} deviceMac:${deviceControl?.deviceModel?.deviceMac} isConnect  $isConnect connectState:$connectState")
            return isConnect
        }
        return false
    }

    fun isConnected(address: String?): Boolean {
        if (address.isNullOrEmpty()) {
            return false
        }
        bluetoothClient?.let { client ->
            return client.getConnectStatus(address) == Constants.STATUS_DEVICE_CONNECTED
        }
        return false
    }

    fun isConnecting(address: String?): Boolean {
        if (address.isNullOrEmpty()) {
            return false
        }
        bluetoothClient?.let { client ->
            return client.getConnectStatus(address) == Constants.STATUS_DEVICE_CONNECTING
        }
        return false
    }

    fun isDisconnecting(): Boolean {
        deviceControl?.deviceModel?.let {
            val connectState = PPBluetoothKit.bluetoothClient?.getConnectStatus(deviceControl?.deviceModel?.deviceMac)
            val isDisconnecting: Boolean = connectState == Constants.STATUS_DEVICE_DISCONNECTING
            Logger.d("isDisconnecting() deviceName:${deviceControl?.deviceModel?.deviceName} deviceMac:${deviceControl?.deviceModel?.deviceMac} isDisconnecting  $isDisconnecting connectState:$connectState")
            return isDisconnecting
        }
        return false
    }

    fun isConnectOrConnecting(): Boolean {
        return deviceControl?.connectState() == true
    }

    /**
     * 开始扫描设备
     */
    fun startScan(deviceMac: String?, callBack: Result) {

        if (isScanning()) {
            Logger.e("PPLefuBleConnectManager startScan isScanning true return 蓝牙已经在扫描中")
            sendCommonState(true, callBack)
            return
        }

        tempDeviceDict.clear()
        scanDevice(PPLefuScanType.SCAN, callBack)
    }

    /**
     * 扫描设备
     */
    fun scanDevice(type: PPLefuScanType, callBack: Result) {

        scanType = type

        sendCommonState(true, callBack)
        tempDeviceDict.clear()

        //5s如果没有搜到任何设备，则认定为搜索失败，外部可重启扫描
        ppScale?.startSearchDeviceList(300000, searchDeviceInfoInterface, bleStateInterface)

    }



    /**
     * 连接设备
     */
    fun connectDevice(deviceMac: String, deviceName: String) {

        val isConnect = isConnected(deviceMac)

        if (isConnect) {
            loggerStreamHandler?.sendEvent("$deviceName $deviceMac -该设备已连接，继续使用")
            sendConnectState(1)
            return
        }
        if (isConnecting(deviceMac)) {
            loggerStreamHandler?.sendEvent("$deviceName $deviceMac -该设备正在连接中，请稍候")
//            sendConnectState(1)
            return
        }
        if (tempDeviceDict.containsKey(deviceMac)) {
            val device = tempDeviceDict[deviceMac]
            stopScan()
            realConnectDevice(device)
        } else {
            loggerStreamHandler?.sendEvent("找不到设备-$deviceMac")
            sendConnectState(2)
        }
    }

    /**
     * 前面要做连接前的防频繁和防已连接等问题
     * 真正连接设备
     */
    private fun realConnectDevice(device: PPDeviceModel?) {
        if (device != null) {
            currentDevice = device
            loggerStreamHandler?.sendEvent("开始连接设备:${device.deviceName} ${device.deviceName} ${device.getDevicePeripheralType()}")

            when (device.getDevicePeripheralType()) {
                PPDevicePeripheralType.PeripheralApple -> {
                    appleControl = PPBlutoothPeripheralAppleController()
                    deviceControl = appleControl
                }

                PPDevicePeripheralType.PeripheralCoconut -> {
                    coconutControl = PPBlutoothPeripheralCoconutController()
                    deviceControl = coconutControl
                }

                PPDevicePeripheralType.PeripheralTorre -> {
                    torreControl = PPBlutoothPeripheralTorreController()
                    deviceControl = torreControl
                }

                PPDevicePeripheralType.PeripheralIce -> {
                    iceControl = PPBlutoothPeripheralIceController()
                    deviceControl = iceControl
                }

                PPDevicePeripheralType.PeripheralBorre -> {
                    borreControl = PPBlutoothPeripheralBorreController()
                    deviceControl = borreControl
                }

                PPDevicePeripheralType.PeripheralDorre -> {
                    dorreControl = PPBlutoothPeripheralDorreController()
                    deviceControl = dorreControl
                }

                PPDevicePeripheralType.PeripheralForre -> {
                    forreControl = PPBlutoothPeripheralForreController()
                    deviceControl = forreControl
                }

                PPDevicePeripheralType.PeripheralFish -> {
                    fishControl = PPBlutoothPeripheralFishController()
                    deviceControl = fishControl
                }

                PPDevicePeripheralType.PeripheralEgg -> {
                    eggControl = PPBlutoothPeripheralEggController()
                    deviceControl = eggControl
                }

                PPDevicePeripheralType.PeripheralDurian -> {
                    durianControl = PPBlutoothPeripheralDurianController()
                    deviceControl = durianControl
                }

                else -> {
                    loggerStreamHandler?.sendEvent("不支持的设备类型-peripheralType:${device.getDevicePeripheralType()}")
                    sendConnectState(2)
                }
            }
            deviceControl?.startConnect(device, bleStateInterface)
        }
    }

    /**
     * 停止扫描
     */
    public fun stopScan() {
        if (isScanning()) {
            ppScale?.stopSearch()
            sendScanState(false)
        }
    }

    /**
     * 断开连接
     */
    fun disconnect() {
        if (PPScaleHelper.isSupportConnect(deviceControl?.deviceModel?.deviceConnectType?.getType())) {
            if (deviceControl?.connectState() == true) {
                deviceControl?.disConnect()
            } else {
                Logger.e("PPLefuBleConnectManager disconnect 设备未连接,无需断开")
            }
            clearData()
        }
    }

    /**
     * 清除数据
     */
    fun clearData() {
        deviceControl = null
        coconutControl = null
        torreControl = null
        iceControl = null
        borreControl = null
        forreControl = null
        fishControl = null
        eggControl = null
        durianControl = null
        currentDevice = null

        currentLightStrength = null
    }

    /**
     * 发送连接状态
     * 连接状态 0:断开连接 1:连接成功 2:连接错误
     */
    fun sendConnectState(state: Int) {
        // 防抖：如果是断开连接状态，检查是否在500ms内已经发送过
        if (state == 0) {
            val currentTime = System.currentTimeMillis()
            if (isProcessingDisconnect || (currentTime - lastDisconnectTime) < 500) {
                loggerStreamHandler?.sendEvent("连接状态:$state - 重复事件，忽略")
                return
            }
            lastDisconnectTime = currentTime
            isProcessingDisconnect = true

            // 500ms后重置标志
            Handler(Looper.getMainLooper()).postDelayed({
                isProcessingDisconnect = false
            }, 500)
        }

        loggerStreamHandler?.sendEvent("连接状态:$state")

        connectState = state

        val mac = deviceControl?.deviceModel?.deviceMac ?: ""
        val params = mapOf(
            "deviceMac" to mac,
            "state" to state
        )

        connectStateStreamHandler?.sendEvent(params)
    }

    /**
     * 获取历史数据
     */
    fun fetchHistory(model: PPUserModel, callBack: Result? = null) {
        if (!(deviceControl?.connectState() ?: false)) {
            loggerStreamHandler?.sendEvent("当前无连接设备")
            callBack?.let { sendCommonState(false, it) }
            return
        }

        when (deviceControl?.deviceModel?.getDevicePeripheralType()) {
            PPDevicePeripheralType.PeripheralApple -> {
                tempScaleHistoryList = mutableListOf()
                appleControl?.getHistoryData(historyDataInterface, null)
            }

            PPDevicePeripheralType.PeripheralCoconut -> {
                tempScaleHistoryList = mutableListOf()
                coconutControl?.getHistoryData(historyDataInterface)
            }

            PPDevicePeripheralType.PeripheralTorre -> {
                tempScaleHistoryList = mutableListOf()
                if (model.userID.equals("30")) {
                    torreControl?.getTorreDeviceManager()?.syncTouristHistory(historyDataInterface)
                } else {
                    torreControl?.getTorreDeviceManager()?.syncUserHistory(model, historyDataInterface)
                }
            }

            PPDevicePeripheralType.PeripheralIce -> {
                iceControl?.getHistory(historyDataInterface)
            }

            PPDevicePeripheralType.PeripheralBorre -> {
                if (model.userID.equals("30")) {
                    borreControl?.getTorreDeviceManager()?.syncTouristHistory(historyDataInterface)
                } else {
                    borreControl?.getTorreDeviceManager()?.syncUserHistory(model, historyDataInterface)
                }
            }

            PPDevicePeripheralType.PeripheralDorre -> {
                if (model.userID.equals("30")) {
                    dorreControl?.getTorreDeviceManager()?.syncTouristHistory(historyDataInterface)
                } else {
                    dorreControl?.getTorreDeviceManager()?.syncUserHistory(model, historyDataInterface)
                }
            }

            else -> {
                loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice?.getDevicePeripheralType()}")
                callBack?.let { sendCommonState(false, it) }
            }
        }
    }

    /**
     * 删除历史数据
     */
    fun deleteHistory(callBack: Result? = null) {
        if (!(deviceControl?.connectState() ?: false)) {
            loggerStreamHandler?.sendEvent("当前无连接设备")
            callBack?.let { sendCommonState(false, it) }
            return
        }

        when (currentDevice?.getDevicePeripheralType()) {
            PPDevicePeripheralType.PeripheralApple -> {
                appleControl?.deleteHistoryData(object : PPBleSendResultCallBack {
                    override fun onResult(sendState: PPScaleSendState?) {
                        if (sendState == PPScaleSendState.PP_SEND_SUCCESS) {
                            sendCommonState(true, callBack)
                        } else {
                            sendCommonState(false, callBack)
                        }
                    }
                })
            }

            PPDevicePeripheralType.PeripheralCoconut -> {
                coconutControl?.deleteHistoryData(object : PPBleSendResultCallBack {
                    override fun onResult(sendState: PPScaleSendState?) {
                        if (sendState == PPScaleSendState.PP_SEND_SUCCESS) {
                            sendCommonState(true, callBack)
                        } else {
                            sendCommonState(false, callBack)
                        }
                    }
                })
            }

            PPDevicePeripheralType.PeripheralIce -> {
                iceControl?.deleteHistoryData(object : PPBleSendResultCallBack {
                    override fun onResult(sendState: PPScaleSendState?) {
                        if (sendState == PPScaleSendState.PP_SEND_SUCCESS) {
                            sendCommonState(true, callBack)
                        } else {
                            sendCommonState(false, callBack)
                        }
                    }
                })
            }

            else -> {
                loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice?.getDevicePeripheralType()}")
                callBack?.let { sendCommonState(false, it) }
            }
        }
    }

    /**
     * 获取电池信息
     */
    fun fetchBatteryInfo(callBack: Result? = null) {
        if (!(deviceControl?.connectState() ?: false)) {
            loggerStreamHandler?.sendEvent("当前无连接设备")
            batteryStreamHandler?.sendEvent(mapOf("power" to 0, "type" to -1))
            callBack?.let { sendCommonState(false, it) }
            return
        }

        when (currentDevice?.getDevicePeripheralType()) {
            PPDevicePeripheralType.PeripheralApple -> {
                appleControl?.readDeviceBattery(deviceInfoInterface)
                callBack?.let { sendCommonState(true, it) }
            }

            PPDevicePeripheralType.PeripheralTorre -> {
                torreControl?.getTorreDeviceManager()?.readDeviceBattery(torreDeviceModeChangeInterface)
            }

            PPDevicePeripheralType.PeripheralCoconut -> {
                coconutControl?.readDeviceBattery(deviceInfoInterface)
            }

            PPDevicePeripheralType.PeripheralIce -> {
                iceControl?.readDeviceBattery(deviceInfoInterface)
            }

            PPDevicePeripheralType.PeripheralBorre -> {
                borreControl?.getTorreDeviceManager()?.readDeviceBattery(torreDeviceModeChangeInterface)
            }

            PPDevicePeripheralType.PeripheralDorre -> {
                dorreControl?.getTorreDeviceManager()?.readDeviceBattery(torreDeviceModeChangeInterface)
            }

            PPDevicePeripheralType.PeripheralForre -> {
                forreControl?.getTorreDeviceManager()?.readDeviceBattery(torreDeviceModeChangeInterface)
            }

            PPDevicePeripheralType.PeripheralFish -> {
            }

            PPDevicePeripheralType.PeripheralEgg -> {
            }

            else -> {
                loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice?.getDevicePeripheralType()}")
                batteryStreamHandler?.sendEvent(mapOf("power" to 0, "type" to -1))
                callBack?.let { sendCommonState(false, it) }
            }
        }
    }

    /**
     * 重置设备
     */
    fun resetDevice(callBack: Result? = null) {
        if (!(deviceControl?.connectState() ?: false)) {
            loggerStreamHandler?.sendEvent("当前无连接设备")
            callBack?.let { sendCommonState(false, it) }
            return
        }

        when (currentDevice?.getDevicePeripheralType()) {
            PPDevicePeripheralType.PeripheralApple -> {
                appleControl?.sendResetDevice(deviceSetInfoInterface, object : PPBleSendResultCallBack {
                    override fun onResult(sendState: PPScaleSendState?) {
                        if (sendState == PPScaleSendState.PP_SEND_SUCCESS) {
                            sendCommonState(true, callBack)
                        } else {
                            sendCommonState(false, callBack)
                        }
                    }

                })

            }

            PPDevicePeripheralType.PeripheralIce -> {
                iceControl?.sendResetDevice(deviceSetInfoInterface)
                sendCommonState(true, callBack)
            }

            PPDevicePeripheralType.PeripheralTorre -> {
                torreControl?.getTorreDeviceManager()?.resetDevice(deviceSetInfoInterface)
                sendCommonState(true, callBack)
            }

            PPDevicePeripheralType.PeripheralBorre -> {
                borreControl?.getTorreDeviceManager()?.resetDevice(deviceSetInfoInterface)
                sendCommonState(true, callBack)
            }

            PPDevicePeripheralType.PeripheralDorre -> {
                dorreControl?.getTorreDeviceManager()?.resetDevice(deviceSetInfoInterface)
                sendCommonState(true, callBack)
            }

            PPDevicePeripheralType.PeripheralForre -> {
                forreControl?.getTorreDeviceManager()?.resetDevice(deviceSetInfoInterface)
                sendCommonState(true, callBack)
            }

            else -> {
                loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice?.getDevicePeripheralType()}")
                callBack?.let { sendCommonState(false, it) }
            }
        }
    }

    /**
     * 接收广播数据
     */
    fun unReceiveBroadcastData(deviceMac: String, callBack: Result) {
        val device = tempDeviceDict[deviceMac]

        if (device == null) {
            Logger.e("receiveBroadcastData 找不到当前设备 deviceMac:$deviceMac")
            loggerStreamHandler?.sendEvent("找不到当前设备 deviceMac:$deviceMac")
            sendCommonState(false, callBack)
            return
        }

        if (device.deviceConnectType != PPDeviceConnectType.PPDeviceConnectTypeBroadcast) {
            loggerStreamHandler?.sendEvent("${device.deviceName}-${device.deviceMac}不是广播秤")
            Logger.e("receiveBroadcastData ${device.deviceName}-${device.deviceMac}不是广播秤")
            sendCommonState(false, callBack)
            return
        }

        currentDevice = device

        when (device.getDevicePeripheralType()) {
            PPDevicePeripheralType.PeripheralBanana -> {
                Logger.d("unReceiveBroadcastData PeripheralBanana")
                bananaControl?.registDataChangeListener(null)
//                bananaControl?.stopSeach()
            }

            PPDevicePeripheralType.PeripheralJambul -> {
                Logger.d("unReceiveBroadcastData PeripheralJambul")
                jambulControl?.registDataChangeListener(null)
//                jambulControl?.stopSeach()
            }

            PPDevicePeripheralType.PeripheralHamburger -> {
                Logger.d("unReceiveBroadcastData PeripheralHamburger")
                hamburgerControl?.registDataChangeListener(null)
//                hamburgerControl?.stopSeach()
            }

            PPDevicePeripheralType.PeripheralGrapes -> {
                Logger.d("unReceiveBroadcastData PeripheralGrapes")
                grapesControl?.registDataChangeListener(null)
//                grapesControl?.stopSeach()
            }

            else -> {
                currentDevice = null
            }
        }

        if (currentDevice != null) {
            sendCommonState(true, callBack)
        } else {
            sendCommonState(false, callBack)
        }
    }

    fun receiveBroadcastData(deviceMac: String, callBack: Result) {
        val device = tempDeviceDict[deviceMac]

        if (device == null) {
            Logger.e("receiveBroadcastData 找不到当前设备 deviceMac:$deviceMac")
            loggerStreamHandler?.sendEvent("找不到当前设备 deviceMac:$deviceMac")
            sendCommonState(false, callBack)
            return
        }

        if (device.deviceConnectType != PPDeviceConnectType.PPDeviceConnectTypeBroadcast) {
            loggerStreamHandler?.sendEvent("${device.deviceName}-${device.deviceMac}不是广播秤")
            Logger.e("receiveBroadcastData ${device.deviceName}-${device.deviceMac}不是广播秤")
            sendCommonState(false, callBack)
            return
        }

        if (!PPBleHelper.isOpenBluetooth()) {
            loggerStreamHandler?.sendEvent("接收广播失败-蓝牙开关未打开")
            Logger.e("receiveBroadcastData 接收广播失败-蓝牙开关未打开")
            sendCommonState(false, callBack)
            return
        }

        currentDevice = device

        when (device.getDevicePeripheralType()) {
            PPDevicePeripheralType.PeripheralBanana -> {
                bananaControl = PPBlutoothPeripheralBananaController()
                bananaControl?.deviceModel = device
                deviceControl = bananaControl
                registerDataChangeListener()
//                if (isScanning().not()) {
//                    bananaControl?.startSearch(device.deviceMac, bleStateInterface)
//                }
            }

            PPDevicePeripheralType.PeripheralJambul -> {
                jambulControl = PPBlutoothPeripheralJambulController()
                jambulControl?.deviceModel = device
                deviceControl = jambulControl
                registerDataChangeListener()
//                if (isScanning().not()) {
//                    jambulControl?.startSearch(device.deviceMac, bleStateInterface)
//                }
            }

            PPDevicePeripheralType.PeripheralHamburger -> {
                hamburgerControl = PPBlutoothPeripheralHamburgerController()
                hamburgerControl?.deviceModel = device
                deviceControl = hamburgerControl
                registerDataChangeListener()
//                if (isScanning().not()) {
//                    hamburgerControl?.startSearch(device.deviceMac, bleStateInterface)
//                }
            }

            PPDevicePeripheralType.PeripheralGrapes -> {
                grapesControl = PPBlutoothPeripheralGrapesController()
                grapesControl?.deviceModel = device
                deviceControl = grapesControl
                registerDataChangeListener()
//                if (isScanning().not()) {
//                    grapesControl?.startSearch(device.deviceMac, bleStateInterface)
//                }
            }

            else -> {
                currentDevice = null
            }
        }
        if (currentDevice != null) {
            sendCommonState(true, callBack)
        } else {
            sendCommonState(false, callBack)
        }
    }

    /**
     * 发送广播数据
     */
    fun sendBroadcastData(cmd: String, unitType: Int, callBack: Result) {


        if (currentDevice?.getDevicePeripheralType() == PPDevicePeripheralType.PeripheralJambul && jambulControl != null
            && PPScaleHelper.isFuncTypeTwoBrocast(jambulControl?.deviceModel?.deviceFuncType)
        ) {
            val mode = if (cmd.equals("38")) 1 else 0

            val userModel = PPUserModel.Builder().setPregnantMode(mode == 1).build()
            jambulControl?.stopAdvertising()
            jambulControl?.startBroadCast(UnitUtil.getUnitType(unitType), userModel, jambulControl?.deviceModel)
            sendCommonState(true, callBack)
        } else {
            loggerStreamHandler?.sendEvent("不支持的功能-jambul:${jambulControl}-peripheralType:${currentDevice?.getDevicePeripheralType()}")
            sendCommonState(false, callBack)
        }
    }

    /**
     * 获取已连接设备
     */
    fun fetchConnectedDevice(callBack: Result) {
        if (currentDevice != null) {
            val dict = convertDeviceDict(currentDevice!!)
            callBack.success(dict)
        } else {
            callBack.success(emptyMap<String, Any>())
        }
    }

    /**
     * 添加蓝牙权限监听
     * 调用此方法，立即返回当前蓝牙权限状态，并实时监听蓝牙权限状态变化
     *
     * Android 蓝牙权限说明：
     * 1. 优先级，
     *   - 先判断蓝牙下相关权限是否授权，
     *   - 再判断定位开关是否打开（Android12以下设备），
     *   - 再判断蓝牙开关是否打开
     * 2. 不同的状态的处理方式
     * 1-未授权，调用申请蓝牙权限API
     * 2-蓝牙开，系统蓝牙打开，此时检测所有权限API，若收到2(蓝牙开)，则具备所有权限，若回复其他状态则相应的处理即可
     * 3-蓝牙关，调用请求开启蓝牙开关API
     * 4-定位开关开，用户主动打开定位开关，处理逻辑与2一样
     * 5-定位开关关闭，弹窗，让用户选择是否去开启定位开关，选择去设置，则跳转到设置定位开关设置页面，此处桥阶层提供API
     * 6-权限被永久拒绝，此时弹窗，让用户选择是否去开启蓝牙相关权限，选择去设置，则跳转到系统应用权限申请页面，此处桥阶层提供API。
     */
    fun addBlePermissionListener() {
        try {
            if (PermissionUtil.isPermissionPermanentlyDenied(context) == true) {
                Logger.i("DeviceManager addBlePermissionListenmer permanently denied 权限被永久拒绝")
                sendBlePermissionState(PPBluetoothState.PERMANENTLY_DENY)
                return
            }
            if (PermissionUtil.isHasBluetoothPermissions(context)) {
                initGpsLocationListener()
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
                    // Android 12 以下需要检查定位开关
                    if (!isLocationEnabled(context)) {
                        Logger.i("DeviceManager addBlePermissionListener location off")
                        sendBlePermissionState(PPBluetoothState.POSITIONING_OFF)
                        return
                    }
                }
                // Android 12+ 不需要检查定位开关
                if (PPBleHelper.isOpenBluetooth()) {
                    //蓝牙一斤可以用了
                    Logger.i("DeviceManager addBlePermissionListener bluetooth on")
                    sendBlePermissionState(PPBluetoothState.POWERED_ON)
                } else {
                    Logger.i("DeviceManager addBlePermissionListener bluetooth off")
                    sendBlePermissionState(PPBluetoothState.POWERED_OFF)
                }
            } else {
                Logger.i("DeviceManager addBlePermissionListener permission unauthorized")
                sendBlePermissionState(PPBluetoothState.UNAUTHORIZED)
            }
        } catch (e: Exception) {
            Logger.e("DeviceManager addBlePermissionListener exception ${e.message}")
            sendBlePermissionState(PPBluetoothState.UNAUTHORIZED)
            e.printStackTrace()
        }
    }

    /**
     * 请求打开蓝牙
     */
    fun openBluetooth() {
        if (PermissionUtil.isHasBluetoothPermissions(context)) {
            bluetoothClient?.openBluetooth()
        } else {
            Logger.i("DeviceManager openBluetooth permission unauthorized")
        }
    }


    /**
     * 直接跳转至位置信息设置界面
     */
    fun openLocation() {
        try {
            val intent = Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
            context.startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /**
     * 跳转到权限设置页面
     */
    fun gotoPermissionSetting() {
        PermissionSettingUtil.gotoPermissionSetting(context)


    }

    /**
     * 申请蓝牙权限
     */
    fun requestBluetoothPermission() {
        PermissionUtil.requestBluetoothPermission(context)
    }

    /**
     * 注册定位开关监听，
     */
    fun initGpsLocationListener() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S || PermissionUtil.isHuaweiOS()) {
            if (PermissionUtil.isHasBluetoothPermissions(context)) {
                Logger.i("DeviceManager initGpsLocationListener")
                context?.let { LocationHelper.registerLocationListener(it, onGPSChangeListener) }
            }
        }
    }

    val onGPSChangeListener = object : GpsSwitchStateReceiver.OnGPSChangeListener {

        override fun onChange(isGpsEnabled: Boolean) {
            Logger.i("DeviceManager onGPSChangeListener onChange isGpsEnabled:$isGpsEnabled")
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S || PermissionUtil.isHuaweiOS()) {
                if (isGpsEnabled.not()) {
                    stopScan()
                    disconnect()
                    sendBlePermissionState(PPBluetoothState.POSITIONING_OFF)
                } else {
                    sendBlePermissionState(PPBluetoothState.POSITIONING_ON)
                }
            }
        }
    }

    /**
     * 归零操作
     */
    fun toZero(callBack: Result) {
        if (!(deviceControl?.connectState() ?: false)) {
            loggerStreamHandler?.sendEvent("当前无连接设备")
            sendCommonState(false, callBack)
            return
        }

        when (currentDevice?.getDevicePeripheralType()) {
            PPDevicePeripheralType.PeripheralFish -> {
                fishControl?.toZeroKitchenScale(object : PPBleSendResultCallBack {
                    override fun onResult(sendState: PPScaleSendState?) {
                        if (sendState == PPScaleSendState.PP_SEND_SUCCESS) {
                            sendCommonState(true, callBack)
                        } else {
                            sendCommonState(false, callBack)
                        }
                    }
                })
            }

            PPDevicePeripheralType.PeripheralEgg -> {
                eggControl?.toZeroKitchenScale(object : PPBleSendResultCallBack {
                    override fun onResult(sendState: PPScaleSendState?) {
                        if (sendState == PPScaleSendState.PP_SEND_SUCCESS) {
                            sendCommonState(true, callBack)
                        } else {
                            sendCommonState(false, callBack)
                        }
                    }

                })
            }

            else -> {
                loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice?.getDevicePeripheralType()}")
                sendCommonState(false, callBack)
            }
        }
    }

    fun changeBuzzerGate(open: Boolean, callBack: Result) {

        if (!(deviceControl?.connectState() ?: false)) {
            loggerStreamHandler?.sendEvent("当前无连接设备")
            sendCommonState(false, callBack)
            return
        }

        when (currentDevice?.getDevicePeripheralType()) {
            PPDevicePeripheralType.PeripheralFish -> {
                fishControl?.switchBuzzer(open, object : PPBleSendResultCallBack {
                    override fun onResult(sendState: PPScaleSendState?) {
                        if (sendState == PPScaleSendState.PP_SEND_SUCCESS) {
                            sendCommonState(true, callBack)
                        } else {
                            sendCommonState(false, callBack)
                        }
                    }
                })
            }

            else -> {
                loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice?.getDevicePeripheralType()}")
                sendCommonState(false, callBack)
            }
        }


    }

    fun foodScaleUnit(
        weightG: Number,
        accuracyType: Int,
        unitType: Int,
        callBack: Result
    ) {

        val unit = UnitUtil.getUnitType(unitType)

        // 3. 重量计算逻辑（精度为 .point01G 时乘以 10）
        var weight = weightG.toDouble()
        if (accuracyType == PPScaleDefine.PPDeviceAccuracyType.PPDeviceAccuracyTypePoint01G.getType()) {
            weight = weight * 10
        }

        val weightStr = UnitUtils.getValue(weight, unit, weight > 0, accuracyType)

        // 4. 调用工具类获取重量字典


        // 5. 拼接重量字符串
//        var weightStr = ""
//        if (unit == PPUnitType.PPUnitLBOZ) {
//            // 单位为磅盎司时，拼接 "lb:oz"
//            val lb = dic["lboz_lb"] ?: ""
//            val oz = dic["lboz_oz"] ?: ""
//            weightStr = "$lb:$oz"
//        } else {
//            // 其他单位取 weight 字段
//            weightStr = dic["weight"] ?: ""
//            // 重量为 0 时强制显示 "0"（处理 Float 转 String 可能的异常）
//            val weightFloat = weightStr.toFloatOrNull() ?: 0f
//            if (weightFloat == 0f) {
//                weightStr = "0"
//            }
//        }

        // 6. 执行回调（返回 Map 结构）

        callBack.success(mapOf("weightStr" to weightStr))

    }


    val bleStateInterface = object : PPBleStateInterface() {
        override fun monitorBluetoothWorkState(ppBleWorkState: PPBleWorkState?, deviceModel: PPDeviceModel?) {
            Logger.e("monitorBluetoothWorkState:${ppBleWorkState}")
            if (ppBleWorkState == PPBleWorkState.PPBleWorkStateConnected) {

            } else if (ppBleWorkState == PPBleWorkState.PPBleWorkStateConnecting) {

            } else if (ppBleWorkState == PPBleWorkState.PPBleWorkStateDisconnected) {

                Logger.d("设备断开连接:${deviceModel?.deviceName} ${deviceModel?.deviceMac}")
                sendConnectState(0)

            } else if (ppBleWorkState == PPBleWorkState.PPBleStateSearchCanceled) {
//                scanStateStreamHandler?.sendState(0)
                //主动取消扫描无需对外告知
            } else if (ppBleWorkState == PPBleWorkState.PPBleWorkSearchTimeOut) {
                scanStateStreamHandler?.sendState(0)
            } else if (ppBleWorkState == PPBleWorkState.PPBleWorkStateSearching) {
                scanStateStreamHandler?.sendState(1)
            } else if (ppBleWorkState == PPBleWorkState.PPBleWorkStateWritable) {
                sendConnectState(1)
                registerDataChangeListener()
            } else if (ppBleWorkState == PPBleWorkState.PPBleWorkStateConnectFailed) {
                sendConnectState(2)
            } else if (ppBleWorkState == PPBleWorkState.PPBleWorkSearchFail) {
            }
        }

        override fun monitorBluetoothSwitchState(ppBleSwitchState: PPBleSwitchState?) {
            if (ppBleSwitchState == PPBleSwitchState.PPBleSwitchStateOff) {
                stopScan()
                disconnect()
                sendBlePermissionState(PPBluetoothState.POWERED_OFF)
            } else if (ppBleSwitchState == PPBleSwitchState.PPBleSwitchStateOn) {
                sendBlePermissionState(PPBluetoothState.POWERED_ON)
            }
        }

        override fun monitorMtuChange(deviceModel: PPDeviceModel?) {
            sendConnectState(1)
            registerDataChangeListener()
        }

    }

    fun addPrint(msg: String) {
        if (msg.isNotEmpty()) {
            Logger.d(msg)
        }
    }

    fun registerDataChangeListener() {

        val currentDevice = deviceControl?.deviceModel

        when (currentDevice?.getDevicePeripheralType()) {
            PPDevicePeripheralType.PeripheralFish -> {
                Logger.i("fishControl registDataChangeListener")
                fishControl?.registDataChangeListener(foodScaleDataChangeListener)
            }

            PPDevicePeripheralType.PeripheralEgg -> {
                Logger.i("eggControl registDataChangeListener")
                eggControl?.registDataChangeListener(foodScaleDataChangeListener)
            }

            PPDevicePeripheralType.PeripheralJambul -> {
                Logger.i("jambulControl registDataChangeListener")
                jambulControl?.registDataChangeListener(dataChangeListener)
            }

            PPDevicePeripheralType.PeripheralGrapes -> {
                Logger.i("grapesControl registDataChangeListener")
                grapesControl?.registDataChangeListener(foodScaleDataChangeListener)
            }

            PPDevicePeripheralType.PeripheralHamburger -> {
                Logger.i("hamburgerControl registDataChangeListener")
                hamburgerControl?.registDataChangeListener(foodScaleDataChangeListener)
            }

            PPDevicePeripheralType.PeripheralBanana -> {
                Logger.i("bananaControl registDataChangeListener")
                bananaControl?.registDataChangeListener(dataChangeListener)
            }

            PPDevicePeripheralType.PeripheralDurian -> {
                Logger.i("durianControl registDataChangeListener")
                durianControl?.registDataChangeListener(dataChangeListener)
            }

            PPDevicePeripheralType.PeripheralCoconut -> {
                Logger.i("coconutControl registDataChangeListener")
                coconutControl?.registDataChangeListener(dataChangeListener)
            }

            PPDevicePeripheralType.PeripheralApple -> {
                Logger.i("appleControl registDataChangeListener")
                appleControl?.registDataChangeListener(dataChangeListener)
            }

            PPDevicePeripheralType.PeripheralIce -> {
                Logger.i("iceControl registDataChangeListener")
                iceControl?.registDataChangeListener(dataChangeListener)
            }

            PPDevicePeripheralType.PeripheralTorre -> {
                Logger.i("torreControl registDataChangeListener")
                torreControl?.getTorreDeviceManager()?.registDataChangeListener(dataChangeListener)


            }

            PPDevicePeripheralType.PeripheralBorre -> {
                Logger.i("borreControl registDataChangeListener")
                borreControl?.getTorreDeviceManager()?.registDataChangeListener(dataChangeListener)

                borreControl?.getTorreDeviceManager()?.registerLightIntensityListener { lightIntensity ->

                    currentLightStrength = lightIntensity
                }
            }

            PPDevicePeripheralType.PeripheralDorre -> {
                Logger.i("dorreControl registDataChangeListener")
                dorreControl?.getTorreDeviceManager()?.registDataChangeListener(dataChangeListener)
            }

            PPDevicePeripheralType.PeripheralForre -> {
                Logger.i("forreControl registDataChangeListener")
                forreControl?.getTorreDeviceManager()?.registDataChangeListener(dataChangeListener)
            }

            else -> {

            }
        }


    }


    val searchDeviceInfoInterface = object : PPSearchDeviceInfoInterface {
        override fun onSearchDevice(deviceModel: PPDeviceModel?, data: String?) {
            if (deviceModel == null) {
                return
            }
            Logger.d("桥接层扫描到设备:${deviceModel?.deviceName} mac:${deviceModel?.deviceMac} ${deviceModel?.getDevicePeripheralType()}")
            tempDeviceDict.put(deviceModel.deviceMac, deviceModel)
            val deviceDict = convertDeviceDict(deviceModel)
            scanResultStreamHandler?.sendEvent(deviceDict)

            if (currentDevice != null && currentDevice?.deviceMac == deviceModel.deviceMac) {
                //广播秤的数据从这里解析
                receivedData(deviceModel, data)
            }

        }

    }


    /**
     * 直接处理数据
     */
    fun receivedData(deviceModel: PPDeviceModel?, data: String?) {
        when (deviceModel?.getDevicePeripheralType()) {
            PPDevicePeripheralType.PeripheralBanana -> {
                bananaControl?.deviceModel = deviceModel
                bananaControl?.onSearchResponse(data)
            }

            PPDevicePeripheralType.PeripheralJambul -> {
                jambulControl?.deviceModel = deviceModel
                jambulControl?.onSearchResponse(data)
            }

            PPDevicePeripheralType.PeripheralHamburger -> {
                hamburgerControl?.deviceModel = deviceModel
                hamburgerControl?.onSearchResponse(data)
            }

            PPDevicePeripheralType.PeripheralGrapes -> {
                grapesControl?.deviceModel = deviceModel
                grapesControl?.onSearchResponse(data)
            }

            else -> {
                currentDevice = null
            }
        }
    }


    var historyDataInterface = object : PPHistoryDataInterface() {
        override fun monitorHistoryData(bodyBaseModel: PPBodyBaseModel?, dateTime: String?) {
            addPrint("monitorHistoryData weight: ${bodyBaseModel?.weight}" + " dateTime:$dateTime")
            bodyBaseModel?.let {
                if (tempScaleHistoryList == null) {
                    tempScaleHistoryList = mutableListOf()
                }
                tempScaleHistoryList?.add(it)
                addPrint("monitorHistoryEnd")

            }
        }

        override fun monitorHistoryEnd(deviceModel: PPDeviceModel?) {
            addPrint("monitorHistoryEnd")
            val list = tempScaleHistoryList ?: mutableListOf()
            sendHistoryData(list)
            tempScaleHistoryList = null
        }

        override fun monitorHistoryFail() {
            addPrint("monitorHistoryFail")
            val list = tempScaleHistoryList ?: mutableListOf()
            sendHistoryData(list)
            tempScaleHistoryList = null
        }
    }

    var deviceInfoInterface = object : PPDeviceInfoInterface() {

        override fun readDevicePower(power: Int, state: Int) {
            batteryStreamHandler?.sendEvent(mapOf("power" to power, "type" to state))
        }

        override fun onLightIntensityChange(intensity: Int) {

            currentLightStrength = intensity
        }

    }

    var torreDeviceModeChangeInterface = object : PPTorreDeviceModeChangeInterface {

        override fun readDevicePower(power: Int) {
            batteryStreamHandler?.sendEvent(mapOf("power" to power, "type" to 0))
        }

    }

    var deviceSetInfoInterface = object : PPDeviceSetInfoInterface {

        override fun monitorResetStateFail() {

        }

        override fun monitorResetStateSuccess() {

        }


    }


    var onDFUStateListener: OnDFUStateListener = object : OnDFUStateListener {
        override fun onDfuProgress(progress: Int) {
            dfuStreamHandler?.sendEvent(mapOf("progress" to progress.toFloat() / 100.0, "isSuccess" to false, "code" to 0))
        }

        override fun onDfuFail(errorType: String?) {
            dfuStreamHandler?.sendEvent(mapOf("progress" to -1, "isSuccess" to false, "code" to 2))
        }

        override fun onDfuStart() {
            dfuStreamHandler?.sendEvent(mapOf("progress" to 0, "isSuccess" to false, "code" to 0))
        }

        override fun onDfuSucess() {
            dfuStreamHandler?.sendEvent(mapOf("progress" to 100.toFloat() / 100.0, "isSuccess" to true, "code" to 1))
        }

        override fun onStartSendDfuData() {

        }

    }


    var deviceLogInterface = object : PPDeviceLogInterface {

        override fun syncLogStart() {
            deviceLogStreamHandler?.sendEvent(mapOf("progress" to 0.0, "isFailed" to false))
        }

        override fun syncLoging(progress: Int) {
            deviceLogStreamHandler?.sendEvent(mapOf("progress" to progress / 100.0, "isFailed" to false))
        }

        override fun syncLogEnd(filePath: String?) {
            deviceLogStreamHandler?.sendEvent(mapOf("progress" to 1.0, "filePath" to filePath, "isFailed" to false))
        }

    }

    var foodScaleDataChangeListener = object : FoodScaleDataChangeListener() {

        override fun processData(foodScaleGeneral: LFFoodScaleGeneral, deviceModel: PPDeviceModel?) {
            if (foodScaleGeneral == null) {
                return
            }
            if (deviceModel == null) {
                return
            }
            val measureMentDataDict = convertMeasurementDictFood(foodScaleGeneral, deviceModel)
            //0:过程数据，10:测量完成（获取阻抗、心率等数据进行身体数据计算）
            var measurementState = 0
            kitchenStreamHandler?.sendEvent(
                mapOf(
                    "measurementState" to measurementState,
                    "device" to convertDeviceDict(deviceModel),
                    "data" to measureMentDataDict
                )
            )
        }

        override fun lockedData(foodScaleGeneral: LFFoodScaleGeneral, deviceModel: PPDeviceModel?) {
            if (foodScaleGeneral == null) {
                return
            }
            if (deviceModel == null) {
                return
            }
            val measureMentDataDict = convertMeasurementDictFood(foodScaleGeneral, deviceModel)
            var measurementState = 10
            kitchenStreamHandler?.sendEvent(
                mapOf(
                    "measurementState" to measurementState,
                    "device" to convertDeviceDict(deviceModel),
                    "data" to measureMentDataDict
                )
            )
        }

    }
    var dataChangeListener = object : PPDataChangeListener {
        override fun monitorDataFail(bodyBaseModel: PPBodyBaseModel?, deviceModel: PPDeviceModel?) {

        }

        /**
         * 设备状态监听/Device status monitoring
         */
        override fun monitorScaleState(scaleState: PPScaleState?) {
            //中文：https://xinzhiyun.feishu.cn/docx/MyOldJy8woXBKZxpvw8c3huLnjf?from=from_copylink
            //English:https://xinzhiyun.feishu.cn/docx/Llu6dwLe6oghduxfsGZco8bInEe?from=from_copylink

        }


        /**
         * 监听过程数据
         *
         * @param bodyBaseModel
         * @param deviceModel
         */
        override fun monitorProcessData(bodyBaseModel: PPBodyBaseModel?, deviceModel: PPDeviceModel?) {
            if (bodyBaseModel == null) {
                return
            }
            if (deviceModel == null) {
                return
            }

            bodyBaseModel.heartRate = 0

            val measureMentDataDict = convertMeasurementDict(bodyBaseModel).toMutableMap()
            // 添加光照强度
            if (currentLightStrength != null) {
                measureMentDataDict["hasLightStrength"] = true
                measureMentDataDict["lightStrength"] = currentLightStrength!!
            } else {
                measureMentDataDict["hasLightStrength"] = false
            }
            //0:过程数据，1:体脂测量中（部分设备无此状态），2:心率测量中，10:测量完成（获取阻抗、心率等数据进行身体数据计算）
            var measurementState = 0
            if (bodyBaseModel.scaleState.impedanceType == PPScaleStateImpedanceType.PP_SCALE_STATE_IMPEDANCE_MEASURING) {
                measurementState = 1
            } else if (bodyBaseModel.scaleState.heartRateType == PPScaleStateHeartRateType.PP_SCALE_STATE_HEARTRATE_MEASURING) {
                measurementState = 2
            } else {
                measurementState = 0
            }
            measureStreamHandler?.sendEvent(
                mapOf(
                    "measurementState" to measurementState,
                    "device" to convertDeviceDict(deviceModel),
                    "data" to measureMentDataDict
                )
            )
        }

        /**
         * 0:过程数据，1:体脂测量中（部分设备无此状态），2:心率测量中，10:测量完成（获取阻抗、心率等数据进行身体数据计算）
         *
         * @param bodyBaseModel
         */
        override fun monitorLockData(bodyBaseModel: PPBodyBaseModel?, deviceModel: PPDeviceModel?) {
            if (bodyBaseModel == null) {
                return
            }
            if (deviceModel == null) {
                return
            }
            val measureMentDataDict = convertMeasurementDict(bodyBaseModel).toMutableMap()
            // 添加光照强度
            if (currentLightStrength != null) {
                measureMentDataDict["hasLightStrength"] = true
                measureMentDataDict["lightStrength"] = currentLightStrength!!
            } else {
                measureMentDataDict["hasLightStrength"] = false
            }

               if(bodyBaseModel.imErrorType != ImpedanceErrorType.PP_ERROR_TYPE_NONE){
                measureMentDataDict["imErrorType"] = bodyBaseModel.imErrorType.getType()
            }
            if (bodyBaseModel.isHeartRating ?: false) {
                //isHeartRating： 心率是否测量中  true心率测量中/重量测量完成/阻抗测量完成  false心率测量结束/测量完成
                measureStreamHandler?.sendEvent(
                    mapOf(
                        "measurementState" to 2,
                        "device" to convertDeviceDict(deviceModel),
                        "data" to measureMentDataDict
                    )
                )
            } else {
                measureStreamHandler?.sendEvent(
                    mapOf(
                        "measurementState" to 10,
                        "device" to convertDeviceDict(deviceModel),
                        "data" to measureMentDataDict
                    )
                )
            }


        }
    }

}