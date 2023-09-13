//
//  File.swift
//
//
//  Created by Yume on 2023/9/13.
//

import Dispatch
import Foundation
import HumanString
@testable import LeakDetectKit
@testable import SKClient
import XCTest

final class SkipConceptTests: XCTestCase {
  final func testObjFunction() throws {
    let code = """
    A().a()
    struct A {
      func a() {}
    }
    """

    let client = SKClient(code: code, arguments: SDK.macosx.args)
    try prepare(client: client) { client in
      let res = try client(4)
      XCTAssertEqual(code[4 ... 6], "a()")
      
      XCTAssertEqual(res.name, "a()")
      XCTAssertEqual(res.typename, "(A) -> () -> ()")
      XCTAssertEqual(res.kind, .refFunctionMethodInstance)
    }
  }

  private func a(_ type: Any.Type) -> () -> () {
    return {}
  }

  private func temp() {
    let _ = a(Int.self)
  }

  final func testFunctionReturnClosure() throws {
    let code = """
    let x = a(Int.self)
    func a(_ type: Any.Type) -> () -> () {
      return {}
    }
    """

    let client = SKClient(code: code, arguments: SDK.macosx.args)
    try prepare(client: client) { client in
      let res = try client(8)
      XCTAssertEqual(code[8 ... 18], "a(Int.self)")
      
      XCTAssertEqual(res.name, "a(_:)")
      XCTAssertEqual(res.typename, "(Any.Type) -> () -> ()")
      XCTAssertEqual(res.kind, .refFunctionFree)
    }
  }
  
  final func testGenericFunction() throws {
    let code = """
    a(t: 1)
    func a<T>(t: T) {}
    """

    let client = SKClient(code: code, arguments: SDK.macosx.args)
    try prepare(client: client) { client in
      let res = try client(0)
      XCTAssertEqual(code[0 ... 6], "a(t: 1)")
      
      XCTAssertEqual(res.name, "a(t:)")
      XCTAssertEqual(res.typename, "<T> (t: T) -> ()")
      XCTAssertEqual(res.kind, .refFunctionFree)
    }
  }
  
  final func testStaticFunction() throws {
    let code = """
    A.a()
    struct A {
      static func a() {}
    }
    """

    let client = SKClient(code: code, arguments: SDK.macosx.args)
    try prepare(client: client) { client in
      let res = try client(2)
      XCTAssertEqual(code[2 ... 4], "a()")
      
      XCTAssertEqual(res.name, "a()")
      XCTAssertEqual(res.typename, "(A.Type) -> () -> ()")
      XCTAssertEqual(res.kind, .refFunctionMethodStatic)
    }
  }
  
  final func testGenericNestedType() throws {
    let code = """
    A<Int>.B<Int>.a(1)
    struct A<T> {
      struct B<U> {
        static func a<V>(_ v: V) {}
      }
    }
    """

    let client = SKClient(code: code, arguments: SDK.macosx.args)
    try prepare(client: client) { client in
      let res = try client(14)
      XCTAssertEqual(code[0 ... 17], "A<Int>.B<Int>.a(1)")
      
      XCTAssertEqual(res.name, "a(_:)")
      XCTAssertEqual(res.typename, "<T, U, V> (A<T>.B<U>.Type) -> (V) -> ()")
      XCTAssertEqual(res.kind, .refFunctionMethodStatic)
    }
  }
  
  
  final func testConstructor() throws {
    let code = """
    A()
    struct A {}
    """

    let client = SKClient(code: code, arguments: SDK.macosx.args)
    try prepare(client: client) { client in
      let res = try client(0)
      XCTAssertEqual(code[0 ... 2], "A()")
      
      XCTAssertEqual(res.secondary_symbols?.name, "init()")
      XCTAssertEqual(res.secondary_symbols?.typename, "(A.Type) -> () -> A")
      XCTAssertEqual(res.secondary_symbols?.kind, .refFunctionConstructor)
    }
  }
}
