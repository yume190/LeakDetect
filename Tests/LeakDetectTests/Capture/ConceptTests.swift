//
//  ConceptTests.swift
//
//
//  Created by Yume on 2022/9/1.
//

import Foundation
import XCTest

private class Concept {
    typealias Callback = () -> Concept?
    private var cb: Callback?
    private var nest: Callback?
    
    func leak() -> Concept? {
        cb = {
            let nest = { [weak self] in
                self
            }
            return nest()
        }
        return cb?()
    }
    
    func noleak() -> Concept? {
        cb = { [weak self] in
            self?.nest = { [weak self] in
                self
            }
            return self?.nest?()
        }
        return cb?()
    }
    
    func captureWeak() -> Concept? {
        cb = { [weak self] in
            self?.nest = {
                self
            }
            return self?.nest?()
        }
        return cb?()
    }
    
    func captureStrong() -> Concept? {
        cb = { [weak self] in
            let `self`: Concept? = self
            self?.nest = {
                self
            }
            return self?.nest?()
        }
        return cb?()
    }
}

final class ConcepctTests: XCTestCase {
    private var concept: Concept? = nil
    private weak var _concept: Concept? = nil
    
    override func setUp() {
        super.setUp()
        concept = Concept()
        _concept = concept
    }
    
    override func tearDown() {
        concept = nil
        _concept = nil
        super.tearDown()
    }
    
    func testConceptNestedSpecial_noleak() {
        XCTAssertNotNil(concept?.noleak())
        XCTAssertNotNil(_concept)
        concept = nil
        XCTAssertNil(_concept)
    }
    
    func testConceptNestedSpecial_leak() {
        XCTAssertNotNil(concept?.leak())
        XCTAssertNotNil(_concept)
        concept = nil
        XCTAssertNotNil(_concept)
    }
    
    func testConceptNestedCaptureWeak() {
        XCTAssertNotNil(concept?.captureWeak())
        XCTAssertNotNil(_concept)
        concept = nil
        XCTAssertNil(_concept)
    }
    
    func testConceptNestedCaptureStrong() {
        XCTAssertNotNil(concept?.captureStrong())
        XCTAssertNotNil(_concept)
        concept = nil
        XCTAssertNotNil(_concept)
    }
}
