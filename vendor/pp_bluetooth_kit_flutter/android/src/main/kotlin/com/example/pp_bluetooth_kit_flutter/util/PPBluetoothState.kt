package com.example.pp_bluetooth_kit_flutter.util

enum class PPBluetoothState {
    UNAUTHORIZED,
    //蓝牙打开
    POWERED_ON,
    //蓝牙关闭
    POWERED_OFF,
    //定位打开
    POSITIONING_ON,
    //定位关闭
    POSITIONING_OFF,
    //永久拒绝
    PERMANENTLY_DENY,
}