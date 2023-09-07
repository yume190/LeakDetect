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

  static func handleNormal(_ visitor: LeakVisitor) throws -> [LeakVisitorResult] {
    guard let start = visitor.start else { return [] }
    let startLoc = start.offset

    let ids = visitor.results.compactMap { $0.location.syntax?.as(IdentifierExprSyntax.self) } +
      visitor.ids

    let results = try ids.compactMap { id -> LeakVisitorResult? in
      let cursorInfo = try visitor.client(id.offset)
      guard cursorInfo.isLeak(startLoc) else { return nil }

      switch visitor.context {
      case .cumputedImmediately: fallthrough
      case .nonEscaping:
        var parent: LeakVisitor? = visitor.parentVisitor
        var reason = "Parent"
        var isCapture = false
        while let _parent = parent {
          if _parent.context.isEscape {
            isCapture = true
            parent = _parent.parentVisitor
            reason += ".Parent"
            continue
          }

          let end1 =
            _parent.context.isGlobal &&
            isCapture

          let end2 =
            !_parent.context.isColsure &&
            isCapture &&
            _parent.parentVisitor?.context.isGlobal == true

          if end1 || end2 {
            return .init(
              originLocation: originLocation(id, visitor),
              location: visitor.client(location: id),
              reason: "In Non-Escaping Closure Capture Ref From \(reason)",
              visitor: visitor
            )
          }

          return nil
        }
        return nil

      default:
        return .init(
          originLocation: originLocation(id, visitor),
          location: visitor.client(location: id),
          reason: "Capture Ref From Parent",
          visitor: visitor
        )
      }
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
      //          location: location,
      location: originLocation ?? location,
      reason: reason,
      verbose: description
    )
  }
}

import Foundation

func escape(block: @escaping () -> Void) {}

func nonescape(block: () -> Void) {}

// class A {
//    func leak() {
//        let a = A()
//        let b = A()
//        // escape {
//        //     print(a)
//        // }
//
//        // nonescape {
//        //     let block = {
//        //         print(a)
//        //     }
//        // }
//
//        nonescape {
//            escape { [b = a] in
//                print(a, b)
//            }
//        }
//
//        // struct AA {
//        //     func leak() {
//        //         let aa = AA ()
//        //         escape {
//        //             print(aa)
//        //         }
//        //     }
//        // }
//    }
// }
