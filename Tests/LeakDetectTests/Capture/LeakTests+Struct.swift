//
//  Strcut_Self_LeakTests.swift
//
//
//  Created by Yume on 2022/7/11.
//

import Foundation
import XCTest

final class Strcut_Self_LeakTests: _LeakTests {}

extension Strcut_Self_LeakTests {
    final func testStruct() throws {
        let code = """
        struct B {
            var a = 1
            func leak() {
                escape {
                    let a = self.a
                }
            }
        }
        """

        try XCTAssertEqual(Self.count(code), 0)
    }
}
