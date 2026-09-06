package com.example.pp_bluetooth_kit_flutter

import android.content.Context
import com.lefu.ppbase.PPSDKKit
import com.lefu.ppbase.util.Logger
import com.lefu.ppbase.util.OnLogCallBack
import com.peng.ppscale.PPBluetoothKit

fun PpBluetoothKitFlutterPlugin.initSDK(context: Context, appKey: String, appSecret: String, encryptStr: String) {
    /**
     * SDK日志打印
     * SDK日志写入文件，App内日志管理可控
     */
    PPSDKKit.setDebugLogCallBack(object : OnLogCallBack() {
        override fun logd(s: String?, s1: String?) {
            s1?.let { bleManager.loggerStreamHandler?.sendEvent(it) }
        }

        override fun logi(s: String?, s1: String?) {
            s1?.let { bleManager.loggerStreamHandler?.sendEvent(it) }

        }

        override fun logv(s: String?, s1: String?) {
            s1?.let { bleManager.loggerStreamHandler?.sendEvent(it) }
        }

        override fun logw(s: String?, s1: String?) {
            s1?.let { bleManager.loggerStreamHandler?.sendEvent(it) }
        }

        override fun loge(s: String?, s1: String?) {
            s1?.let { bleManager.loggerStreamHandler?.sendEvent(it) }
        }
    })

    /*********************以下内容为SDK的配置项***************************************/
    /**
     *  SDK日志打印控制，true会打印
     */
    PPBluetoothKit.setDebug(true)


    /**
     * PPBluetoothKit 蓝牙库初始化 所需参数需要自行到开放平台自行申请，请勿直接使用Demo中的参数，
     * Demo中的参数仅供Demo使用
     * @param appKey App的标识
     * @param appSecret Appp的密钥
     * @param configPath 在开放平台下载相应的配置文件以.config结尾，并放到assets目录下，将config文件全名传给SDK
     */
    Logger.i("PpBluetoothKitFlutterPlugin initSDK setNetConfig")
    Logger.i("appkey: $appKey appSecret: $appSecret")
    // 按照每500字符分段打印encryptStr
    fun printLongString(tag: String, text: String) {
        val chunkSize = 500
        if (text.length <= chunkSize) {
            Logger.i("$tag: $text")
        } else {
            for (i in text.indices step chunkSize) {
                val end = minOf(i + chunkSize, text.length)
                val chunk = text.substring(i, end)
                val partNumber = (i / chunkSize) + 1
                Logger.i("$tag-part$partNumber: $chunk")
            }
        }
    }
    
    printLongString("encryptStr", encryptStr)

    PPBluetoothKit.setNetConfig(context, appKey, appSecret, encryptStr)


}


fun PpBluetoothKitFlutterPlugin.setDeviceSetting(context: Context, encryptStr: String) {
    /**
     * SDK日志打印
     * SDK日志写入文件，App内日志管理可控
     */
    PPSDKKit.setDebugLogCallBack(object : OnLogCallBack() {
        override fun logd(s: String?, s1: String?) {
            s1?.let { bleManager.loggerStreamHandler?.sendEvent(it) }
        }

        override fun logi(s: String?, s1: String?) {
            s1?.let { bleManager.loggerStreamHandler?.sendEvent(it) }

        }

        override fun logv(s: String?, s1: String?) {
            s1?.let { bleManager.loggerStreamHandler?.sendEvent(it) }
        }

        override fun logw(s: String?, s1: String?) {
            s1?.let { bleManager.loggerStreamHandler?.sendEvent(it) }
        }

        override fun loge(s: String?, s1: String?) {
            s1?.let { bleManager.loggerStreamHandler?.sendEvent(it) }
        }
    })


    /*********************以下内容为SDK的配置项***************************************/
    /**
     *  SDK日志打印控制，true会打印
     */
    PPBluetoothKit.setDebug(true)
    /**
     * PPBluetoothKit 蓝牙库初始化 所需参数需要自行到开放平台自行申请，请勿直接使用Demo中的参数，
     * Demo中的参数仅供Demo使用
     * @param appKey App的标识
     * @param appSecret Appp的密钥
     * @param configPath 在开放平台下载相应的配置文件以.config结尾，并放到assets目录下，将config文件全名传给SDK
     */
    PPBluetoothKit.setDeviceConfigJsonStr(context, encryptStr)


}