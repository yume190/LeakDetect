//
//  CaptureRewriterTests.swift
//
//
//  Created by Yume on 2023/5/3.
//

@testable import LeakDetectKit
@testable import SKClient
import SwiftSyntaxParser
import XCTest

final class CaptureRewriterTests: XCTestCase {
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

        XCTAssertEqual(rewriter.infos[0].expresion, 41)
        XCTAssertEqual(rewriter.infos[1].expresion, 48)
        XCTAssertEqual(rewriter.infos[2].expresion, 55)
    }
}

final class RewriterLeakTests: _LeakTests {
    final func testNested() throws {
        let code = """
        extension A {
            func leak() {
                let a = A()
                escape {
                    escape { [weak a] in
                    }
                }
            }
        }
        """

        let source = try SyntaxParser.parse(source: code)
        let rewriter = CaptureListRewriter()
        let newSource = rewriter.visit(source)
        let newCode = newSource.description
        
        let ids = try Self.detect(newCode)
        XCTAssertEqual(ids.count, 1)
        
        // 96 －> 100
        XCTAssertEqual(ids.first?.offset, 100)
        
        let info = rewriter.infos.filter { info in
            info.expresion == 100
        }
        XCTAssertEqual(info.first?.originSyntax.offset, 96)
    }
}
