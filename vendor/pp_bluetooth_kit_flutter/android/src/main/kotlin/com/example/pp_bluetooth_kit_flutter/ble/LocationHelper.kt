package com.example.pp_bluetooth_kit_flutter.ble

import android.annotation.SuppressLint
import android.content.Context
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import com.lefu.ppbase.util.Logger

object LocationHelper {

    private var locationManager: LocationManager? = null
    private var locationListener: LocationListener? = null
    var onGPSChangeListener: GpsSwitchStateReceiver.OnGPSChangeListener? = null

    var lasttimes = 0L//用于防止多次调用

    @SuppressLint("MissingPermission")
    fun registerLocationListener(context: Context, onGPSChangeListener: GpsSwitchStateReceiver.OnGPSChangeListener) {
        this.onGPSChangeListener = onGPSChangeListener
        if (locationListener != null) return
        locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager?
        locationListener = object : LocationListener {
            override fun onLocationChanged(location: Location) {
                // 位置改变时的处理
            }

            override fun onStatusChanged(provider: String, status: Int, extras: Bundle) {
                // 位置提供器状态改变时的处理
            }

            override fun onProviderEnabled(provider: String) {
                Logger.i("LocationHelper locationListener onProviderEnabled :true")
                // 位置提供器启用时的处理
                if (System.currentTimeMillis() - lasttimes > 1000) {
                    lasttimes = System.currentTimeMillis()
                    onGPSChangeListener?.onChange(true)
                }
            }

            override fun onProviderDisabled(provider: String) {
                Logger.i("LocationHelper locationListener onProviderDisabled :false")
                // 位置提供器禁用时的处理
                if (System.currentTimeMillis() - lasttimes > 1000) {
                    lasttimes = System.currentTimeMillis()
                    onGPSChangeListener?.onChange(false)
                }
            }
        }
        try {
            locationManager?.requestLocationUpdates(LocationManager.GPS_PROVIDER, 0, 0f, locationListener as LocationListener)
        } catch (e: Exception) {
            Logger.e("LocationHelper registerLocationListener error:$e")
        }
    }

    fun unRegisterLocationListener() {
        // 注销位置监听器
        try {
            locationListener?.let {
                locationManager?.removeUpdates(it)
                locationListener = null
            }
        } catch (e: Exception) {
            Logger.e("LocationHelper unRegisterLocationListener error:$e")
        }
    }

}
