//
//  LeakDetectDangerPlugin.swift
//  
//
//  Created by Yume on 2023/8/25.
//

import Danger
import LeakDetectKit
import SourceKittenFramework

public struct LeakDetectDangerPlugin {
    private static let danger = Danger()
    
    public static func spm(
        _ path: String,
        _ module: String,
        _ arguments: [String] = []
    ) {
        guard let module = Module(spmArguments: arguments, spmName: module) else {
            danger.warn("Can't create module")
            return
        }
        
        try? Pipeline.detect(module, .danger, false)
    }
    
    public static func xcodeproj(
        _ path: String,
        _ module: String,
        _ arguments: [String] = []
    ) {
        let newArgs: [String] = [
            "-project",
            path,
            "-scheme",
            module,
        ]
        guard let module = Module(xcodeBuildArguments: arguments + newArgs, name: module) else {
            danger.warn("Can't create module")
            return
        }
        
        try? Pipeline.detect(module, .danger, false)
    }
    
    public static func xcworkspace(
        _ path: String,
        _ module: String,
        _ arguments: [String] = []
    ) {
        let newArgs: [String] = [
            "-workspace",
            path,
            "-scheme",
            module,
        ]
        guard let module = Module(xcodeBuildArguments: arguments + newArgs, name: module) else {
            danger.warn("Can't create module")
            return
        }
        
        try? Pipeline.detect(module, .danger, false)
    }
    
}
