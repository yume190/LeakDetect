//
//  LeakVisitorResult.swift
//
//
//  Created by Yume on 2023/9/6.
//

import Foundation
import SKClient
import SwiftSyntax

public struct LeakVisitorResult: CustomStringConvertible {
  public let originLocation: CodeLocation?
  public let location: CodeLocation
  public let reason: String
  let visitor: LeakVisitor

  private init(
    originLocation: CodeLocation? = nil,
    location: CodeLocation,
    reason: String,
    visitor: LeakVisitor
  ) {
    self.originLocation = originLocation
    self.location = location
    self.reason = reason
    self.visitor = visitor
  }

  private static func originLocation(_ id: IdentifierExprSyntax, _ visitor: LeakVisitor) -> CodeLocation? {
    guard let origin = visitor.rewriter[id.offset] else {
      return nil
    }
    return visitor.client(location: origin)
  }

  static func handleCaptureList(_ id: IdentifierExprSyntax, _ visitor: LeakVisitor) throws -> LeakVisitorResult? {
    guard let start = visitor.parentVisitor?.start else { return nil }
    let startLoc = start.offset
    let cursorInfo = try visitor.client(id.offset)

    guard cursorInfo.isLeak(startLoc) else { return nil }

    return .init(
      originLocation: originLocation(id, visitor),
      location: visitor.client(location: id),
      reason: "Capture List Ref From Parent.Parent",
      visitor: visitor
    )
  }

  static func handleNormal(_ visitor: LeakVisitor, _ skips: Skips) throws -> [LeakVisitorResult] {
    guard let start = visitor.start else { return [] }
    let startLoc = start.offset

    let ids = visitor.results.compactMap { $0.location.syntax?.as(IdentifierExprSyntax.self) } +
      visitor.ids

    let results = try ids.compactMap { id -> LeakVisitorResult? in
      let idInfo = try visitor.client(id.offset)
      guard idInfo.isLeak(startLoc) else { return nil }
      guard let ref = idInfo.offset else { return nil }

      var layers = -1
      var isCapture = false
      var parent: LeakVisitor? = visitor

      while let _parent = parent {
        defer {
          parent = _parent.parentVisitor
          layers += 1
        }
        let function = _parent.function?.tokenSyntax
        let info: SourceKitResponse? = function != nil ?
          try visitor.client(function!) :
          nil

        if _parent.context.isEscape {
          if let info {
            if !skips.isSkip(info) {
              isCapture = true
              continue
            }
          } else {
            /// handle {}()
            isCapture = true
            continue
          }
        }

        let end = (_parent.start?.offset ?? 0) <= ref
        if end {
          break
        }
      }
      if isCapture {
        let reason = [String].init(repeating: "Parent", count: layers).joined(separator: ".")
        let closureName = visitor.function?.withoutTrivia().description ?? "_"
        return .init(
          originLocation: originLocation(id, visitor),
          location: visitor.client(location: id),
          reason: "In \(visitor.context) Closure `\(closureName)` Capture Ref From \(reason)",
          visitor: visitor
        )
      }
      return nil
    }

    return results
  }

  private var context: String {
    let current = location.syntax?.withoutTrivia().description ?? ""
    var all = ["Target: \(current)"]
    var parent: LeakVisitor? = visitor
    while let _parent = parent {
      let name =
        _parent.function?.withoutTrivia().description ??
        _parent.start?.withoutTrivia().description ??
        "_"
      let text = "\(_parent.context) \(name)"
      all = [text] + all
      parent = _parent.parentVisitor
    }
    for (index, text) in all.enumerated() where index != 0 {
      let indent = String(repeating: "  ", count: index - 1)
      all[index] = "\(indent)└─\(text)"
    }
    return all.joined(separator: "\n    ")
  }

  public var description: String {
    let token = location.syntax

    let c: SourceKitResponse? = token?.offset != nil ?
      try? visitor.client(token!.offset) :
      nil

    return """
        Context:
        \(context)
        \("is struct???:".lightBlue) \(c?.typeusr?.isStruct ?? false)
        \("type:".lightBlue) `\(c?.typeusr_demangle ?? "")`
        \("typeusr:".lightBlue) `\(c?.typeusr ?? "")`
        \("kind:".lightBlue) `\(c?.kind?.rawValue ?? "")`
    """
  }

  var result: LeakResult {
    LeakResult(
      location: originLocation ?? location,
      reason: reason,
      verbose: description
    )
  }
}
