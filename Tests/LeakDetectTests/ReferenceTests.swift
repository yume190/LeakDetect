//
//  ReferenceTests.swift
//
//
//  Created by Yume on 2022/5/30.
//

import Foundation
import HumanString
@testable import LeakDetectKit
@testable import SKClient
import XCTest

@inline(__always)
private func prepare(code: String, action: (SKClient) throws -> ()) throws {
    let client = try SKClient(code: code)
    try prepare(client: client, action: action)
}

@inline(__always)
private func prepare(client: SKClient, action: (SKClient) throws -> ()) throws {
    _ = try client.editorOpen()
    try action(client)
    _ = try client.editorClose()
}

final class ReferenceTests: XCTestCase {
    final func testSelf() throws {
        let code = """
        class A {
            var a: A {
                return self
            }
            
            func b() -> A {
                return self
            }
            
            lazy var c: A = {
                return self
            }()
        
            init() {}
        }
        """

        try prepare(code: code) { client in
            /// a
            try XCTAssertEqual(client(40).offset, 23)
            XCTAssertEqual(code[40...43], "self")
            XCTAssertEqual(code[23], "{")
            
            /// b
            try XCTAssertEqual(client(91).offset, 65)
            XCTAssertEqual(code[91...94], "self")
            XCTAssertEqual(code[65...72], "b() -> A")
            
            /// c
            try XCTAssertEqual(client(144).offset, 120)
            XCTAssertEqual(code[144...147], "self")
            XCTAssertEqual(code[120...123], "c: A")
        }
    }
    
    final func testCapture() throws {
        let code = """
        class A {
            func example()  {
                let a = A()
                let b: () -> () = { [aa = a, a, weak self, this = self] in
                    print(aa, a, self, this)
                }
            }
            
            init() {}
        }
        """

        /// reference of capture list
        try prepare(code: code) { client in
            /// aa = a, `a`
            try XCTAssertEqual(client(86).offset, 44)
            XCTAssertEqual(code[86], "a")
            XCTAssertEqual(code[44], "a")
            
            /// a, `a`
            try XCTAssertEqual(client(89).offset, 89)
            XCTAssertEqual(code[89], "a")
            
            /// weak self, `self`
            try XCTAssertEqual(client(97).offset, 97)
            XCTAssertEqual(code[97...100], "self")
            
            /// this = self, `self`
            try XCTAssertEqual(client(110).offset, 19)
            XCTAssertEqual(code[110...113], "self")
            XCTAssertEqual(code[19...25], "example")
        }
        
        /// reference to capture list
        try prepare(code: code) { client in
            /// aa
            try XCTAssertEqual(client(137).offset, 81)
            /// a
            try XCTAssertEqual(client(141).offset, 89)
            /// self
            try XCTAssertEqual(client(144).offset, 97)
            /// this
            try XCTAssertEqual(client(150).offset, 103)
        }
    }
    
    final func testNestedCapture() throws {
        let code = """
        class A {
            func example() {
                let a = A()
                let b: () -> () = {
                    print(a, self)
                    let c: () -> () = {
                        print(a, self)
                    }
                }
                print(a, self)
            }
        }
        """

        /// reference of capture list
        try prepare(code: code) { client in
            /// a
            try XCTAssertEqual(client(97).offset, 43)
            try XCTAssertEqual(client(160).offset, 43)
            try XCTAssertEqual(client(207).offset, 43)
            
            /// self
            try XCTAssertEqual(client(102).offset, 19)
            try XCTAssertEqual(client(165).offset, 19)
            try XCTAssertEqual(client(212).offset, 19)
        }
    }
    
    func testMultiFile() throws {
        /// let a = 1
        let file = resource(file: "Reference2.swift.data")
        let code = """
        func test() {
            print(a)
        }
        """
        let args = SDK.macosx.pathArgs + [
            file,
        ]

        let client = try SKClient(code: code, arguments: args)
        try prepare(client: client) { client in
            let res = try client(24)
            XCTAssertEqual(res.offset, 4)
            XCTAssertEqual(res.raw["key.filepath"] as? String, file)
        }
    }
}
