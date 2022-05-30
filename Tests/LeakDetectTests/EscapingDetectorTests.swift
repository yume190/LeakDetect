//
//  EscapingDetectorTests.swift
//  TypeFillTests
//
//  Created by Yume on 2021/10/19.
//

import Foundation
import XCTest
@testable import SKClient
@testable import LeakDetectKit

typealias Complete = () -> Void

final class EscapingDetectorTests: XCTestCase {
    
    private let normal = "@escaping () -> Void"
    private let parenthesis = "(() -> Void)"
    private let parenthesisOption = "(() -> Void)?"
    private let other = "Int"
    
    func testNormal() throws {
        let target = self.normal
        XCTAssertTrue(EscapingDetector.detectWithTypeAlias(code: target))
    }
    
    func testParenthesis() throws {
        let target = self.parenthesis
        XCTAssertTrue(EscapingDetector.detectWithTypeAlias(code: target))
    }
    
    func testParenthesisOption() throws {
        let target = self.parenthesisOption
        XCTAssertTrue(EscapingDetector.detectWithTypeAlias(code: target))
    }
    
    func testOther() throws {
        let target = self.other
        XCTAssertFalse(EscapingDetector.detectWithTypeAlias(code: target))
    }
    
    func testNew() throws {
        let target = "let action: @escaping () -> Void"
        XCTAssertTrue(EscapingDetector.detect(code: target))
    }
    
    func testNew2() throws {
        let target = "Swift.Optional<(Swift.Error) -> ()>"
        XCTAssertTrue(EscapingDetector.detectWithTypeAlias(code: target))
    }
    
    func testNew2_2() throws {
        let target = "((Swift.Error) -> ())?"
        XCTAssertTrue(EscapingDetector.detectWithTypeAlias(code: target))
    }
}
