//
//  WeakDetector.swift
//
//
//  Created by Yume on 2023/9/13.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxParser

public enum WeakDetector {
  /// input:
  ///   weak var c: Int?
  ///   unowned var c: Int
  ///   var c: Int
  public static func detect(code: String) -> Bool {
    let target: String = code
    do {
      let source: SourceFileSyntax = try SyntaxParser.parse(source: target)
      let visitor = WeakVisitor(viewMode: .sourceAccurate)
      visitor.walk(source)
      return visitor.isHaveWeak || visitor.isHaveUnowned
    } catch {
      return false
    }
  }
}

private final class WeakVisitor: SyntaxVisitor {
  var isHaveWeak: Bool = false
  var isHaveUnowned: Bool = false
  override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    let modifiers = node.modifiers?.map { $0.withoutTrivia().description } ?? []
    isHaveWeak = modifiers.contains("weak")
    isHaveUnowned = modifiers.contains("unowned")

    return .skipChildren
  }
}
