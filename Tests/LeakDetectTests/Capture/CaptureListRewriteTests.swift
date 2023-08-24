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

final class CaptureListRewriteTests: XCTestCase {
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
