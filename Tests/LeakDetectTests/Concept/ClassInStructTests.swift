//
//  ClassInStructTests.swift
//  
//
//  Created by Yume on 2023/8/25.
//

import Foundation
import XCTest

final class ClassInStructTests: XCTestCase {
    fileprivate typealias Callback = () -> S?
    fileprivate class C {}
    fileprivate struct S {
        let c: C
        init(_ c: C) {
            self.c = c
        }
    }
    
    func testLeak() {
        var c: C? = C()
        let s: S? = S(c!)
        weak var wc: C? = c
        let cb: Callback? = {
            s
        }
        
        XCTAssertNotNil(cb)
        XCTAssertNotNil(s)
        XCTAssertNotNil(c)
        c = nil
        XCTAssertNotNil(wc)
    }
}
