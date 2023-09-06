//
//  DeclsVisitor.swift
//
//
//  Created by Yume on 2022/5/23.
//

import Foundation
import SwiftSyntax
import SKClient

/// only visit:
///     `class`, `struct`, `enum`, `extension`, `actor`, ~~`protocol`~~
///
/// Source Code use ``customWalk`` to walk `static func` and `sub DeclsVisitor`
public final class DeclsVisitor: SyntaxVisitor {
    private lazy var _subVisitors: [DeclsVisitor] = []
    private let leak: LeakVisitor

    
    public init(client: SKClient, _ rewriter: CaptureListRewriter) {
        self.leak = LeakVisitor(
            context: .global(.file),
            client: client,
            rewriter: rewriter)
        
        super.init(viewMode: .sourceAccurate)
    }
    
    init(client: SKClient, _ rewriter: CaptureListRewriter, _ global: LeakVisitor.Context.Global) {
        self.leak = LeakVisitor(
            context: .global(global),
            client: client,
            rewriter: rewriter)
        super.init(viewMode: .sourceAccurate)
    }

    override public final func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = node.identifier.withoutTrivia().description
        self.append(node.members, .class(name))
        return .skipChildren
    }

    override public final func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = node.identifier.withoutTrivia().description
        self.append(node.members, .class(name))
        return .skipChildren
    }

    override public final func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = node.identifier.withoutTrivia().description
        self.append(node.members, .class(name))
        return .skipChildren
    }

    override public final func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = node.extendedType.withoutTrivia().description
        self.append(node.members, .class(name))
        return .skipChildren
    }
    
    override public final func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = node.identifier.withoutTrivia().description
        self.append(node.members, .class(name))
        return .skipChildren
    }
}

extension DeclsVisitor {
    var subVisitors: [DeclsVisitor] {
        return [self] + self._subVisitors.flatMap(\.subVisitors)
    }

    var leakVisitors: [LeakVisitor] {
        return self.subVisitors.flatMap(\.leak.subVisitors)
    }

    public final func customWalk<SyntaxType>(_ node: SyntaxType) where SyntaxType: SyntaxProtocol {
        super.walk(node)
        self.leak.walk(node)
    }

    private final func append<Syntax: SyntaxProtocol>(_ syntax: Syntax, _ global: LeakVisitor.Context.Global) {
        let visitor = DeclsVisitor(client: leak.client, leak.rewriter, global)
        self._subVisitors.append(visitor)
        visitor.customWalk(syntax)
    }
}

public extension DeclsVisitor {
    func detect() throws -> [LeakResult] {
        let all = leakVisitors

        var results: [LeakVisitorResult] = []

        for visitor in all {
            results += try LeakVisitorResult.handleNormal(visitor)
        }
      
        let newResults = results.map(\.result)
      
        return newResults
    }
}
