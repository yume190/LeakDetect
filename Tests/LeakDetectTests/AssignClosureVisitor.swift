//
//  AssignClosureVisitor.swift
//  TypeFillTests
//
//  Created by Yume on 2021/10/20.

import Foundation
import XCTest
import SwiftSyntax
@testable import Cursor
@testable import LeakDetectKit

final class AssignClosureTests: XCTestCase {
    
    func testNormal() throws {
        let path: String = resource(file: "AssignClosure.swift.data")
        let cursor = try Cursor(path: path)
        let visitor = AssignClosureVisitor()
        visitor.walk(cursor.sourceFile)
        let results = visitor._detect(cursor)
        
        let espect = [
            CodeLocation(path: path, location: SourceLocation(offset: 171, converter: cursor.converter)),
            CodeLocation(path: path, location: SourceLocation(offset: 191, converter: cursor.converter)),
            CodeLocation(path: path, location: SourceLocation(offset: 216, converter: cursor.converter)),
            CodeLocation(path: path, location: SourceLocation(offset: 231, converter: cursor.converter)),
        ]
        
        XCTAssertEqual(results.count, espect.count)
        XCTAssertEqual(results, espect)
    }
}
