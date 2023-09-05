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

public struct LeakVisitorResult: CustomStringConvertible {
    public let location: CodeLocation
    public let reason: String
    let visitor: LeakVisitor

    private init(
        location: CodeLocation,
        reason: String,
        visitor: LeakVisitor
    ) {
        self.location = location
        self.reason = reason
        self.visitor = visitor
    }

    static func handleCaptureList(_ id: IdentifierExprSyntax, _ visitor: LeakVisitor) throws -> LeakVisitorResult? {
        guard let start = visitor.parentVisitor?.start else { return nil }
        let startLoc = start.offset
        let cursorInfo = try visitor.client(id.offset)

        guard cursorInfo.isLeak(startLoc) else { return nil }

        return .init(
            location: visitor.client(location: id),
            reason: "Capture Ref From Parent.Parent",
            visitor: visitor
        )
    }

    static func handleNormal(_ visitor: LeakVisitor) throws -> [LeakVisitorResult] {
        guard let start = visitor.start else { return [] }
        let startLoc = start.offset

        var dict: [String: Bool] = [:]

        let ids = visitor.results.compactMap { $0.location.syntax?.as(IdentifierExprSyntax.self) } +
            visitor.ids

        let results = try ids.compactMap { id -> LeakVisitorResult? in
            let cursorInfo = try visitor.client(id.offset)
            guard cursorInfo.isLeak(startLoc) else { return nil }
            dict[id.identifier.text] = true

            switch visitor.context {
            case .cumputedImmediately: fallthrough
            case .nonEscaping:
                var parent: LeakVisitor? = visitor.parentVisitor
                var reason = "Parent"
                var isCapture = false
                while let _parent = parent {
                    if _parent.context.isEscape {
                        isCapture = true
                        parent = _parent.parentVisitor
                        reason += ".Parent"
                        continue
                    }

                    let end1 =
                        _parent.context.isGlobal &&
                        isCapture

                    let end2 =
                        !_parent.context.isColsure &&
                        isCapture &&
                        _parent.parentVisitor?.context.isGlobal == true

                    if end1 || end2 {
                        return .init(
                            location: visitor.client(location: id),
                            reason: "In Non-Escaping Closure Capture Ref From \(reason)",
                            visitor: visitor
                        )
                    }

                    return nil
                }
                return nil

            default:
                return .init(
                    location: visitor.client(location: id),
                    reason: "Capture Ref From Parent",
                    visitor: visitor
                )
            }
        }

        return results
    }

    private var context: String {
        let current = self.location.syntax?.withoutTrivia().description ?? ""
        var all = ["Target: \(current)"]
        var parent: LeakVisitor? = self.visitor
        while let _parent = parent {
            let name =
                _parent.function?.withoutTrivia().description ??
                _parent.start?.withoutTrivia().description ??
                "_"
            let text = "\(_parent.context) \(name)"
            all = [text] + all
            parent = _parent.parentVisitor
        }
        for (index, text) in all.enumerated() where index != 0 {
            let indent = String(repeating: "  ", count: index - 1)
            all[index] = "\(indent)└─\(text)"
        }
        return all.joined(separator: "\n    ")
    }

    public var description: String {
        let token = self.location.syntax

        let c: SourceKitResponse? = token?.offset != nil ?
            try? self.visitor.client(token!.offset) :
            nil

        return """
            Context:
            \(self.context)
            \("is struct???:".lightBlue) \(c?.typeusr?.isStruct ?? false)
            \("type:".lightBlue) `\(c?.typeusr_demangle ?? "")`
            \("typeusr:".lightBlue) `\(c?.typeusr ?? "")`
            \("kind:".lightBlue) `\(c?.kind?.rawValue ?? "")`
        """
    }
  
    var result: LeakResult {
        LeakResult(location: location, reason: reason, verbose: description)
    }
}

