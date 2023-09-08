//
//  LeakResult.swift
//
//
//  Created by Yume on 2023/9/5.
//

import Foundation
import SKClient

public struct LeakResult {
  public let location: CodeLocation
  public let reason: String
  public let verbose: String

  public init(location: CodeLocation, reason: String, verbose: String = "") {
    self.location = location
    self.reason = reason
    self.verbose = verbose
  }
  
  public var targetName: String? {
    location.syntax?.withoutTrivia().description
  }
  
  public var reportReason: String  {
    "Target: `\(targetName ?? "")`, Reason: \(reason)"
  }
  
  public var testLocation: String? {
    guard
      let targetName,
      let line = location.location.line,
      let col = location.location.column
    else {return nil}
    return "\(targetName):\(line):\(col)"
  }
}

public extension Reporter {
  func report(_ result: LeakResult) {
    report(result.location, reason: result.reportReason)
  }
}

typealias AssignClosureVisitorResult = LeakResult
