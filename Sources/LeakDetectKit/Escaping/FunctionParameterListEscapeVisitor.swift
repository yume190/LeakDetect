//
//  FunctionParameterListEscapeVisitor.swift
//  TypeFillTests
//
//  Created by Yume on 2021/10/21.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxParser

/// typealias C = (@escaping (@escaping (Int) -> ()) -> (), Int) -> ()
/// typealias C = (((@escaping (Int) -> ()) -> ()), Int) -> ()
/// find `escaping` from `parameter list` by `Index`
internal final class FunctionParameterListEscapeVisitor: SyntaxVisitor {
    private(set) var escape: [Bool] = []
    
    subscript(index: Int) -> Bool {
        guard index < escape.count else { return false }
        return escape[index]
    }

    /// @inlinable func map<T>(_ transform: @escaping (Element) throws -> T) rethrows -> [T]
    internal override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        let args = node.signature.input.parameterList.map{$0}
        
        self.escape = .init(repeating: false, count: args.count)
        for (index, arg) in args.enumerated() {
            guard let type = arg.type else {
                escape[index] = false
                continue
            }
            escape[index] = EscapingDetector.detect(type: type)
        }
        
        return .skipChildren
    }
    
    /// (((@escaping (Int) -> ()) -> ()), Int) -> ()
    internal override func visit(_ node: SequenceExprSyntax) -> SyntaxVisitorContinueKind {
        let target = "typealias A = \(node.description)"
        if let source = try? SyntaxParser.parse(source: target) {
            self.walk(source)
        }
        
        return .skipChildren
    }
    
    /// typealias A = (((@escaping (Int) -> ()) -> ()), Int) -> ()
    internal override func visit(_ node: FunctionTypeSyntax) -> SyntaxVisitorContinueKind {
        
        let args: [TupleTypeElementListSyntax.Element] = node.arguments.map{$0}
        
        self.escape = .init(repeating: false, count: args.count)
        for (index, arg) in args.enumerated() {
            escape[index] = EscapingDetector.detect(type: arg.type)
        }
        
        return .skipChildren
    }
}
