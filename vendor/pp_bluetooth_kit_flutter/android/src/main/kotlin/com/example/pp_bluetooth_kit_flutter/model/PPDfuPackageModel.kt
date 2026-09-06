package com.example.pp_bluetooth_kit_flutter.model

import com.google.gson.annotations.SerializedName




data class PPDfuPackageModel(
    @SerializedName("packages") val packages: PPDfuPackages,
    @SerializedName("deviceSource") val deviceSource: String,
    @SerializedName("packageVersion") val packageVersion: String,
)

data class PPDfuPackages(
    @SerializedName("mcu") val mcu: PPDfuPackageInfo?,
    @SerializedName("ble") val ble: PPDfuPackageInfo?,
    @SerializedName("res") val res: PPDfuPackageInfo?
)

data class PPDfuPackageInfo(
    @SerializedName("version") val version: String,
    @SerializedName("filename") val filename: String
)