/// only visit:
///  * VariableDeclSyntax
///
/// Find sub `function`/`closure`
///     pass id to ``IdentifierVisitor``
final class LeakVisitor: SyntaxVisitor {
    enum Context: CustomStringConvertible, Equatable {
        enum Global: CustomStringConvertible, Equatable {
            case file
            case `class`(String)
            case `struct`(String)
            case `enum`(String)
            case `extension`(String)
            case `actor`(String)
            
            var description: String {
                switch self {
                case .file:
                    return "File"
                case .class(let name):
                    return "class \(name)"
                case .struct(let name):
                    return "struct \(name)"
                case .enum(let name):
                    return "enum \(name)"
                case .extension(let name):
                    return "extension \(name)"
                case .actor(let name):
                    return "actor \(name)"
                }
            }
        }
        
        /// root file/class/struct/enum/extension/actor
        case global(Global)
        /// var x = `{}`()
        case cumputedImmediately
        /// var x: Int `{}`
        case cumputed
        /// func x() `{}`
        case function
        /// closure in escaping arg
        case escaping
        /// closure in non-escaping arg
        case nonEscaping
        /// unhandle closure
        case unhandle
        
        var description: String {
            switch self {
            case .global(let global):
                return global.description
            case .cumputedImmediately:
                return "cumputedImmediately"
            case .cumputed:
                return "cumputed"
            case .function:
                return "function"
            case .escaping:
                return "escaping"
            case .nonEscaping:
                return "nonEscaping"
            case .unhandle:
                return "unhandle"
            }
        }

        private static let allEscape: [Context] = [
            .escaping,
            .cumputed,
            .unhandle,
        ]

        private static let allColure: [Context] = [
            .escaping,
            .nonEscaping,
            .unhandle,
        ]
        
        var isGlobal: Bool {
            if case .global = self {
                return true
            }
            return false
        }

        var isEscape: Bool {
            return Context.allEscape.contains(self)
        }

        var isColsure: Bool {
            return Context.allColure.contains(self)
        }
    }

    let context: Context

    /// The start syntax of closure: `{`.
    /// Or `self` reference
    ///  * functionName
    ///  * ...
    let start: SyntaxProtocol?
    /// the `FunctionCallSyntax`
    let function: ExprSyntax?
    unowned let parentVisitor: LeakVisitor?
    let client: SKClient

    /// for `ClosureCaptureItemSyntax` expression
    lazy var closureCaptureIDs: [IdentifierExprSyntax] = []
    lazy var results: [LeakVisitorResult] = []

    private lazy var _subVisitors: [LeakVisitor] = []
    var subVisitors: [LeakVisitor] {
        return [self] + self._subVisitors.flatMap(\.subVisitors)
    }

    private lazy var _idVisitor: IdentifierVisitor = .init(parentVisitor: self)
    var ids: [IdentifierExprSyntax] {
        return self._idVisitor.ids
    }

    init(
        context: Context,
        start: SyntaxProtocol? = nil,
        function: ExprSyntax? = nil,
        client: SKClient,
        parentVisitor: LeakVisitor?
    ) {
        self.context = context
        self.start = start
        self.function = function
        self.parentVisitor = parentVisitor
        self.client = client
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

    override final func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
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

        if !self.context.isGlobal {
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
                    let visitor = LeakVisitor(
                        context: .cumputedImmediately,
                        start: start,
                        client: client,
                        parentVisitor: self
                    )
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
                let visitor = LeakVisitor(
                    context: .cumputed,
                    start: start,
                    client: client,
                    parentVisitor: self
                )
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
            let visitor = LeakVisitor(
                context: .function,
                start: node.identifier,
//                function: node.inden
                client: self.client,
                parentVisitor: self
            )
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
        let visitor = LeakVisitor(
            context: .unhandle,
            start: node.leftBrace,
            client: self.client,
            parentVisitor: self
        )
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
                try? add(.handleCaptureList(id, self))
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
                if exprs[2].is(FunctionCallExprSyntax.self) {
                    self._idVisitor.walk(exprs[0])
                    self.walk(exprs[2])
                    return .skipChildren
                }

                /// a = {}
                ///     walk `{}`
                if exprs[2].is(ClosureExprSyntax.self) {
                    self._idVisitor.walk(exprs[0])
                    self.walk(exprs[2])
                    return .skipChildren
                }
            }
        }

