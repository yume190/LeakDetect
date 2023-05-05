//
//  File.swift
//
//
//  Created by Yume on 2022/5/24.
//

import SKClient
import Foundation
import LeakDetectKit
import SourceKittenFramework
import SwiftSyntax

protocol DetectVisitor: AnyObject {
    init()
    func detectCount(_ client: SKClient, _ reporter: Reporter, _ isVerbose: Bool) throws -> Int
    func walk<SyntaxType: SyntaxProtocol>(_ node: SyntaxType)
}

extension AssignClosureVisitor: DetectVisitor {}
extension DeclsVisitor: DetectVisitor {}

struct File<Visitor>: Comparable {
    let filePath: String
    let client: SKClient
    let visitor: Visitor

    static func < (lhs: File<Visitor>, rhs: File<Visitor>) -> Bool {
        lhs.filePath < rhs.filePath
    }

    static func == (lhs: File<Visitor>, rhs: File<Visitor>) -> Bool {
        lhs.filePath == rhs.filePath
    }
}

extension File where Visitor: DetectVisitor {
    func detect(_ reporter: Reporter, _ isVerbose: Bool) throws -> Int {
        try self.client.editorOpen()
        let count = try self.visitor.detectCount(self.client, reporter, isVerbose)
        try self.client.editorClose()
        return count
    }
}

extension Module {
    func walk<Visitor: DetectVisitor>() throws -> [File<Visitor>] {
        return try self.sourceFiles.map { filePath in
            let client = try SKClient(path: filePath, arguments: self.compilerArguments)
            let visitor = Visitor()
            visitor.walk(client.sourceFile)
            return .init(filePath: filePath, client: client, visitor: visitor)
        }
    }
}
