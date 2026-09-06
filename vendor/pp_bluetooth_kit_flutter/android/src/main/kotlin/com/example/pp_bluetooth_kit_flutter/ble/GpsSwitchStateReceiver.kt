package com.example.pp_bluetooth_kit_flutter.ble

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.location.LocationManager
import com.lefu.ppbase.util.Logger

class GpsSwitchStateReceiver : BroadcastReceiver() {

    var onGPSChangeListener: OnGPSChangeListener? = null
    var lasttimes = 0L//用于防止多次调用
//    var mIsGpsEnabled = false//用于防止多次调用

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.getAction() != null && intent.getAction().equals(LocationManager.PROVIDERS_CHANGED_ACTION)) {
            // 检查GPS开关状态
            val locationManager: LocationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
            val isGpsEnabled: Boolean = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)
            Logger.i("GpsSwitchStateReceiver onChange isGpsEnabled:$isGpsEnabled")
            if (System.currentTimeMillis() - lasttimes > 2000) {
                lasttimes = System.currentTimeMillis()
                // 根据GPS开关状态执行相应操作
                onGPSChangeListener?.onChange(isGpsEnabled)
            }
        }
    }

    interface OnGPSChangeListener {
        fun onChange(isGpsEnabled: Boolean)
    }

}
