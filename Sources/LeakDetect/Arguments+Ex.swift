//
//  Arguments+Ex.swift
//
//
//  Created by Yume on 2023/8/24.
//

import ArgumentParser
import Foundation
import SKClient
import PathKit

extension Reporter: ExpressibleByArgument {
    public init?(argument: String) {
        
        switch argument {
        case "xcode":
            self = .xcode
        case "vscode":
            self = .vscode
        default:
            self = .custom { _, _ in }
        }
    }
    public var defaultValueDescription: String { "vscode" }
    
    public static var allValueStrings: [String] { ["xcode", "vscode", "custom"] }
    public static var defaultCompletionKind: CompletionKind { .list(allValueStrings) }
    
    static let all: String = "xcode|vscode|custom"
}

extension SDK: ExpressibleByArgument {}

public enum TargetType: String, CaseIterable, ExpressibleByArgument {
    static let all: String = TargetType
        .allCases
        .map(\.rawValue)
        .joined(separator: "|")

    case auto
    case xcodeproj
    case xcworkspace
    case singleFile
    case spm
    
    func detect(_ path: String) -> TargetType {
        guard case .auto = self else {
            return self
        }
        
        if path.hasSuffix(".xcodeproj") {
            return .xcodeproj
        }
        
        if path.hasSuffix(".xcworkspace") {
            return .xcworkspace
        }
        
        if path.hasSuffix(".swift") && !path.hasSuffix("Package.swift") {
            return .singleFile
        }
        
        let path = Path(path)
        let package = path + "Package.swift"
        if path.isDirectory && package.exists {
            return .spm
        }
        
        return .singleFile
    }
}

enum Mode: String, CaseIterable, ExpressibleByArgument {
    case assign
    case capture

    static let all: String = Mode
        .allCases
        .map(\.rawValue)
        .joined(separator: "|")
}
