//
//  CaptureListRewriteTests.swift
//  
//
//  Created by Yume on 2023/8/24.
//

import Foundation
import XCTest
import SwiftSyntaxParser
@testable import LeakDetectKit

final class CaptureListRewriteTests: _LeakTests {
    final func testWeak() throws {
        let code = """
        class Temp {
          func leak() {
            escape { [weak self] in
            }
          }
        }
        """
        let expectedCode = """
        class Temp {
          func leak() {
            escape { [weak self = self] in
            }
          }
        }
        """
        let root = try SyntaxParser.parse(source: code)
        
        let rewriter = CaptureListRewriter()
        let newCode = rewriter.visit(root).description
        
        XCTAssertEqual(newCode, expectedCode)
    }
    
    final func testNormal() throws {
        let code = """
        class Temp {
          func leak() {
            escape { [self] in
            }
          }
        }
        """
        let expectedCode = """
        class Temp {
          func leak() {
            escape { [self = self] in
            }
          }
        }
        """
        let root = try SyntaxParser.parse(source: code)
        
        let rewriter = CaptureListRewriter()
        let newCode = rewriter.visit(root).description
        
        XCTAssertEqual(newCode, expectedCode)
    }
    
    final func testUnowned() throws {
        let code = """
        class Temp {
          func leak() {
            escape { [unowned self] in
            }
          }
        }
        """
        let expectedCode = """
        class Temp {
          func leak() {
            escape { [unowned self = self] in
            }
          }
        }
        """
        let root = try SyntaxParser.parse(source: code)
        
        let rewriter = CaptureListRewriter()
        let newCode = rewriter.visit(root).description
        
        XCTAssertEqual(newCode, expectedCode)
    }
}

extension CaptureListRewriteTests {
    final func test1() throws {
        let code = """
        let (a, b, c) = (1, 2, 3)
        let d = { [a, b, c] in

        }
        """

        let source = try SyntaxParser.parse(source: code)
        let rewriter = CaptureListRewriter()
        let _ = rewriter.visit(source)

        XCTAssertEqual(rewriter.infos.count, 3)
        
        XCTAssertEqual(rewriter.infos[0].originSyntax.offset, 37)
        XCTAssertEqual(rewriter.infos[1].originSyntax.offset, 40)
        XCTAssertEqual(rewriter.infos[2].originSyntax.offset, 43)

        XCTAssertEqual(rewriter.infos[0].expression, 41)
        XCTAssertEqual(rewriter.infos[1].expression, 48)
        XCTAssertEqual(rewriter.infos[2].expression, 55)
    }
}

extension CaptureListRewriteTests {
    final func testNested() throws {
        let code = """
        extension C {
            func leak() {
                let c = C()
                escape {
                    escape { [weak c] in
                    }
                }
            }
        }
        """

        let (results, rewriter) = try Self.detect(code)
        XCTAssertEqual(results.count, 1)
        
        // 96 －> 100
        XCTAssertEqual(rewriter[100]?.offset, 96)
    }
}
