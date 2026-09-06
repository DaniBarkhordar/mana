package com.example.pp_bluetooth_kit_flutter.util

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Context.LOCATION_SERVICE
import android.content.ContextWrapper
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.location.LocationManager
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.lefu.ppbase.util.Logger

object PermissionUtil {

    var strings = arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)

    @RequiresApi(Build.VERSION_CODES.S)
    var strings31BlePermission = arrayOf(Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT, Manifest.permission.BLUETOOTH_ADVERTISE)


    fun requestBluetoothPermission(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            for (permission in strings31BlePermission) {
                if (ContextCompat.checkSelfPermission(context, permission) !== PackageManager.PERMISSION_GRANTED) {
                    ActivityCompat.requestPermissions(
                        findActivity(context) as Activity,
                        arrayOf(permission),
                        0
                    )
                }
            }
        } else {
            for (permission in strings) {
                if (ContextCompat.checkSelfPermission(context, permission) !== PackageManager.PERMISSION_GRANTED) {
                    ActivityCompat.requestPermissions(
                        findActivity(context) as Activity,
                        arrayOf(permission),
                        0
                    )
                }
            }
        }
    }

    /**
     * 判断是否已经赋予权限
     *
     * @return
     */
    fun isHasBluetoothPermissions(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            for (permission in strings31BlePermission) {
                if (!(ContextCompat.checkSelfPermission(context, permission) === PackageManager.PERMISSION_GRANTED)) {
                    return false
                }
            }
        } else {
            for (permission in strings) {
                if (!(ContextCompat.checkSelfPermission(context, permission) === PackageManager.PERMISSION_GRANTED)) {
                    return false
                }
            }
        }
        return true
    }

    fun isLocationEnabled(context: Context): Boolean {
        val locationManager = context.getSystemService(LOCATION_SERVICE) as LocationManager
        return locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
    }

    /**
     * 判断当前手机是否为华为手机
     */
    fun isHuaweiOS(): Boolean {
        val osName = System.getProperty("os.name")
        val osVersion = System.getProperty("os.version")
        Logger.i("DeviceBrand isHuaweiOS osName: $osName, osVersion: $osVersion")

        val brand = getDeviceBrand()
        return if (brand.equals("Huawei", ignoreCase = true) || brand.equals(
                "Honor",
                ignoreCase = true
            )
        ) {
            true
        } else {
            false
        }
    }

    fun getDeviceBrand(): String {
        val manufacturer = Build.MANUFACTURER
        val model = Build.MODEL
        val brand = Build.BRAND
        Logger.i("DeviceBrand getDeviceBrand Manufacturer: $manufacturer, Model: $model, Brand: $brand") // 打印设备信息，用于调试
        return if (manufacturer.equals("unknown", ignoreCase = true)) {
            brand
        } else {
            manufacturer
        }
    }

    /**
     * 获取蓝牙权限状态
     */
    fun isPermissionPermanentlyDenied(activity: Context): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            for (permission in strings31BlePermission) {
                val permissionStatus = getPermissionStatus(activity, permission)
                if (permissionStatus == PermissionStatus.PERMANENTLY_DENIED) return true
            }
        } else {
            for (permission in strings) {
                val permissionStatus = getPermissionStatus(activity, permission)
                if (permissionStatus == PermissionStatus.PERMANENTLY_DENIED) return true
            }
        }
        return false
    }


    fun initSP(context: Context) {
        if (prefs == null) {
            prefs = context.getSharedPreferences("bluetooth_permission", Context.MODE_PRIVATE)
        }
    }

    var prefs: SharedPreferences? = null

    /**
     * 检查是否请求过权限
     */
    private fun isPermissionRequested(permission: String): Boolean {
        return prefs?.getBoolean("${permission}_requested", false) ?: false
    }

    /**
     * 检查单个权限状态
     */
    private fun getPermissionStatus(context: Context, permission: String): PermissionStatus {
        initSP(context)
        // 1. 检查是否已授权
        if (ContextCompat.checkSelfPermission(context, permission) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            return PermissionStatus.GRANTED
        }

        // 2. 检查是否请求过
        if (!isPermissionRequested(permission)) {
            return PermissionStatus.NOT_REQUESTED
        }

        val findActivity = findActivity(context)

        findActivity ?: return PermissionStatus.PERMANENTLY_DENIED

        // 3. 检查是否应该显示说明
        val shouldShowRationale =
            ActivityCompat.shouldShowRequestPermissionRationale(findActivity, permission)

        return if (shouldShowRationale) {
            PermissionStatus.DENIED
        } else {
            PermissionStatus.PERMANENTLY_DENIED
        }
    }

    /**
     * 通过 [Context] 查到顶层 [Activity]
     *
     * @param context
     * @return
     */
    fun findActivity(context: Context?): Activity? {
        if (isNull(context)) return null
        if (context is Activity) return context
        if (context is ContextWrapper) {
            return findActivity(context.getBaseContext())
        }
        return null
    }

    fun isNull(context: Context?): Boolean {
        return ObjNull.isNull(context)
    }


    /**
     * 检查蓝牙权限状态
     */
    enum class PermissionStatus {
        GRANTED,           // 已授权
        DENIED,            // 被拒绝
        PERMANENTLY_DENIED, // 被永久拒绝
        NOT_REQUESTED      // 未请求过
    }


}