//
//  WeakDetector.swift
//
//
//  Created by Yume on 2023/9/13.
//

import Foundation
@testable import LeakDetectKit
import XCTest

final class WeakDetectorTest: XCTestCase {
  func testWeak() throws {
    let code = "weak var c: Int?"
    XCTAssertTrue(WeakDetector.detect(code: code))
  }

  func testUnowned() throws {
    let code = "unowned var c: Int?"
    XCTAssertTrue(WeakDetector.detect(code: code))
  }

  func testStrong() throws {
    let code = "var c: Int?"
    XCTAssertFalse(WeakDetector.detect(code: code))
  }
}
