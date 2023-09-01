//
//  LeakTests+Normal.swift
//  
//
//  Created by Yume on 2023/8/31.
//

import Foundation
import XCTest

final class Normal_LeakTests: _LeakTests {}

extension Normal_LeakTests {
    final func testNoLeak_WhenCaptureWeak() throws {
        let code = """
        extension C {
            func test() {
                weak var ws = self
                escape {
                    print(ws)
                    escape {
                        print(ws)
                    }
                }
            }
        }
        """
        
        try XCTAssertEqual(Self.count(code), 0)
    }
    
    final func testLeak2_ObjcClosure() throws {
        let code = """
        import UIKit
        
        extension C {
            func test() {
                let anim = UIViewPropertyAnimator(duration: 2.0, curve: .linear) {
                    print(self.a)
                }
                anim.addCompletion { _ in
                    print(self.a)
                }
                anim.startAnimation()
            }
        }
        """
        
        try XCTAssertEqual(Self.count(code, .iphoneos), 2)
    }
}
