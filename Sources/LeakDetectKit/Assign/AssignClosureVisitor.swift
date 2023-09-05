//
//  Assign.swift
//  TypeFillTests
//
//  Created by Yume on 2021/10/21.
//

import Foundation
import Rainbow
import SKClient
import SwiftSyntax

// TODO: let x = obj.func
// TODO: if let x = obj.func
public final class AssignClosureVisitor: SyntaxVisitor {
    private(set) var results: [AssignClosureVisitorResult] = []
    public let client: SKClient

    public init(client: SKClient) {
        self.client = client
        super.init(viewMode: .sourceAccurate)
    }

    /// self.a = self.abc
    ///
    /// expr self.a/a
    ///     MemberAccessExpr/IdentifierExpr
    /// expr =
    ///     AssigmentExpr
    /// expr self.abc/abc
    ///     MemberAccessExpr/IdentifierExpr
    override public final func visit(_ node: ExprListSyntax) -> SyntaxVisitorContinueKind {
        find(node)
        return .visitChildren
    }

    /// _ = `obj.func/instancFunc`
    @inline(__always)
    private final func find(_ node: ExprListSyntax) {
        guard node.count == 3 else { return }
        let exprs: [ExprListSyntax.Element] = node.map { $0 }

        guard let _ = exprs[0].tokenSyntax else { return }
        guard exprs[1].is(AssignmentExprSyntax.self) else { return }

        guard !exprs[2].is(FunctionCallExprSyntax.self) else { return }
        guard let identifier: TokenSyntax = exprs[2].tokenSyntax else { return }

        add(identifier, "Assign Instance Function To Variable")
    }

    /// self.def(self.abc)
    ///
    /// calledExpression self.def/def
    ///     MemberAccessExpr/IdentifierExpr
    /// argumentList
    ///     TupleExprElementSyntax expression
    ///     TupleExprElementSyntax
    override public final func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        find(node)
        return .visitChildren
    }

    @inline(__always)
    private final func find(_ node: FunctionCallExprSyntax) {
        let info = client.functionInfo(node)
        for param in node.argumentList {
            guard let identifier: TokenSyntax = param.expression.tokenSyntax else { continue }
            if let name = param.label?.text, let info {
                if info.isEscape(name) {
                    add(identifier,
                        "Assign Instance Function To Escaping Closure Argument")
                }
            } else {
                add(identifier, "Assign Instance Function To Argument")
            }
        }
    }

    private func add(_ token: TokenSyntax, _ reason: String) {
        guard let isRIF = try? client(token).isRefInstanceFunction, isRIF else {
            return
        }

        results.append(AssignClosureVisitorResult(
            location: client(location: token),
            reason: reason))
    }
}

public extension AssignClosureVisitor {
    final func detect() -> [LeakResult] {
        return results
    }
}
