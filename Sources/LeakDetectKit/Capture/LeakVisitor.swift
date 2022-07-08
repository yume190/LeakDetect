// old
//
//  LeakVisitor.swift
//
//
//  Created by Yume on 2022/5/13.
//

import Foundation
import SwiftSyntax
import Rainbow
import SKClient

/// Find sub `function`/`closure`
///     pass id to ``IdentifierVisitor``
internal final class LeakVisitor: SyntaxVisitor {
    internal enum ClosureType {
        case trailing
        case label(String)
        case wild
    }
    
    internal let isInDecl: Bool
    internal let start: SyntaxProtocol?
    internal let function: ExprSyntax?
    internal let closureType: ClosureType
    
    
    private lazy var _subVisitors: [LeakVisitor] = []
    private lazy var _idVisitor: IdentifierVisitor = .init()
    internal var subVisitors: [LeakVisitor] {
        return [self] + _subVisitors.flatMap(\.subVisitors)
    }
    
    internal var ids: [IdentifierExprSyntax] {
        return self._idVisitor.ids
    }
    
    internal init(
        isInDecl: Bool,
        start: SyntaxProtocol? = nil,
        function: ExprSyntax? = nil,
        type: ClosureType = .wild
    ) {
        self.isInDecl = isInDecl
        self.start = start
        self.function = function
        self.closureType = type
    }
    
    // MARK: Skip Decls
    internal final override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }
    internal final override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }
    internal final override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }
    internal final override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }
    
    /// var a: Int = {1}()
    /// var b: Int {1}
    /// let c = 1
    internal final override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        let list = node.bindings
        
        if !isInDecl {
            walk(list)
            return .skipChildren
        }

        if let bind = list.first, list.count == 1 {
            /// class A {
            ///     lazy var a: A = {
            ///         //   ^
            ///         //    \
            ///         return self
            ///     }()
            /// }
            if let f = bind.initializer?.value.as(FunctionCallExprSyntax.self) {
                let start = bind.pattern.as(IdentifierPatternSyntax.self)

                if let closure = f.calledExpression.as(ClosureExprSyntax.self) {
                    let visitor = LeakVisitor(isInDecl: false, start: start)
                    visitor.walk(closure.statements)
                    _subVisitors.append(visitor)
                }

                return .skipChildren
            }

            /// class A {
            ///     var b: A {
            ///         // ^
            ///         //   \
            ///         return self
            ///     }
            /// }
            if let f = bind.accessor {
                let start = bind.pattern.as(IdentifierPatternSyntax.self)
                let visitor = LeakVisitor(isInDecl: false, start: start)
                visitor.walk(f)
                _subVisitors.append(visitor)
            }
        }

        return .skipChildren
    }
    
    /// func xxx() {
    ///     // ...
    ///     // self offset at xxx
    ///     //                ^
    /// }
    internal final override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        if let body = node.body {
            let visitor = LeakVisitor(isInDecl: false, start: node.identifier)
            visitor.walk(body)
            self._subVisitors.append(visitor)
        }
        
        return .skipChildren
    }
    
    /// { [weak self] a, b in
    ///     // self offset at [weak self]
    ///     //                      ^
    /// }
    internal final override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        let visitor = LeakVisitor(isInDecl: false, start: node.leftBrace)
        visitor.walk(node.statements)
        self._subVisitors.append(visitor)
        return .skipChildren
    }
    
    // MARK: Binding
    /// if let x = expr
    internal final override func visit(_ node: OptionalBindingConditionSyntax) -> SyntaxVisitorContinueKind {
        let value = node.initializer.value
        self.walk(value)
        self._idVisitor.walk(value)
        return .skipChildren
    }
    
    /// let x = expr
    internal final override func visit(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind {
        if let value = node.initializer?.value {
            self.walk(value)
            self._idVisitor.walk(value)
        }
        return .skipChildren
    }
    
    /// a = b
    internal final override func visit(_ node: ExprListSyntax) -> SyntaxVisitorContinueKind {
        if node.count == 3 {
            let exprs: [ExprListSyntax.Element] = node.map {$0}
            /// a = ?
            if let _ = exprs[0].firstBase, exprs[1].is(AssignmentExprSyntax.self) {
                /// a = b.c
                ///     capture `b`
                if exprs[2].is(MemberAccessExprSyntax.self) {
                    self._idVisitor.walk(exprs[0])
                    self._idVisitor.walk(exprs[2])
                    return .skipChildren
                }
                
                /// a = b()
                ///     walk `b()`
                /// a = {}
                ///     walk `{}`
                if exprs[2].is(FunctionCallExprSyntax.self) || exprs[2].is(ClosureExprSyntax.self) {
                    self._idVisitor.walk(exprs[0])
                    self.walk(exprs[2])
                    return.skipChildren
                }
            }
        }
        
        node.forEach { sub in
            self._idVisitor.walk(sub)
        }
        return .skipChildren
    }
    
    /// a()
    /// a.b.c()
    /// closure()
    internal final override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        self._idVisitor.walk(node.calledExpression)
        self._idVisitor.walk(node.argumentList)
        
        /// .abc().def().xxx()
        self.walk(node.calledExpression)
        self.walk(node.argumentList)

        if let closure = node.trailingClosure {
            let visitor = LeakVisitor(
                isInDecl: false,
                start: closure.leftBrace,
                function: node.calledExpression,
                type: .trailing
            )
            visitor.walk(closure.statements)
            self._subVisitors.append(visitor)
        }
        
        if let closures = node.additionalTrailingClosures {
            // label colon closure
            // abc: {}
            for closure in closures {
                let visitor = LeakVisitor(
                    isInDecl: false,
                    start: closure.closure.leftBrace,
                    function: node.calledExpression,
                    type: .label(closure.label.text)
                )
                visitor.walk(closure.closure.statements)
                self._subVisitors.append(visitor)
            }
            walk(closures)
        }
        
        return .skipChildren
    }
}
