//
//  File.swift
//
//
//  Created by Yume on 2022/5/24.
//

import Cursor
import Foundation
import LeakDetectKit
import SourceKittenFramework
import SwiftSyntax

protocol DetectVisitor: AnyObject {
    init()
    func detect(_ cursor: Cursor, _ reporter: Reporter, _ isVerbose: Bool) throws -> Int
    func walk<SyntaxType: SyntaxProtocol>(_ node: SyntaxType)
}

extension AssignClosureVisitor: DetectVisitor {}
extension DeclsVisitor: DetectVisitor {}

struct File<Visitor>: Comparable {
    let filePath: String
    let cursor: Cursor
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
        try self.cursor.editorOpen()
        let count = try self.visitor.detect(self.cursor, reporter, isVerbose)
        try self.cursor.editorClose()
        return count
    }
}

extension Module {
    func walk<Visitor: DetectVisitor>() async throws -> [File<Visitor>] {
        return try await withThrowingTaskGroup(of: File<Visitor>.self) { group in
            for filePath in self.sourceFiles {
                group.addTask {
                    let cursor: Cursor = try Cursor(path: filePath, arguments: self.compilerArguments)
                    let visitor = Visitor()
                    visitor.walk(cursor.sourceFile)
                    return .init(filePath: filePath, cursor: cursor, visitor: visitor)
                }
            }

            var result: [File<Visitor>] = []
            for try await target in group {
                result.append(target)
            }

            return result
        }
    }
}
