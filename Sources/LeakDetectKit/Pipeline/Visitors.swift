//
//  Visitors.swift
//
//
//  Created by Yume on 2023/9/6.
//

import Foundation
import SKClient

public struct Visitors {
  public let assign: AssignClosureVisitor
  public let capture: DeclsVisitor

  init(_ client: SKClient, _ rewriter: CaptureListRewriter) {
    self.assign = AssignClosureVisitor(client: client)
    self.capture = DeclsVisitor(client: client, rewriter)
  }

  func detect(_ skips: Skips) throws -> [LeakResult] {
    return try
      assign.detect() +
      capture.detect(skips)
  }
}
