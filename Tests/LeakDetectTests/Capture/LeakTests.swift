//
//  LeakTests.swift
//
//
//  Created by Yume on 2022/7/8.
//

import Foundation
@testable import LeakDetectKit
@testable import SKClient
import SwiftSyntax
import SwiftSyntaxParser
import XCTest

/// Type: class, struct, enum, protocol, extension(class, struct), ...
/// Target: self, object
/// Situation: single closure, nested closure
class _LeakTests: XCTestCase {
  /// escape function
  /// nonescape function
  static let _functions = resource(file: "Functions.swift.data")
  static let _model = resource(file: "Model.swift.data")
  static let _load = [_functions, _model]

  static func detect(_ code: String, _ sdk: SDK = .macosx) throws -> (Pipeline, [LeakResult]) {
    let path = "code: /temp.swift"
    let pipeline = try Pipeline(
      path,
      code,
      sdk.args + Self._load + [path]
    )

    return try (pipeline, pipeline.detectCapture(.default))
  }

  static func count(_ code: String, _ sdk: SDK = .macosx) throws -> Int {
    return try detect(code, sdk).1.count
  }
}
