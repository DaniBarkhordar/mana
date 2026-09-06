package com.example.pp_bluetooth_kit_flutter

import android.content.Context
import androidx.annotation.NonNull
import com.example.pp_bluetooth_kit_flutter.extension.clearDeviceData
import com.example.pp_bluetooth_kit_flutter.extension.configWifi
import com.example.pp_bluetooth_kit_flutter.extension.deleteFingerprint
import com.example.pp_bluetooth_kit_flutter.extension.deleteUser
import com.example.pp_bluetooth_kit_flutter.extension.exitBabyModel
import com.example.pp_bluetooth_kit_flutter.extension.exitNetworkConfig
import com.example.pp_bluetooth_kit_flutter.extension.exitScanWifiNetworks
import com.example.pp_bluetooth_kit_flutter.extension.fetchBindingState
import com.example.pp_bluetooth_kit_flutter.extension.fetchDeviceInfo
import com.example.pp_bluetooth_kit_flutter.extension.fetchDeviceLanguage
import com.example.pp_bluetooth_kit_flutter.extension.fetchFingerprintList
import com.example.pp_bluetooth_kit_flutter.extension.fetchHeartRateSwitch
import com.example.pp_bluetooth_kit_flutter.extension.fetchImpedanceSwitch
import com.example.pp_bluetooth_kit_flutter.extension.fetchUserIDList
import com.example.pp_bluetooth_kit_flutter.extension.fetchWifiInfo
import com.example.pp_bluetooth_kit_flutter.extension.fetchWifiMac
import com.example.pp_bluetooth_kit_flutter.extension.getDisplayMetrics
import com.example.pp_bluetooth_kit_flutter.extension.getScreenBrightness
import com.example.pp_bluetooth_kit_flutter.extension.heartRateSwitchControl
import com.example.pp_bluetooth_kit_flutter.extension.impedanceSwitchControl
import com.example.pp_bluetooth_kit_flutter.extension.keepAlive
import com.example.pp_bluetooth_kit_flutter.extension.registerFingerprint
import com.example.pp_bluetooth_kit_flutter.extension.scanWifiNetworks
import com.example.pp_bluetooth_kit_flutter.extension.selectUser
import com.example.pp_bluetooth_kit_flutter.extension.sendCommonState
import com.example.pp_bluetooth_kit_flutter.extension.setBindingState
import com.example.pp_bluetooth_kit_flutter.extension.setDeviceLanguage
import com.example.pp_bluetooth_kit_flutter.extension.setDisplayBodyFat
import com.example.pp_bluetooth_kit_flutter.extension.setDisplayMetrics
import com.example.pp_bluetooth_kit_flutter.extension.setRGBMode
import com.example.pp_bluetooth_kit_flutter.extension.setScreenBrightness
import com.example.pp_bluetooth_kit_flutter.extension.startBabyModel
import com.example.pp_bluetooth_kit_flutter.extension.startDFU
import com.example.pp_bluetooth_kit_flutter.extension.startMeasure
import com.example.pp_bluetooth_kit_flutter.extension.stopMeasure
import com.example.pp_bluetooth_kit_flutter.extension.syncDeviceLog
import com.example.pp_bluetooth_kit_flutter.extension.syncLast7Data
import com.example.pp_bluetooth_kit_flutter.extension.syncTime
import com.example.pp_bluetooth_kit_flutter.extension.syncUnit
import com.example.pp_bluetooth_kit_flutter.extension.syncUserInfo
import com.example.pp_bluetooth_kit_flutter.extension.syncUserList
import com.example.pp_bluetooth_kit_flutter.extension.wifiOTA
import com.lefu.ppbase.util.Logger
import com.lefu.ppbase.vo.PPUserGender
import com.lefu.ppbase.vo.PPUserModel
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result


