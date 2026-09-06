//
//  PPDfuPackageModel.swift
//  Pods
//
//  Created by lefu on 2025/4/3
//  


import Foundation


struct PPDfuPackageModel: Codable {
    let deviceSource: String
    let packageVersion: String
    let packages: PPDfuPackages
}

struct PPDfuPackages: Codable {
    let mcu: PPDfuPackageInfo?
    let ble: PPDfuPackageInfo?
    let res: PPDfuPackageInfo?
}

struct PPDfuPackageInfo: Codable {
    let filename: String
    let version: String
}
