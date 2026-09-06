package com.example.pp_bluetooth_kit_flutter.util

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.content.Context

object PPBleHelper {

    fun isOpenBluetooth(): Boolean {
        val var0 = BluetoothAdapter.getDefaultAdapter()
        return var0?.isEnabled ?: false
    }

    @SuppressLint("MissingPermission")
    fun openOpenBluetooth(): Boolean {
        val defaultAdapter = BluetoothAdapter.getDefaultAdapter()
        return defaultAdapter?.enable() ?: false
    }

    fun isLocationEnabled(context: Context): Boolean {
        return LocationUtil.isLocationEnabledS(context);
    }


}