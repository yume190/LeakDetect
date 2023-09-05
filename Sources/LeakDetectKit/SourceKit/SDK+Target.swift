//
//  SDK+Target.swift
//
//
//  Created by Yume on 2023/9/5.
//

import Foundation
import SKClient

extension SDK {
  public var args: [String] {
    pathArgs + target
  }
  
  /// Target Triple
  var target: [String] {
    switch self {
    case .macosx:
      return []
      
    case .iphoneos:
      /// arm64-apple-ios11.0
      return ["-target", "arm64-apple-ios"]
    case .iphonesimulator:
      /// x86_64-apple-ios16.2-simulator
      return ["-target", "x86_64-apple-ios-simulator"]
    
    // TODO:
    case .watchos:
      return []
    case .watchsimulator:
      return []

    // TODO:
    case .appletvos:
      return []
    case .appletvsimulator:
      return []
    }
  }
}
