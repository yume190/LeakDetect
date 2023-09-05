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
    static let _functions = resource(file: "Functions.swift.data")
    static let _model = resource(file: "Model.swift.data")
    static let _load = [_functions, _model]

    static func detect(_ code: String, _ sdk: SDK = .macosx) throws -> [IdentifierExprSyntax] {
//        let pipeline = SingleFilePipeline(
//            "code: /temp.swift",
//            code,
//            SDK.macosx.pathArgs + Self._load + ["code: /temp.swift"]
//        )
//        pipeline.detect(.vscode, false)
        
        let source = try SyntaxParser.parse(source: code)
        let rewriter = CaptureListRewriter()
        let newSource = rewriter.visit(source)
        let newCode = newSource.description
        var args = sdk.args + Self._load
        
        let client = SKClient(code: newCode, arguments: args)
        try client.editorOpen()

        let visitor = DeclsVisitor(client: client)
        visitor.customWalk(client.sourceFile)
        
        let ids = try visitor.detect()
        try client.editorClose()

        return ids.compactMap {
            $0.location.syntax?.as(IdentifierExprSyntax.self)
        }
    }

    static func count(_ code: String, _ sdk: SDK = .macosx) throws -> Int {
        return try detect(code, sdk).count
    }
}
