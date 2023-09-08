//
//  File.swift
//  
//
//  Created by Yume on 2023/9/7.
//

import Foundation
import LeakDetectKit
import ArgumentParser

public enum Reporter {
    public typealias R = (LeakResult) -> Void
    
    case xcode
    case vscode
    case custom(R)
    
    public func report(_ result: LeakResult) {
        switch self {
        case .vscode:
            print("\(result.location.reportVSCode) \(result.reason)")
        case .xcode:
            print("\(result.location.reportXCode) \(result.reason)")
        case let .custom(report):
            report(result)
        }
    }
}

extension Reporter: ExpressibleByArgument {
    public init?(argument: String) {
        
        switch argument {
        case "xcode":
            self = .xcode
        case "vscode":
            self = .vscode
        default:
            self = .custom { _ in }
        }
    }
    public var defaultValueDescription: String { "vscode" }
    
    public static var allValueStrings: [String] { ["xcode", "vscode", "custom"] }
    public static var defaultCompletionKind: CompletionKind { .list(allValueStrings) }
    
    static let all: String = "xcode|vscode|custom"
}
