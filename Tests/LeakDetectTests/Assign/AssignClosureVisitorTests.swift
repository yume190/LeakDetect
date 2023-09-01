//
//  AssignClosureVisitorTests.swift
//  TypeFillTests
//
//  Created by Yume on 2021/10/20.

import Foundation
@testable import LeakDetectKit
@testable import SKClient
import SwiftSyntax
import XCTest

final class AssignClosureVisitorTests: XCTestCase {
    func testNormal() throws {
        let path: String = resource(file: "AssignClosure.swift.data")
        let client = try SKClient(path: path)
        let visitor = AssignClosureVisitor(client: client)
        visitor.walk(client.sourceFile)
        let results = visitor.results.map(\.location)

        let espect = [
            CodeLocation(path: path, location: SourceLocation(offset: 171, converter: client.converter)),
            CodeLocation(path: path, location: SourceLocation(offset: 191, converter: client.converter)),
            CodeLocation(path: path, location: SourceLocation(offset: 216, converter: client.converter)),
            CodeLocation(path: path, location: SourceLocation(offset: 231, converter: client.converter)),
        ]

        XCTAssertEqual(results.count, espect.count)
        XCTAssertEqual(results, espect)
    }
}