/** PpBluetoothKitFlutterPlugin */
class PpBluetoothKitFlutterPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel: MethodChannel
  private lateinit var bleChannel: MethodChannel
  private lateinit var context: Context
  lateinit var bleManager: PPLefuBleConnectManager

  companion object {
    @Volatile private var initialized = false
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {

    if (initialized) {
      // 可加调试日志：重复引擎或重复注册场景
      Logger.e("PpBluetoothKitFlutterPlugin has been initialized already.")
      return
    }
    initialized = true

    context = flutterPluginBinding.applicationContext
    bleManager = PPLefuBleConnectManager.getInstance(context)

    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "pp_bluetooth_kit_flutter")
    channel.setMethodCallHandler(this)

    bleChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "pp_ble_channel")
    bleChannel.setMethodCallHandler(this)

    // 设置测量数据流
    val measureStreamHandler = PPLefuStreamHandler()
    bleManager.measureStreamHandler = measureStreamHandler
    val measureEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "pp_measurement_streams")
    measureEventChannel.setStreamHandler(measureStreamHandler)

    // 设置日志流
    val loggerStreamHandler = PPLefuStreamHandler()
    bleManager.loggerStreamHandler = loggerStreamHandler
    val loggerEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "pp_logger_streams")
    loggerEventChannel.setStreamHandler(loggerStreamHandler)

    // 设置连接状态流
    val connectStateStreamHandler = PPLefuStreamHandler()
    bleManager.connectStateStreamHandler = connectStateStreamHandler
    val connectStateEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "pp_connect_state_streams")
    connectStateEventChannel.setStreamHandler(connectStateStreamHandler)

    // 设置扫描结果流
    val scanResultStreamHandler = PPLefuStreamHandler()
    bleManager.scanResultStreamHandler = scanResultStreamHandler
    val scanEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "pp_device_list_streams")
    scanEventChannel.setStreamHandler(scanResultStreamHandler)

    // 设置历史数据流
    val historyStreamHandler = PPLefuStreamHandler()
    bleManager.historyStreamHandler = historyStreamHandler
    val historyEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "pp_history_data_streams")
    historyEventChannel.setStreamHandler(historyStreamHandler)

    // 设置电池信息流
    val batteryStreamHandler = PPLefuStreamHandler()
    bleManager.batteryStreamHandler = batteryStreamHandler
    val batteryEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "pp_battery_streams")
    batteryEventChannel.setStreamHandler(batteryStreamHandler)

    // 设置蓝牙权限流
    val blePermissionStreamHandler = PPLefuStreamHandler()
    bleManager.blePermissionStreamHandler = blePermissionStreamHandler
    val blePermissionEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "pp_ble_permission_streams")
    blePermissionEventChannel.setStreamHandler(blePermissionStreamHandler)

    // 设置DFU流
    val dfuStreamHandler = PPLefuStreamHandler()
    bleManager.dfuStreamHandler = dfuStreamHandler
    val dfuEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "pp_dfu_streams")
    dfuEventChannel.setStreamHandler(dfuStreamHandler)

    // 设置设备日志流
    val deviceLogStreamHandler = PPLefuStreamHandler()
    bleManager.deviceLogStreamHandler = deviceLogStreamHandler
    val deviceLogEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "device_log_streams")
    deviceLogEventChannel.setStreamHandler(deviceLogStreamHandler)

    // 设置扫描状态流
    val scanStateStreamHandler = PPLefuStreamHandler()
    bleManager.scanStateStreamHandler = scanStateStreamHandler
    val scanStateEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "pp_scan_state_streams")
    scanStateEventChannel.setStreamHandler(scanStateStreamHandler)

    // 设置厨房秤流
    val kitchenStreamHandler = PPLefuStreamHandler()
    bleManager.kitchenStreamHandler = kitchenStreamHandler
    val kitchenEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "pp_kitchen_streams")
    kitchenEventChannel.setStreamHandler(kitchenStreamHandler)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    val method = call.method
    val params = call.arguments as? Map<String, Any?>
    Logger.e("method: $method")
    when (method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "initSDK" -> {
        val appKey = params?.get("appKey") as? String
        val appSecret = params?.get("appSecret") as? String
        val deviceContent = params?.get("deviceContent") as? String

        if (appKey == null) {
          bleManager.loggerStreamHandler?.sendEvent("appKey为空")
          return
        }
        if (appSecret == null) {
          bleManager.loggerStreamHandler?.sendEvent("appSecret为空")
          return
        }
        if (deviceContent == null) {
          bleManager.loggerStreamHandler?.sendEvent("deviceContent为空")
          return
        }

        // 初始化SDK
        initSDK(context, appKey, appSecret,  deviceContent)
        bleManager.initSDK()

      }
      "setDeviceSetting" -> {
        val deviceContent = params?.get("deviceContent") as? String

        if (deviceContent == null) {
          bleManager.loggerStreamHandler?.sendEvent("deviceContent为空")
          return
        }
        try {
          setDeviceSetting(context, deviceContent)
          bleManager.sendCommonState(true, result)

        } catch (e: Exception) {
          bleManager.loggerStreamHandler?.sendEvent("设备列表-转JSON异常: ${e.message}")
          bleManager.sendCommonState(false, result)
        }
        bleManager.initSDK()
      }
      "startScan" -> {
        val deviceMac = params?.get("deviceMac") as? String
        bleManager.startScan(deviceMac, result)
      }
      "stopScan" -> {
        bleManager.stopScan()
        Logger.e("method: Android 桥阶层不支持外部停止扫描")
        bleManager.sendCommonState(true, result)
      }
      "connectDevice" -> {
        val deviceMac = params?.get("deviceMac") as? String
        val deviceName = params?.get("deviceName") as? String

        if (deviceMac == null) {
          bleManager.loggerStreamHandler?.sendEvent("deviceMac为空")
          return
        }
        if (deviceName == null) {
          bleManager.loggerStreamHandler?.sendEvent("deviceName为空")
          return
        }

        bleManager.connectDevice(deviceMac, deviceName)
      }
      "disconnect" -> {
        bleManager.disconnect()
        result.success(emptyMap<String, Any>())
      }
      "fetchHistory" -> {
        val userID = params?.get("userID") as? String ?: ""
        val memberID = params?.get("memberID") as? String ?: ""

        val model = PPUserModel.Builder()
          .setUserID(userID)
          .setMemberId(memberID)
          .build()

        bleManager.fetchHistory(model, result)
      }
      "deleteHistory" -> {
        bleManager.deleteHistory(result)
      }

      "syncUnit" -> {
        val unit = params?.get("unit") as? Int
        val sex = params?.get("sex") as? Int
        val age = params?.get("age") as? Int
        val height = params?.get("height") as? Int
        val isPregnantMode = params?.get("isPregnantMode") as? Boolean
        val isAthleteMode = params?.get("isAthleteMode") as? Boolean

        if (unit == null) {
          bleManager.loggerStreamHandler?.sendEvent("unit为空")
          return
        }

        val model = PPUserModel.Builder()
          .setAge(age ?: 0)
          .setHeight(height ?: 0)
          .setSex(if (sex == 0) PPUserGender.PPUserGenderFemale else PPUserGender.PPUserGenderMale)
          .setAthleteMode(isAthleteMode ?: false)
          .setPregnantMode(isPregnantMode ?: false)
          .build()

        bleManager.syncUnit(unit, model, result)
      }
      "syncTime" -> {
        val is24Hour = params?.get("is24Hour") as? Boolean ?: true
        bleManager.syncTime(is24Hour, result)
      }
      "configWifi" -> {
        val domain = params?.get("domain") as? String
        val ssId = params?.get("ssId") as? String
        val password = params?.get("password") as? String ?: ""

        if (domain == null) {
          result.success(mapOf("success" to false, "errorCode" to -1))
          return
        }

        if (ssId == null) {
          result.success(mapOf("success" to false, "errorCode" to -1))
          return
        }

        bleManager.configWifi(domain, ssId, password, result)
      }
      "fetchWifiInfo" -> {
        bleManager.fetchWifiInfo(result)
      }
      "fetchDeviceInfo" -> {
        bleManager.fetchDeviceInfo(result)
      }
      "fetchBatteryInfo" -> {
        bleManager.fetchBatteryInfo(result)
      }
      "resetDevice" -> {
        bleManager.resetDevice(result)
      }
      "fetchConnectedDevice" -> {
        bleManager.fetchConnectedDevice(result)
      }
      "addBlePermissionListener" -> {
        bleManager.addBlePermissionListener()
        result.success(emptyMap<String, Any>())
      }
      "fetchWifiMac" -> {
        bleManager.fetchWifiMac(result)
      }
      "scanWifiNetworks" -> {
        bleManager.scanWifiNetworks(result)
      }
      "wifiOTA" -> {
        bleManager.wifiOTA(result)
      }

      "androidOpenBooth" -> {
        bleManager.gotoPermissionSetting()
      }
      "heartRateSwitchControl" -> {
        val open = params?.get("open") as? Boolean ?: false
        bleManager.heartRateSwitchControl(open, result)
      }
      "fetchHeartRateSwitch" -> {
        bleManager.fetchHeartRateSwitch(result)
      }
      "impedanceSwitchControl" -> {
        val open = params?.get("open") as? Boolean ?: false
        bleManager.impedanceSwitchControl(open, result)
      }
      "fetchImpedanceSwitch" -> {
        bleManager.fetchImpedanceSwitch(result)
      }
      "setBindingState" -> {
        val binding = params?.get("binding") as? Boolean ?: false
        bleManager.setBindingState(binding, result)
      }
      "fetchBindingState" -> {
        bleManager.fetchBindingState(result)
      }
      "setScreenBrightness" -> {
        val brightness = params?.get("brightness") as? Int ?: 50
        bleManager.setScreenBrightness(brightness, result)
      }
      "getScreenBrightness" -> {
        bleManager.getScreenBrightness(result)
      }
      "syncUserInfo" -> {
        val model = getUserInfo(params)
        if (model != null) {
          bleManager.syncUserInfo(model, result)
        } else {
          bleManager.loggerStreamHandler?.sendEvent("用户信息参数不完整")
        }
      }
      "syncUserList" -> {
        val userList = params?.get("userList") as? List<Map<String, Any?>>

        if (userList == null) {
          bleManager.loggerStreamHandler?.sendEvent("用户列表为空")
          return
        }

        val userArray = ArrayList<PPUserModel>()

        for (item in userList) {
          val model = getUserInfo(item)
          if (model != null) {
            userArray.add(model)
          }
        }

        bleManager.loggerStreamHandler?.sendEvent("下发用户数量:${userArray.size}")
        bleManager.syncUserList(userArray, result)
      }
      "fetchUserIDList" -> {
        bleManager.fetchUserIDList(result)
      }
      "selectUser" -> {
        val userID = params?.get("userID") as? String ?: ""
        val memberID = params?.get("memberID") as? String ?: ""

        val user = PPUserModel.Builder()
          .setUserID(userID)
          .setMemberId(memberID)
          .build()

        bleManager.selectUser(user, result)
      }
      "deleteUser" -> {
        val userID = params?.get("userID") as? String ?: ""
        val memberID = params?.get("memberID") as? String ?: ""

        val user = PPUserModel.Builder()
          .setUserID(userID)
          .setMemberId(memberID)
          .build()


        bleManager.deleteUser(user, result)
      }
      "startMeasure" -> {
        bleManager.startMeasure(result)
      }
      "stopMeasure" -> {
        bleManager.stopMeasure(result)
      }
      "startBabyModel" -> {
        val step = params?.get("step") as? Int ?: 0
        val weight = params?.get("weight") as? Double ?: 0.0

        bleManager.startBabyModel(step, weight, result)
      }
      "exitBabyModel" -> {
        bleManager.exitBabyModel(result)
      }
      "startDFU" -> {
        val filePath = params?.get("filePath") as? String ?: ""
        val deviceFirmwareVersion = params?.get("deviceFirmwareVersion") as? String ?: ""
        val isForceCompleteUpdate = params?.get("isForceCompleteUpdate") as? Boolean ?: false

        bleManager.startDFU(filePath, deviceFirmwareVersion, isForceCompleteUpdate, result)
      }
      "syncDeviceLog" -> {
        val logFolder = params?.get("logFolder") as? String ?: ""
        bleManager.syncDeviceLog(logFolder, result)
      }
      "keepAlive" -> {
        bleManager.keepAlive()
        result.success(emptyMap<String, Any>())
      }
      "clearDeviceData" -> {
        val type = params?.get("type") as? Int ?: 0
        bleManager.clearDeviceData(type, result)
      }
      "setDeviceLanguage" -> {
        val type = params?.get("type") as? Int ?: 0
        bleManager.setDeviceLanguage(type, result)
      }
      "fetcgDeviceLanguage" -> {
        bleManager.fetchDeviceLanguage(result)
      }
      "setDisplayBodyFat" -> {
        val bodyFat = params?.get("bodyFat") as? Int ?: 0
        bleManager.setDisplayBodyFat(bodyFat, result)
      }
      "exitScanWifiNetworks" -> {
        bleManager.exitScanWifiNetworks(result)
      }
      "exitNetworkConfig" -> {
        bleManager.exitNetworkConfig(result)
      }
      "receiveBroadcastData" -> {
        val deviceMac = params?.get("deviceMac") as? String

        if (deviceMac == null) {
          bleManager.loggerStreamHandler?.sendEvent("deviceMac为空")
          bleManager.sendCommonState(false, result)
          return
        }

        bleManager.receiveBroadcastData(deviceMac, result)
      }
      "unReceiveBroadcastData" -> {
        val deviceMac = params?.get("deviceMac") as? String

        if (deviceMac == null) {
          bleManager.loggerStreamHandler?.sendEvent("deviceMac为空")
          bleManager.sendCommonState(false, result)
          return
        }

        bleManager.unReceiveBroadcastData(deviceMac, result)
      }
      "setRGBMode" -> {

        val defalutColor = params?.get("defalutColor") as? String ?: ""
        val gainColor = params?.get("gainColor") as? String ?: ""
        val lossColor = params?.get("lossColor") as? String ?: ""
        val lightEnable = params?.get("lightEnable") as? Int ?: 0
        val lightMode = params?.get("lightMode") as? Int ?: 0


        bleManager.setRGBMode(lightEnable,lightMode,defalutColor,gainColor,lossColor,result)

      }
      "sendBroadcastData" -> {
        val cmd = params?.get("cmd") as? String
        val unit = params?.get("unit") as? Int ?: 0

        if (cmd == null) {
          bleManager.loggerStreamHandler?.sendEvent("cmd为空")
          bleManager.sendCommonState(false, result)
          return
        }

        bleManager.sendBroadcastData(cmd, unit, result)
      }
      "toZero" -> {
        bleManager.toZero(result)
      }

      "changeBuzzerGate" -> {
        val open = params?.get("open") as? Boolean ?: true

        bleManager.changeBuzzerGate(open,result)
      }

      "foodScaleUnit" -> {


        val weightG = params?.get("weightG") as? Double ?: 0
        val accuracyType = params?.get("accuracyType") as? Int ?: 0
        val unitType = params?.get("unitType") as? Int ?: 4

        bleManager.foodScaleUnit(weightG,accuracyType,unitType,result)


      }

      "fetchFingerprintList" -> {
        bleManager.fetchFingerprintList(result)

      }

      "registerFingerprint" -> {
          val userID = params?.get("userID") as? String ?: ""
          val memberID = params?.get("memberID") as? String ?: ""

        val user = PPUserModel.Builder().setUserID(userID).setMemberId(memberID).build()


        bleManager.registerFingerprint(user,result)
      }

      "deleteFingerprint" -> {
          val userID = params?.get("userID") as? String ?: ""
          val memberID = params?.get("memberID") as? String ?: ""

          val user = PPUserModel.Builder().setUserID(userID).setMemberId(memberID).build()


          bleManager.deleteFingerprint(user, result)
      }

      "setDisplayMetrics" -> {
        val metrics = params?.get("metrics") as? Int ?: 0
        bleManager.setDisplayMetrics(metrics,result)
      }

      "getDisplayMetrics" -> {
        // TODO: Implement bleManager.getDisplayMetrics(result)
        bleManager.getDisplayMetrics(result)
      }

      "fetchUserInfoList" -> {
        // TODO: Implement bleManager.fetchUserInfoList(result)
        result.notImplemented()
      }

      "syncBorreCLast7Data" -> {
        val list = params?.get("weightList") as? List<Map<String, Any>> ?: listOf()

        // 创建历史数据列表
        val historyList = ArrayList<Double>()
        val historyTimeList = ArrayList<Long>()

        // 处理历史数据
        for (item in list) {
          val weightKg = item.get("value") as? Double ?: 0.0
          val timeStamp = item.get("timeStamp") as? Long ?: 0

          historyList.add(weightKg)
          historyTimeList.add(timeStamp)
        }

        val typeValue = params?.get("type") as? Int ?: 0

        val builder = PPUserModel.Builder()
          .setUserID(params?.get("userID") as? String ?: "")
          .setMemberId(params?.get("memberID") as? String ?: "")
          .setTargetWeight(params?.get("targetWeight") as? Double ?: 0.0)
          .setIdeaWeight(params?.get("ideaWeight") as? Double ?: 0.0)
          .setBmi(params?.get("lastBMI") as? Double ?: 0.0)
          .setMuscleRate(params?.get("lastMuscleRate") as? Double ?: 0.0)
          .setWaterRate(params?.get("lastWaterRate") as? Double ?: 0.0)
          .setBodyfat(params?.get("lastBodyFat") as? Double ?: 0.0)
          .setHeartRate(params?.get("lastHeartRate") as? Int ?: 0)
          .setMuscle(params?.get("lastMuscle") as? Double ?: 0.0)
          .setBone(params?.get("lastBone") as? Double ?: 0.0)
          .setBoneRate(params?.get("lastBoneRate") as? Double ?: 0.0)

        // 设置体重数组和时间数组
        if (historyList.isNotEmpty()) {
          builder.setUserWeightArray(historyList.toDoubleArray())
          builder.setUserWeightTimeArray(historyTimeList.toLongArray())
        }

        // TODO: Implement bleManager.syncBorreCLast7Data(builder.build(), result)
        result.notImplemented()
      }



        "syncLast7Data" -> {
        val list = params?.get("weightList") as? List<Map<String, Any>> ?: listOf()

        // 创建历史数据列表
        val historyList = ArrayList<Double>()
        val historyTimeList = ArrayList<Long>()

        // 处理历史数据
        for (item in list) {
          val weightKg = item.get("value") as? Double ?: 0.0
          val timeStamp = item.get("timeStamp") as? Long ?: 0

          historyList.add(weightKg)
          historyTimeList.add(timeStamp)
        }

        val typeValue = params?.get("type") as? Int ?: 0

        val builder = PPUserModel.Builder()
          .setUserID(params?.get("userID") as? String ?: "")
          .setMemberId(params?.get("memberID") as? String ?: "")
          .setTargetWeight(params?.get("targetWeight") as? Double ?: 0.0)
          .setIdeaWeight(params?.get("ideaWeight") as? Double ?: 0.0)
          .setBmi(params?.get("lastBMI") as? Double ?: 0.0)
          .setMuscleRate(params?.get("lastMuscleRate") as? Double ?: 0.0)
          .setWaterRate(params?.get("lastWaterRate") as? Double ?: 0.0)
          .setBodyfat(params?.get("lastBodyFat") as? Double ?: 0.0)
          .setHeartRate(params?.get("lastHeartRate") as? Int ?: 0)
          .setMuscle(params?.get("lastMuscle") as? Double ?: 0.0)
          .setBone(params?.get("lastBone") as? Double ?: 0.0)
          .setBoneRate(params?.get("lastBoneRate") as? Double ?: 0.0)

        // 设置体重数组和时间数组
        if (historyList.isNotEmpty()) {
          builder.setUserWeightArray(historyList.toDoubleArray())
          builder.setUserWeightTimeArray(historyTimeList.toLongArray())
        }

//        val type = PPUserBodyDataType.values().getOrElse(typeValue) { PPUserBodyDataType.WEIGHT }
        bleManager.syncLast7Data(builder.build(), result)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  /**
   * 获取用户信息模型
   * 参考iOS版本实现的用户信息获取方法
   */
  private fun getUserInfo(params: Map<String, Any?>?): PPUserModel? {
    if (params == null) return null

    val userID = params["userID"] as? String ?: ""
    val memberID = params["memberID"] as? String ?: ""
    val isPregnantMode = params["isPregnantMode"] as? Boolean ?: false
    val isAthleteMode = params["isAthleteMode"] as? Boolean ?: false
    val unitType = params["unitType"] as? Int ?: 0
    val age = params["age"] as? Int ?: 0
    val sex = params["sex"] as? Int ?: 0
    val userHeight = params["userHeight"] as? Int ?: 0
    val userName = params["userName"] as? String ?: ""
    val deviceHeaderIndex = params["deviceHeaderIndex"] as? Int ?: 0
    val currentWeight = params["currentWeight"] as? Double ?: 0.0
    val targetWeight = params["targetWeight"] as? Double ?: 0.0
    val idealWeight = params["idealWeight"] as? Double ?: 0.0
    val recentData = params["recentData"] as? List<Map<String, Any?>> ?: listOf()
    val pIndex = params["pIndex"] as? Int ?: 0
    
    // 创建历史数据列表
    val historyList = ArrayList<Double>()
    val historyTimeList = ArrayList<Long>()
    
    // 处理历史数据
    for (item in recentData) {
      val weightKg = item["weightKg"] as? Double ?: 0.0
      val timeStamp = item["timeStamp"] as? Long ?: 0
      
      historyList.add(weightKg)
      historyTimeList.add(timeStamp)
    }
    
    // 构建用户模型
    val builder = PPUserModel.Builder()
      .setUserID(userID)
      .setMemberId(memberID)
      .setPregnantMode(isPregnantMode)
      .setAthleteMode(isAthleteMode)
      .setAge(age)
      .setSex(if (sex == 0) PPUserGender.PPUserGenderFemale else PPUserGender.PPUserGenderMale)
      .setHeight(userHeight)
      .setUserName(userName)
      .setDeviceHeaderIndex(deviceHeaderIndex)
      .setWeightKg(currentWeight)
      .setTargetWeight(targetWeight)
      .setIdeaWeight(idealWeight)
      .setPIndex(pIndex)
    
    // 设置体重数组和时间数组
    if (historyList.isNotEmpty()) {
      builder.setUserWeightArray(historyList.toDoubleArray())
      builder.setUserWeightTimeArray(historyTimeList.toLongArray())
    }
    
    return builder.build()
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    bleChannel.setMethodCallHandler(null)
  }
}
