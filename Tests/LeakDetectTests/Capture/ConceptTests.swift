//
//  ConceptTests.swift
//
//
//  Created by Yume on 2022/9/1.
//


import Foundation
import XCTest

fileprivate class Concept {
    typealias Callback = () -> Concept?
    private var cb: Callback? = nil
    private var nest: Callback? = nil
    
    func leak() -> Concept? {
        self.cb = {
            let nest = { [weak self] in
                return self
            }
            return nest()
        }
        return self.cb?()
    }
    
    func noleak() -> Concept? {
        self.cb = { [weak self] in
            self?.nest = { [weak self] in
                return self
            }
            return self?.nest?()
        }
        return self.cb?()
    }
    
    func captureWeak() -> Concept? {
        self.cb = { [weak self] in
            self?.nest = {
                return self
            }
            return self?.nest?()
        }
        return self.cb?()
    }
    
    func captureStrong() -> Concept? {
        self.cb = { [weak self] in
            let `self`: Concept? = self
            self?.nest = {
                return self
            }
            return self?.nest?()
        }
        return self.cb?()
    }
}


final class ConcepctTests: XCTestCase {
    private var concept: Concept? = nil
    private weak var _concept: Concept? = nil
    
    override func setUp() {
        super.setUp()
        self.concept = Concept()
        self._concept = self.concept
    }
    
    override func tearDown() {
        self.concept = nil
        self._concept = nil
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
