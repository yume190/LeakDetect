//
//  Assign.swift
//  TypeFillTests
//
//  Created by Yume on 2021/10/21.
//

import Foundation
import SwiftSyntax
import Rainbow
import Cursor

public final class AssignClosureVisitor: SyntaxVisitor {
    
    private(set) var results: [TokenSyntax] = []
    
    /// self.a = self.abc
    ///
    /// expr self.a/a
    ///     MemberAccessExpr/IdentifierExpr
    /// expr =
    ///     AssigmentExpr
    /// expr self.abc/abc
    ///     MemberAccessExpr/IdentifierExpr
    public final override func visit(_ node: ExprListSyntax) -> SyntaxVisitorContinueKind {
        self.find(node)
        return .visitChildren
    }
    
    @inline(__always)
    private final func find(_ node: ExprListSyntax) {
        guard node.count == 3 else {return}
        let exprs: [ExprListSyntax.Element] = node.map {$0}
        
        guard let _ = exprs[0].tokenSyntax else {return}
        guard exprs[1].is(AssignmentExprSyntax.self) else {return}
        
        guard !exprs[2].is(FunctionCallExprSyntax.self) else {return}
        guard let identifier: TokenSyntax = exprs[2].tokenSyntax else {return}

        results.append(identifier)
    }
    
    /// self.def(self.abc)
    ///
    /// calledExpression self.def/def
    ///     MemberAccessExpr/IdentifierExpr
    /// argumentList
    ///     TupleExprElementSyntax expression
    ///     TupleExprElementSyntax
    public final override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        self.find(node)
        return .visitChildren
    }
    
    /// TODO: check decl param is nonescaping
    @inline(__always)
    private final func find(_ node: FunctionCallExprSyntax) {
        for param in node.argumentList {
            guard let identifier: TokenSyntax = param.expression.tokenSyntax else {continue}
            results.append(identifier)
        }
    }
    
    public final func detect(_ cursor: Cursor, _ reporter: Reporter, _ isVerbose: Bool) throws -> Int {
        
        let locs = _detect(cursor)
        
        for loc in locs {
            reporter.report(loc)
            if isVerbose {
                let c = try cursor(loc.location.offset)
                print("""
                    \("kind:".lightBlue) `\(c.kind?.rawValue ?? "")`
                """)
            }
        }
        
        return locs.count
    }
    
    public final func _detect(_ cursor: Cursor) -> [CodeLocation] {
        return results.compactMap { result in
            guard let isRIF = try? cursor(result).isRefInstanceFunction, isRIF else {
                return nil
            }
            return cursor(location: result)
        }
    }
}
