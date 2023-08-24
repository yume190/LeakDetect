//
//  LeakTests.swift
//
//
//  Created by Yume on 2022/7/8.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxParser
@testable import LeakDetectKit
@testable import SKClient
import XCTest

/// Type: class, struct, enum, protocol, extension(class, struct), ...
/// Target: self, object
/// Situation: single closure, nested closure
class _LeakTests: XCTestCase {
    /// escape function
    /// nonescape function
    static let _functions = resource(file: "Leak2.swift.data")
    static let _class = resource(file: "Structures.swift.data")
    static let _load = [_functions, _class]

    static func detect(_ code: String) throws -> [IdentifierExprSyntax] {

        let source = try SyntaxParser.parse(source: code)
        let rewriter = CaptureListRewriter()
        let newSource = rewriter.visit(source)
        let newCode = newSource.description
        let client = SKClient(code: newCode, arguments: SDK.macosx.pathArgs + Self._load)

//        let client = SKClient(code: code, arguments: SDK.macosx.pathArgs + Self._load)

        let visitor = DeclsVisitor(viewMode: .sourceAccurate)
        visitor.customWalk(client.sourceFile)

        try client.editorOpen()
        let ids = try visitor.detect(client, .vscode, false)
        try client.editorClose()

        return ids
    }

    static func count(_ code: String) throws -> Int {
        return try detect(code).count
    }
}
