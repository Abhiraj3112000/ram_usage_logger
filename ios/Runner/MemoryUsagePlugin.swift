//
//  MemoryUsagePlugin.swift
//  Runner
//
//  Created by Abhiraj Chatterjee on 21/09/25.
//

import Foundation
import Flutter

public class MemoryUsagePlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.example/memory_usage",
            binaryMessenger: registrar.messenger()
        )
        let instance = MemoryUsagePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "getMemoryUsage" {
            result(getMemoryUsageInMB())
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    private func getMemoryUsageInMB() -> Double {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.stride) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            return Double(info.phys_footprint) / 1024.0 / 1024.0
        } else {
            return -1
        }
    }
}

