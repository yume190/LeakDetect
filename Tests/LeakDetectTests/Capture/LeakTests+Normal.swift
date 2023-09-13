//
//  LeakTests+Normal.swift
//
//
//  Created by Yume on 2023/8/31.
//

import Foundation
import XCTest

final class Normal_LeakTests: _LeakTests {}

// MARK: - No Leak

extension Normal_LeakTests {
  final func testWhenCaptureWeak() throws {
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

  final func testWhenCaptureUnowned() throws {
    let code = """
    extension C {
        func test() {
            unowned var ws = self
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
  
  final func testCaptureList1() throws {
    let code = """
    extension C {
        func test() {
            escape { [weak self] in
            }
        }
    }
    """
    
    try XCTAssertEqual(Self.count(code), 0)
  }
  
  final func testCaptureList2() throws {
    let code = """
    extension C {
        func test() {
            escape { [weak self = self] in
            }
        }
    }
    """
    
    try XCTAssertEqual(Self.count(code), 0)
  }
}
  
// MARK: - Skips

extension Normal_LeakTests {
  final func testSkip1() throws {
    DispatchQueue.main.async {
      print(self)
    }
    let code = """
    import Foundation
    extension C {
        func test() {
            DispatchQueue.main.async {
                print(self)
            }
        }
    }
    """
    
    try XCTAssertEqual(Self.count(code, .iphoneos), 0)
  }
  
  final func testSkip2() throws {
    DispatchQueue.main.async {
      print(self)
    }
    let code = """
    import UIKit
    extension C {
        func test() {
            UIView.animate(withDuration: 1) {
                print(self)
            }
        }
    }
    """
    
    try XCTAssertEqual(Self.count(code, .iphoneos), 0)
  }
}

extension Normal_LeakTests {
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
