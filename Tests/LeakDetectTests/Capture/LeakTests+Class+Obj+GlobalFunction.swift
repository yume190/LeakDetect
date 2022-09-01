//
//  Class_Obj_GlobalFunction_LeakTests.swift
//
//
//  Created by Yume on 2022/7/11.
//

import Foundation
import XCTest

final class Class_Obj_GlobalFunction_LeakTests: _LeakTests {}

#warning("todo implement scan global function")
// MARK: - class -
// MARK: Single self
extension Class_Obj_GlobalFunction_LeakTests {
    final func testNoLeak() throws {
        let code = """
        func leak() {
            let a = A()
            nonescape {
                print(a.a)
            }
        }
        """

        try XCTAssertEqual(Self.count(code), 0)
    }

    final func testLeak() throws {
        let code = """
        func leak() {
            let a = A()
            escape {
                print(a.a)
            }
        }
        """

        try XCTAssertEqual(Self.count(code), 1)
    }
}

// MARK: Nested self
extension Class_Obj_GlobalFunction_LeakTests {
    final func testNested1() throws {
        let code = """
        func leak() {
            let a = A()
            escape {
                print(a.a)
                escape {
                    print(a.a)
                }
            }
        }
        """

        try XCTAssertEqual(Self.count(code), 2)
    }


    final func testNested2() throws {
        let code = """
        func leak() {
            let a = A()
            nonescape {
                print(a.a)
                nonescape {
                    print(a.a)
                }
            }
        }
        """

        try XCTAssertEqual(Self.count(code), 0)
    }

    #warning("2")
    final func testNested3() throws {
        let code = """
        func leak() {
            let a = A()
            escape {
                print(a.a)
                nonescape {
                    print(a.a)
                }
            }
        }
        """

        try XCTAssertEqual(Self.count(code), 1)
    }

    final func testNested4() throws {
        let code = """
        func leak() {
            let a = A()
            nonescape {
                print(a.a)
                escape {
                    print(a.a)
                }
            }
        }
        """

        try XCTAssertEqual(Self.count(code), 1)
    }

    #warning("1")
    final func testNestedSpecial() throws {
        let code = """
        func leak() {
            let a = A()
            escape {
                escape { [weak a] in
                }
            }
        }
        """

        try XCTAssertEqual(Self.count(code), 0)
    }
}

// MARK: Single self assign
extension Class_Obj_GlobalFunction_LeakTests {
    final func testAssign1() throws {
        let code = """
        func leak() {
            let a = A()
            escape {
                a.a = 1
            }
        }
        """

        try XCTAssertEqual(Self.count(code), 1)
    }

    final func testAssign2() throws {
        let code = """
        func leak() {
            let a = A()
            escape {
                let a = a.a
            }
        }
        """

        try XCTAssertEqual(Self.count(code), 1)
    }
}
