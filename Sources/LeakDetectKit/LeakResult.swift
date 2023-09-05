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
  
  var syntax: String? {
    location.syntax?.withoutTrivia().description
  }
  
  var reportReason: String  {
    "Target: `\(syntax ?? "")`, Reason: \(reason)"
  }

}

extension Reporter {
  func report(_ result: LeakResult) {
    report(result.location, reason: result.reportReason)
  }
}

typealias AssignClosureVisitorResult = LeakResult
