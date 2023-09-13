//
//  SourceKitResponseStringTests.swift
//
//
//  Created by Yume on 2023/9/12.
//

import Foundation
@testable import LeakDetectKit
import XCTest

final class SourceKitResponseStringTests: XCTestCase {
  func testFunctionTypeName0() {
    let code = "(DispatchQueue) -> (DispatchGroup?, DispatchQoS, DispatchWorkItemFlags, @escaping @convention(block) () -> ()) -> ()"
    XCTAssertEqual(code.parseSourkitFunctionTypeName().first, "(DispatchQueue)")
  }
  
  func testFunctionTypeName1() {
    let code = "(UIView.Type) -> (Double, @escaping () -> ()) -> ()"
    XCTAssertEqual(code.parseSourkitFunctionTypeName().first, "(UIView.Type)")
  }
  
  func testFunctionTypeName2() {
    let code = "(@escaping () -> ()) -> ()"
    XCTAssertEqual(code.parseSourkitFunctionTypeName().count, 2)
  }
  
  func testFunctionTypeName3() {
    let code = "<T> (G<T>.Type) -> () -> ()"
    XCTAssertEqual(code.parseSourkitFunctionTypeName().first, "(G<T>.Type)")
  }
  
  func testFunctionTypeName4() {
    let code = "<T, U> (G<T>.GG<U>.Type) -> () -> ()"
    XCTAssertEqual(code.parseSourkitFunctionTypeName().first, "(G<T>.GG<U>.Type)")
  }
  
  func testRemoveGeneric0() {
    let code = "G<T>.Type"
    XCTAssertEqual(code.removeGeneric(), "G.Type")
  }
  
  func testRemoveGeneric1() {
    let code = "G<T>.GG<U>.Type"
    XCTAssertEqual(code.removeGeneric(), "G.GG.Type")
  }
  
  func testRemoveGeneric2() {
    let code = "Array<Array<Int>>"
    XCTAssertEqual(code.removeGeneric(), "Array")
  }
}
