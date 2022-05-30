//
//  FunctionParameterListEscapeTests.swift
//  TypeFillTests
//
//  Created by Yume on 2021/10/19.
//

import Foundation
import XCTest
@testable import SKClient
@testable import LeakDetectKit

final class FunctionParameterListEscapeTests: XCTestCase {
    private typealias C = (@escaping (@escaping (Int) -> ()) -> (), Int) -> ()
    private typealias B = (((@escaping (Int) -> ()) -> ()), Int) -> ()
    private let normal = "(@escaping (@escaping (Int) -> ()) -> (), Int) -> ()"
    private let parenthesis = "(((@escaping (Int) -> ()) -> ()), Int) -> ()"
    
    private let a = """
    @inlinable func map<T>(_ transform: @escaping (Element) throws -> T) rethrows -> [T]")
    """
    private let b = """
    @inlinable func map<T>(_ transform: (Element) throws -> T) rethrows -> [T]")
    """
        
    func testNormal0() throws {
        let target = self.normal
        XCTAssertTrue(EscapingDetector.detect(code: target, index: 0))
    }
    
    func testNormal1() throws {
        let target = self.normal
        XCTAssertFalse(EscapingDetector.detect(code: target, index: 1))
    }
    
    func testParenthesis0() throws {
        let target = self.parenthesis
        XCTAssertTrue(EscapingDetector.detect(code: target, index: 0))
    }
    
    func testParenthesis1() throws {
        let target = self.parenthesis
        XCTAssertFalse(EscapingDetector.detect(code: target, index: 1))
    }
    
    func testNew1() throws {
        let target = self.a
        XCTAssertTrue(EscapingDetector.detect(code: target, index: 0))
    }
    
    func testNew2() throws {
        let target = self.b
        XCTAssertFalse(EscapingDetector.detect(code: target, index: 0))
    }
}
