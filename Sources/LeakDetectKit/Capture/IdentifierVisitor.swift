//
//  IdentifierVisitor.swift
//  
//
//  Created by Yume on 2022/5/20.
//

import Foundation
import SwiftSyntax

/// skip find IdentifierExprSyntax(ID)
///     in function call `ID1(x, ID2, x.x(ID3), x.x {ID4})`
///     in closure `{ [ID1] ID2 in ID3}`
final class IdentifierVisitor: SyntaxVisitor {
    lazy var ids: [IdentifierExprSyntax] = []
    
    /// xxx(...)
    final override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }
    
    /// { [...] _ in ... }
    final override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }
    
    final override func visit(_ node: OptionalChainingExprSyntax) -> SyntaxVisitorContinueKind {
        if let base = node.expression.firstBase {
            ids.append(base)
        }
        
        return .skipChildren
    }
    
    final override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        if let base = node.base?.firstBase {
            ids.append(base)
        }
        
        return .skipChildren
    }
    
    final override func visit(_ node: IdentifierExprSyntax) -> SyntaxVisitorContinueKind {
        ids.append(node)
        return .skipChildren
    }
}
