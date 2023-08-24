//
//  File 2.swift
//  
//
//  Created by Yume on 2023/8/24.
//

import Foundation
import ArgumentParser
import SKClient

extension Reporter: ExpressibleByArgument {
    static let all: String = Reporter
        .allCases
        .map(\.rawValue)
        .joined(separator: "|")
}

extension SDK: ExpressibleByArgument {}

public enum TargetType: String, CaseIterable, ExpressibleByArgument {
    static let all: String = TargetType
        .allCases
        .map(\.rawValue)
        .joined(separator: "|")
    
    case xcodeproj
    case xcodeworkspace
//        case singleFile
    case spm
}


enum Mode: String, CaseIterable, ExpressibleByArgument {
    case assign
    case capture
   
    static let all: String = Mode
        .allCases
        .map(\.rawValue)
        .joined(separator: "|")
}
