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
final class FunctionParameterListEscapeVisitor: SyntaxVisitor {
    private(set) var escape: [Bool] = []
    private(set) var escapeMap: [String: Bool] = [:]
    
    /// use carefully, function call can skip arg where it has default value.
    subscript(index: Int) -> Bool {
        guard index < escape.count else { return false }
        return escape[index]
    }
    
    subscript(name: String) -> Bool {
        return escapeMap[name] ?? false
    }

    /// @inlinable func map<T>(_ transform: @escaping (Element) throws -> T) rethrows -> [T]
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        let args = node.signature.input.parameterList.map { $0 }
        
        escape = .init(repeating: false, count: args.count)
        for (index, arg) in args.enumerated() {
            guard let type = arg.type else {
                escape[index] = false
                continue
            }
            
            let isEscape = EscapingDetector.detect(type: type)
            escape[index] = isEscape
            if let name = arg.firstName?.text {
                escapeMap[name] = isEscape
            }
        }
        
        return .skipChildren
    }
    
    /// (((@escaping (Int) -> ()) -> ()), Int) -> ()
    override func visit(_ node: SequenceExprSyntax) -> SyntaxVisitorContinueKind {
        let target = "typealias A = \(node.description)"
        if let source = try? SyntaxParser.parse(source: target) {
            walk(source)
        }
        
        return .skipChildren
    }
    
    /// typealias A = (((@escaping (Int) -> ()) -> ()), Int) -> ()
    override func visit(_ node: FunctionTypeSyntax) -> SyntaxVisitorContinueKind {
        let args: [TupleTypeElementListSyntax.Element] = node.arguments.map { $0 }
        
        escape = .init(repeating: false, count: args.count)
        for (index, arg) in args.enumerated() {
            escape[index] = EscapingDetector.detect(type: arg.type)
        }
        
        return .skipChildren
    }
}
