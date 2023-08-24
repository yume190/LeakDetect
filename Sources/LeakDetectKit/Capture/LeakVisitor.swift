// old
//
//  LeakVisitor.swift
//
//
//  Created by Yume on 2022/5/13.
//

import Foundation
import Rainbow
import SKClient
import SwiftSyntax

/// only visit:
///  * VariableDeclSyntax

/// Find sub `function`/`closure`
///     pass id to ``IdentifierVisitor``
final class LeakVisitor: SyntaxVisitor {
    enum ClosureType {
        case trailing
        case label(String)
        case wild
    }

    /// is Visistor in (true)
    ///  * file
    ///  * class
    ///  * struct
    ///  * enum
    ///  * extension
    let isInDecl: Bool

    /// The start syntax of closure: `{`.
    /// Or `self` reference
    ///  * functionName
    ///  * ...
    let start: SyntaxProtocol?
    /// the `FunctionCallsyntax`
    let function: ExprSyntax?
    let closureType: ClosureType
    unowned let parentVisitor: LeakVisitor?

    /// for `ClosureCaptureItemSyntax` expression
    lazy var closureCaptureIDs: [IdentifierExprSyntax] = []

    private lazy var _subVisitors: [LeakVisitor] = []
    var subVisitors: [LeakVisitor] {
        return [self] + self._subVisitors.flatMap(\.subVisitors)
    }

    private lazy var _idVisitor: IdentifierVisitor = .init(viewMode: .sourceAccurate)
    var ids: [IdentifierExprSyntax] {
        return self._idVisitor.ids
    }

    init(
        isInDecl: Bool,
        start: SyntaxProtocol? = nil,
        function: ExprSyntax? = nil,
        type: ClosureType = .wild,
        parentVisitor: LeakVisitor?
    ) {
        self.isInDecl = isInDecl
        self.start = start
        self.function = function
        self.closureType = type
        self.parentVisitor = parentVisitor
        super.init(viewMode: .sourceAccurate)
    }

    // MARK: - Skip Decls(Start)

    override final func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    override final func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    override final func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    override final func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    // MARK: Skip Decls(End) -

    /// VariableDeclSyntax
    /// letOrVar bindings
    /// var      a: Int = {1}()
    /// var      b: Int {1}
    /// let      c = 1
    override final func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        let list = node.bindings

        if !self.isInDecl {
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
                    let visitor = LeakVisitor(isInDecl: false, start: start, parentVisitor: self)
                    self.append(visitor, closure: closure)
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
                let visitor = LeakVisitor(isInDecl: false, start: start, parentVisitor: self)
                self.append(visitor, node: f)
            }
        }

        return .skipChildren
    }

    /// FunctionDeclSyntax
    /// funcKeyword identifier signature body
    /// func        xxx        (a: Int)  {...}
    ///
    /// func xxx() {
    ///     // ...
    ///     // self offset at xxx
    ///     //                ^
    /// }
    override final func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        if let body = node.body {
            let visitor = LeakVisitor(isInDecl: false, start: node.identifier, parentVisitor: self)
            self.append(visitor, node: body)
        }

        return .skipChildren
    }

    /// ClosureExprSyntax
    /// { signature             statements }
    ///   [weak self] a, b in   ...
    ///
    /// { [weak self] a, b in
    ///     // self offset at [weak self]
    ///     //                      ^
    /// }
    override final func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        let visitor = LeakVisitor(isInDecl: false, start: node.leftBrace, parentVisitor: self)
        self.append(visitor, closure: node)

        return .skipChildren
    }

    /// Only for Sub LeakVisitor when meet `ClosureExprSyntax`
    ///
    /// specifier name assignToken expression
    /// weak      a    =           a
    ///                            a
    override final func visit(_ node: ClosureCaptureItemSyntax) -> SyntaxVisitorContinueKind {
        if node.name != nil && node.assignToken != nil {
            if let id = node.expression.as(IdentifierExprSyntax.self) {
                self.closureCaptureIDs.append(id)
            }
        }
        return .skipChildren
    }

    // MARK: Binding

    /// if let x = expr
    override final func visit(_ node: OptionalBindingConditionSyntax) -> SyntaxVisitorContinueKind {
        if let value = node.initializer?.value {
            self.walk(value)
            self._idVisitor.walk(value)
        }
        return .skipChildren
    }

    /// PatternBindingSyntax (let `x = expr`)
    /// pattern  initializer
    /// x        = expr
    override final func visit(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind {
        if let value = node.initializer?.value {
            self.walk(value)
            self._idVisitor.walk(value)
        }
        return .skipChildren
    }

    /// a = b
    override final func visit(_ node: ExprListSyntax) -> SyntaxVisitorContinueKind {
        if node.count == 3 {
            let exprs: [ExprListSyntax.Element] = node.map { $0 }
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
                    return .skipChildren
                }
            }
        }

        node.forEach { sub in
            self._idVisitor.walk(sub)
        }
        return .skipChildren
    }

    /// FunctionCallExprSyntax a.b.c(1, 2, 3)
    /// calledExpression ( argumentList )
    /// a.b.c              1, 2, 3
    ///
    /// closures:
    ///  * additionalTrailingClosures
    ///  * trailingClosure
    override final func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
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
                type: .trailing,
                parentVisitor: self
            )
            self.append(visitor, closure: closure)
        }

        if let closures = node.additionalTrailingClosures {
            // label colon closure
            // abc: {}
            for closure in closures {
                let visitor = LeakVisitor(
                    isInDecl: false,
                    start: closure.closure.leftBrace,
                    function: node.calledExpression,
                    type: .label(closure.label.text),
                    parentVisitor: self
                )

                self.append(visitor, closure: closure.closure)
            }
        }

        return .skipChildren
    }
}

extension LeakVisitor {
    private func append(_ visitor: LeakVisitor, closure: ClosureExprSyntax) {
        visitor.walk(closure.statements)
        if let capture = closure.signature?.capture {
            visitor.walk(capture)
        }
        self._subVisitors.append(visitor)
    }

    private func append<Syntax: SyntaxProtocol>(_ visitor: LeakVisitor, node: Syntax) {
        visitor.walk(node)
        self._subVisitors.append(visitor)
    }
}
