//
//  LeakTests+Normal.swift
//
//
//  Created by Yume on 2023/8/31.
//

import Foundation
import LeakDetectKit
import XCTest

final class Normal_LeakTests: _LeakTests {}

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
  
  final func testCaptureList3() throws {
    let code = """
    extension C {
      func test() {
        var a = C()
        var b = C()
        escape { [self, a = b] in
          escape { [a, b] in
            print(self, a, b)
          }
        }
      }
    }
    """
    #warning("wrong position, b:6:13 -> b:6:20")
    let expect = [
      "b:6:13",
      "self:7:15",
    ]
    let results = try Self.detect(code).1.map(\.testLocation)
    XCTAssertEqual(results, expect)
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

// MARK: - iOS

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
  
  /// Promise Like + Skip Func
  /// Promise Like:
  ///   withUnsafeContinuation
  ///   Observable.create
  final func testPromiseLikeWithSkipFunc() throws {
    let code = """
    import Foundation
    extension C {
      func test() {
        future { c in
          DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            print(c)
          }
        }
      }
      func future(_ callback: @escaping (C) -> Void) {
    
      }
    }
    """
  
    try XCTAssertEqual(Self.count(code, .iphoneos), 0)
  }
}
