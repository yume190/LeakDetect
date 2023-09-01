//
//  Class_Obj_StaticFunction_LeakTests.swift
//
//
//  Created by Yume on 2022/7/11.
//

import Foundation
import XCTest

final class Class_Obj_StaticFunction_LeakTests: _LeakTests {}

// MARK: - class -

// MARK: Single self

extension Class_Obj_StaticFunction_LeakTests {
    final func testNoLeak() throws {
        let code = """
        extension C {
            static func leak() {
                let c = C()
                nonescape {
                    print(c.a)
                }
            }
        }
        """
        
        try XCTAssertEqual(Self.count(code), 0)
    }
    
    final func testLeak() throws {
        let code = """
        extension C {
            static func leak() {
                let c = C()
                escape {
                    print(c.a)
                }
            }
        }
        """
        
        try XCTAssertEqual(Self.count(code), 1)
    }
}

// MARK: Nested self

extension Class_Obj_StaticFunction_LeakTests {
    final func testNested1() throws {
        let code = """
        extension C {
            static func leak() {
                let c = C()
                escape {
                    print(c.a)
                    escape {
                        print(c.a)
                    }
                }
            }
        }
        """
        
        try XCTAssertEqual(Self.count(code), 2)
    }
    
    final func testNested2() throws {
        let code = """
        extension C {
            static func leak() {
                let c = C()
                nonescape {
                    print(c.a)
                    nonescape {
                        print(c.a)
                    }
                }
            }
        }
        """
        
        try XCTAssertEqual(Self.count(code), 0)
    }
    
    /// this case can solve by `escape { [a] in ... }`
    final func testNested3() throws {
        let code = """
        extension C {
            static func leak() {
                let c = C()
                escape {
                    print(c.a)
                    nonescape {
                        print(c.a)
                    }
                }
            }
        }
        """
        
        try XCTAssertEqual(Self.count(code), 2)
    }
    
    final func testNested4() throws {
        let code = """
        extension C {
            static func leak() {
                let c = C()
                nonescape {
                    print(c.a)
                    escape {
                        print(c.a)
                    }
                }
            }
        }
        """
        
        try XCTAssertEqual(Self.count(code), 1)
    }
    
    final func testNestedSpecial() throws {
        let code = """
        extension C {
            static func leak() {
                let c = C()
                escape {
                    escape { [weak c] in
                    }
                }
            }
        }
        """
        
        try XCTAssertEqual(Self.count(code), 1)
    }
}

// MARK: Single self assign

extension Class_Obj_StaticFunction_LeakTests {
    final func testAssign1() throws {
        let code = """
        extension C {
            static func leak() {
                let c = C()
                escape {
                    c.a = 1
                }
            }
        }
        """
        
        try XCTAssertEqual(Self.count(code), 1)
    }
    
    final func testAssign2() throws {
        let code = """
        extension C {
            static func leak() {
                let c = C()
                escape {
                    let a = c.a
                }
            }
        }
        """
        
        try XCTAssertEqual(Self.count(code), 1)
    }
}