        // TODO: use self.walk(sub)?
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

        if let closure = node.calledExpression.as(ClosureExprSyntax.self) {
            /// {...}()
            /// treat closure as non-escaping
            let visitor = LeakVisitor(
                context: .cumputedImmediately,
                start: closure.leftBrace,
                function: node.calledExpression,
                client: self.client,
                parentVisitor: self
            )
            self.append(visitor, closure: closure)
        } else {
            /// .abc().def().xxx()
            self.walk(node.calledExpression)
        }
//        self.walk(node.argumentList)

        self.handleFunctionCallAllClosures(node)

        return .skipChildren
    }

    private func handleFunctionCallAllClosures(_ node: FunctionCallExprSyntax) {
        let info = self.client.functionInfo(node)

        self.handleTrailingClosure(node, info)
        self.handleAdditionalTrailingClosures(node, info)
        self.handleFunctionCallArgClosure(node, info)
    }

    /// handleFunctionCallClosures
    private func handleTrailingClosure(_ node: FunctionCallExprSyntax, _ info: SKClient.FunctionInfo?) {
        guard let closure = node.trailingClosure else { return }

        let isEscape = info?.isEscapeLast()
        let context: Context = isEscape == nil ?
            .unhandle :
            (isEscape! ? .escaping : .nonEscaping)

        let visitor = LeakVisitor(
            context: context,
            start: closure.leftBrace,
            function: node.calledExpression,
            client: self.client,
            parentVisitor: self
        )
        self.append(visitor, closure: closure)
    }

    /// handleFunctionCallClosures
    /// label colon closure
    /// abc   :     {}
    private func handleAdditionalTrailingClosures(_ node: FunctionCallExprSyntax, _ info: SKClient.FunctionInfo?) {
        guard let closureList = node.additionalTrailingClosures else { return }

        for closureItem in closureList {
            let name = closureItem.label.text
            let closure = closureItem.closure

            let isEscape = info?.isEscape(name)
            let context: Context = isEscape == nil ?
                .unhandle :
                (isEscape! ? .escaping : .nonEscaping)

            let visitor = LeakVisitor(
                context: context,
                start: closure.leftBrace,
                function: node.calledExpression,
                client: self.client,
                parentVisitor: self
            )

            self.append(visitor, closure: closure)
        }
    }

    /// handleFunctionCallClosures
    private func handleFunctionCallArgClosure(_ node: FunctionCallExprSyntax, _ info: SKClient.FunctionInfo?) {
        if node.argumentList.count == 1, let arg = node.argumentList.last {
            guard let closure = arg.expression.as(ClosureExprSyntax.self) else {
                walk(arg)
                return
            }

            let isEscape = info?.isEscapeLast()
            let context: Context = isEscape == nil ?
                .unhandle :
                (isEscape! ? .escaping : .nonEscaping)

            let visitor = LeakVisitor(
                context: context,
                start: closure.leftBrace,
                function: node.calledExpression,
                client: self.client,
                parentVisitor: self
            )

            self.append(visitor, closure: closure)
            return
        }

        for arg in node.argumentList {
            guard
                let name = arg.label?.text,
                let closure = arg.expression.as(ClosureExprSyntax.self)
            else {
                walk(arg)
                continue
            }

            let isEscape = info?.isEscape(name)
            let context: Context = isEscape == nil ?
                .unhandle :
                (isEscape! ? .escaping : .nonEscaping)

            let visitor = LeakVisitor(
                context: context,
                start: closure.leftBrace,
                function: node.calledExpression,
                client: self.client,
                parentVisitor: self
            )

            self.append(visitor, closure: closure)
        }
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

    private func add(_ result: LeakVisitorResult?) {
        if let result {
            self.results.append(result)
        }
    }
}
