//
//  Pipeline.swift
//
//
//  Created by Yume on 2023/8/24.
//

import Foundation
import PathKit
import Rainbow
import SKClient
import SourceKittenFramework
import SwiftParser

public struct Pipeline {
  public let filePath: String
  public let code: String
  public let arguments: [String]
  public let client: SKClient
  public let rewriter: CaptureListRewriter
  public let visitors: Visitors
  public init(_ filePath: String, _ arguments: [String]) throws {
    let path = Path(filePath)
    let code = try path.read(.utf8)

    self.init(filePath, code, arguments)
  }

  public init(_ filePath: String, _ code: String, _ arguments: [String]) {
    self.filePath = filePath
    self.code = code
    self.arguments = arguments
    (client, rewriter) = Pipeline.stage1(filePath, self.code, arguments)
    visitors = Visitors(client, rewriter)
  }

  /// change code
  private static func stage1(
    _ filePath: String,
    _ code: String,
    _ arguments: [String]
  ) -> (SKClient, CaptureListRewriter) {
    let source = Parser.parse(source: code)
    let rewriter = CaptureListRewriter()
    let newSource = rewriter.visit(source)
    let newCode = newSource.description
    let client = SKClient(path: filePath, code: newCode, arguments: arguments)
    return (client, rewriter)
  }

  /// visit all potential leaks
  private func walk() {
    visitors.assign.walk(client.sourceFile)
    visitors.capture.customWalk(client.sourceFile)
  }

  @inline(__always)
  private func prepare<T>(action: () throws -> T) throws -> T {
    _ = try client.editorOpen()
    walk()
    let result = try action()
    _ = try client.editorClose()
    return result
  }

  @discardableResult
  public func detect(_ skips: Skips) throws -> [LeakResult] {
    try prepare {
      try visitors.detect(skips)
    }
  }

  @discardableResult
  public func detectCapture(_ skips: Skips) throws -> [LeakResult] {
    try prepare {
      try visitors.capture.detect(skips)
    }
  }

  @discardableResult
  public func detectAssign() throws -> [LeakResult] {
    try prepare {
      visitors.assign.detect()
    }
  }
}

public extension Pipeline {
  @discardableResult
  static func parse(_ module: Module) throws -> [(index: Int, filePath: String, pipeline: Pipeline)] {
    return try module.sourceFiles.sorted().enumerated().map { index, filePath in
      let pipeline = try Pipeline(filePath, module.compilerArguments)
      return (index, filePath, pipeline)
    }
  }
}
