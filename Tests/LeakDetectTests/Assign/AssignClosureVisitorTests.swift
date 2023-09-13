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
        let pipeline = try Pipeline(path, SDK.iphoneos.args + [path])
        let results = try pipeline.detectAssign().map(\.testLocation)

        let expect = [
          "abc:11:27",
          "abc:12:17",
          "abc:14:21",
          "abc:15:11",
          "def:29:100",
        ]
      
        XCTAssertEqual(results.count, 5)
        XCTAssertEqual(results, expect)
    }
}
