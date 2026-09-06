//
//  LefuStreamHandler.swift
//  Pods
//
//  Created by lefu on 2025/3/25
//  


import Foundation
import Flutter


class PPLefuStreamHandler:NSObject, FlutterStreamHandler {
    var event: FlutterEventSink?
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        
        self.event = events
        
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        
        self.event = nil
        return nil
    }
    
    
}
