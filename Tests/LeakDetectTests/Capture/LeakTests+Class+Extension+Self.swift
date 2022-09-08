//
//  ClassEx_Self_LeakTests.swift
//  
//
//  Created by Yume on 2022/7/11.
//

import Foundation
import XCTest

final class ClassEx_Self_LeakTests: _LeakTests {}

// MARK: - class -
// MARK: Single self
extension ClassEx_Self_LeakTests {
    final func testNoLeak() throws {
        let code = """
        extension A {
            func leak() {
                nonescape {
                    print(self.a)
                }
            }
        }
        """
        
        try XCTAssertEqual(Self.count(code), 0)
    }
    
    final func testLeak() throws {
        let code = """
        extension A {
            func leak() {
                escape {
                    print(self.a)
                }
            }
        }
        """
        
        try XCTAssertEqual(Self.count(code), 1)
    }
}

// MARK: Nested self
extension ClassEx_Self_LeakTests {
    final func testNested1() throws {
        let code = """
        extension A {
            func leak() {
                escape {
                    print(self.a)
                    escape {
                        print(self.a)
                    }
                }
            }
        }
        """
        
        try XCTAssertEqual(Self.count(code), 2)
    }
    
    
    final func testNested2() throws {
        let code = """
        extension A {
            func leak() {
                nonescape {
                    print(self.a)
                    nonescape {
                        print(self.a)
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
        extension A {
            func leak() {
                escape {
                    print(self.a)
                    nonescape {
                        print(self.a)
                    }
                }
            }
        }
        """
        
        try XCTAssertEqual(Self.count(code), 1)
    }
    
    final func testNested4() throws {
        let code = """
        extension A {
            func leak() {
                nonescape {
                    print(self.a)
                    escape {
                        print(self.a)
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
        extension A {
            func leak() {
                escape {
                    escape { [weak self] in
                    }
                }
            }
        }
        """
        
        try XCTAssertEqual(Self.count(code), 0)
    }
}

// MARK: Single self assign
extension ClassEx_Self_LeakTests {
    final func testAssign1() throws {
        let code = """
        extension A {
            func leak() {
                escape {
                    self.a = 1
                }
            }
        }
        """
        
        try XCTAssertEqual(Self.count(code), 1)
    }
    
    final func testAssign2() throws {
        let code = """
        extension A {
            func leak() {
                escape {
                    let a = self.a
                }
            }
        }
        """
        
        try XCTAssertEqual(Self.count(code), 1)
    }
}
