//
//  DeclsVisitor.swift
//
//
//  Created by Yume on 2022/5/23.
//

import Foundation
import SwiftSyntax

/// only visit:
///     `class`, `struct`, `enum`, `extension`
///
/// Source Code use ``customWalk`` to walk `static func` and ...
public final class DeclsVisitor: SyntaxVisitor {
    private lazy var _subVisitors: [DeclsVisitor] = []
    private let leak: LeakVisitor = .init(isInDecl: true, parentVisitor: nil)

    override public final func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        self.append(node.members)
        return .skipChildren
    }

    override public final func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        self.append(node.members)
        return .skipChildren
    }

    override public final func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        self.append(node.members)
        return .skipChildren
    }

    override public final func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        self.append(node.members)
        return .skipChildren
    }
}

extension DeclsVisitor {
    private var subVisitors: [DeclsVisitor] {
        return [self] + self._subVisitors.flatMap(\.subVisitors)
    }

    var leakVisitors: [LeakVisitor] {
        return self.subVisitors.flatMap(\.leak.subVisitors)
    }

    public final func customWalk<SyntaxType>(_ node: SyntaxType) where SyntaxType: SyntaxProtocol {
        super.walk(node)
        self.leak.walk(node)
    }

    private final func append<Syntax: SyntaxProtocol>(_ syntax: Syntax) {
        let visitor = DeclsVisitor(viewMode: .sourceAccurate)
        self._subVisitors.append(visitor)
        visitor.customWalk(syntax)
    }
}
