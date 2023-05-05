//
//  Class_Obj_LeakTests.swift
//
//
//  Created by Yume on 2022/7/11.
//

import Foundation
import XCTest

final class Class_Obj_LeakTests: _LeakTests {}

// MARK: - class -

// MARK: Single self

extension Class_Obj_LeakTests {
    final func testNoLeak() throws {
        let code = """
        class AA {
            var a = 1
            func leak() {
                let aa = AA()
                nonescape {
                    print(aa.a)
                }
            }
        }
        """
        
        try XCTAssertEqual(Self.count(code), 0)
    }
    
    final func testLeak() throws {
        let code = """
        class AA {
            var a = 1
            func leak() {
                let aa = AA()
                escape {
                    print(aa.a)
                }
            }
        }
        """
        
        try XCTAssertEqual(Self.count(code), 1)
    }
}

// MARK: Nested self

extension Class_Obj_LeakTests {
    final func testNested1() throws {
        let code = """
        class AA {
            var a = 1
            func leak() {
                let aa = AA()
                escape {
                    print(aa.a)
                    escape {
                        print(aa.a)
                    }
                }
            }
        }
        """
        
        try XCTAssertEqual(Self.count(code), 2)
    }
    
    final func testNested2() throws {
        let code = """
        class AA {
            var a = 1
            func leak() {
                let aa = AA()
                nonescape {
                    print(aa.a)
                    nonescape {
                        print(aa.a)
                    }
                }
            }
        }
        """
        
        try XCTAssertEqual(Self.count(code), 0)
    }
    
    #warning("2")
    final func testNested3() throws {
        let code = """
        class AA {
            var a = 1
            func leak() {
                let aa = AA()
                escape {
                    print(aa.a)
                    nonescape {
                        print(aa.a)
                    }
                }
            }
        }
        """
        
        try XCTAssertEqual(Self.count(code), 1)
    }
    
    final func testNested4() throws {
        let code = """
        class AA {
            var a = 1
            func leak() {
                let aa = AA()
                nonescape {
                    print(aa.a)
                    escape {
                        print(aa.a)
                    }
                }
            }
        }
        """
        
        try XCTAssertEqual(Self.count(code), 1)
    }
    
    #warning("1")
    final func testNestedSpecial() throws {
        let code = """
        class AA {
            var a = 1
            func leak() {
                let aa = AA()
                escape {
                    escape { [weak aa] in
                    }
                }
            }
        }
        """
        
        try XCTAssertEqual(Self.count(code), 0)
    }
}

// MARK: Single self assign

extension Class_Obj_LeakTests {
    final func testAssign1() throws {
        let code = """
        class AA {
            var a = 1
            func leak() {
                let aa = AA()
                escape {
                    aa.a = 1
                }
            }
        }
        """
        
        try XCTAssertEqual(Self.count(code), 1)
    }
    
    final func testAssign2() throws {
        let code = """
        class AA {
            var a = 1
            func leak() {
                let aa = AA()
                escape {
                    let a = aa.a
                }
            }
        }
        """
        
        try XCTAssertEqual(Self.count(code), 1)
    }
}
