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
    private let leak: LeakVisitor = .init(isInDecl: true)
    
    private var subVisitors: [DeclsVisitor] {
        return [self] + _subVisitors.flatMap(\.subVisitors)
    }
    internal var leakVisitors: [LeakVisitor] {
        return subVisitors.flatMap(\.leak.subVisitors)
    }
    
    public final func customWalk<SyntaxType>(_ node: SyntaxType) where SyntaxType : SyntaxProtocol {
        super.walk(node)
        leak.walk(node)
    }
    
    private final func append<Syntax: SyntaxProtocol>(_ syntax: Syntax) {
        let visitor = DeclsVisitor()
        _subVisitors.append(visitor)
        visitor.customWalk(syntax)
    }
    
    public final override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        self.append(node.members)
        return .skipChildren
    }
    public final override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        self.append(node.members)
        return .skipChildren
    }
    
    public final override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        self.append(node.members)
        return .skipChildren
    }
    public final override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        self.append(node.members)
        return .skipChildren
    }
}
