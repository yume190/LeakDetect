//
//  EscapeVisitor.swift
//
//  Created by Yume on 2021/10/19.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxParser

/// typealias A = @escaping () -> Void
/// typealias B = (() -> Void)
/// typealias C = (() -> Void)?
/// find `escaping` from it's type
internal final class TypeEscapeVisitor: SyntaxVisitor {
    internal var isEscape: Bool = false
  
    internal override func visit(_ node: TypeInitializerClauseSyntax) -> SyntaxVisitorContinueKind {
        return self.find(type: node.value) ?? .skipChildren
    }
    
    internal final func find(type: TypeSyntax) -> SyntaxVisitorContinueKind? {
        
        /// Swift.Optional<(Swift.Error) -> ()>
        if let t = type.as(MemberTypeIdentifierSyntax.self) {
            if let elements = t.genericArgumentClause?.arguments,
               elements.count == 1,
               t.baseType.description == "Swift",
               t.name.description == "Optional" {
                // <(Swift.Error) -> ()> -> ["(Swift.Error)", "()"]
                // <Int>                 -> []
                let parts = elements
                    .first?
                    .withoutTrivia()
                    .description
                    .parseSourkitFunctionTypeName() ?? []
              
                if !parts.isEmpty {
                    self.isEscape = true
                }
                return .skipChildren
            }
        }
        
        /// X?
        if let wrapped: TypeSyntax = type.as(OptionalTypeSyntax.self)?.wrappedType {
            return find(type: wrapped)
        }
        
        /// @escaping Closure
        if let attrs: AttributeListSyntax = type.as(AttributedTypeSyntax.self)?.attributes {
            self.walk(attrs) // -> visit(_ node: AttributeSyntax)
            return .skipChildren
        }
        
        /// (Closure)
        if
            let elements: TupleTypeElementListSyntax = type.as(TupleTypeSyntax.self)?.elements,
            let _ = elements.first?.type.as(FunctionTypeSyntax.self),
            elements.count == 1 {
            self.isEscape = true
            return .skipChildren
        }
        
        return nil
    }
    
    internal override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
        if node.attributeName.text == "escaping" {
            self.isEscape = true
        }
        
        return .skipChildren
    }
}
