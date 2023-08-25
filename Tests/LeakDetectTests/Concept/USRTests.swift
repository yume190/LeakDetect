//
//  USRTests.swift
//
//
//  Created by Yume on 2022/5/23.
//

import Foundation
@testable import LeakDetectKit
@testable import SKClient
import XCTest

@_silgen_name("swift_getMangledTypeName")
private func _getMangledTypeName(_ type: Any.Type)
    -> (UnsafePointer<UInt8>, Int)

private func getMangledTypeName(_ type: Any.Type) -> String {
    let (pointer, _) = _getMangledTypeName(type)
    return String(cString: pointer)
}

private enum E {
    fileprivate enum E {}

    fileprivate struct S {}

    fileprivate class C {}

    fileprivate enum EG<T> {}

    fileprivate struct SG<T> {}

    fileprivate class CG<T> {}
}

private struct S {
    fileprivate enum E {}

    fileprivate struct S {}

    fileprivate class C {}

    fileprivate enum EG<T> {}

    fileprivate struct SG<T> {}

    fileprivate class CG<T> {}
}

private class C {
    fileprivate enum E {}

    fileprivate struct S {}

    fileprivate class C {}

    fileprivate enum EG<T> {}

    fileprivate struct SG<T> {}

    fileprivate class CG<T> {}
}

private enum EG<T> {
    fileprivate enum E {}

    fileprivate struct S {}

    fileprivate class C {}

    fileprivate enum EG<T> {}

    fileprivate struct SG<T> {}

    fileprivate class CG<T> {}
}

private struct SG<T> {
    fileprivate enum E {}

    fileprivate struct S {}

    fileprivate class C {}

    fileprivate enum EG<T> {}

    fileprivate struct SG<T> {}

    fileprivate class CG<T> {}
}

private class CG<T> {
    fileprivate enum E {}

    fileprivate struct S {}

    fileprivate class C {}

    fileprivate enum EG<T> {}

    fileprivate struct SG<T> {}

    fileprivate class CG<T> {}
}

final class USRTests: XCTestCase {
    private final func isStruct(_ type: Any.Type) -> Bool {
        getMangledTypeName(type).isStruct
    }
    
    final func testAll() throws {
        XCTAssertEqual(isStruct(S.self), true)
        XCTAssertEqual(isStruct(E.self), false)
        XCTAssertEqual(isStruct(C.self), false)
        
        XCTAssertEqual(isStruct(SG<Void>.self), true)
        XCTAssertEqual(isStruct(EG<Void>.self), false)
        XCTAssertEqual(isStruct(CG<Void>.self), false)
        
        // S
        XCTAssertEqual(isStruct(S.S.self), true)
        XCTAssertEqual(isStruct(S.E.self), false)
        XCTAssertEqual(isStruct(S.C.self), false)
        
        XCTAssertEqual(isStruct(S.SG<Void>.self), true)
        XCTAssertEqual(isStruct(S.EG<Void>.self), false)
        XCTAssertEqual(isStruct(S.CG<Void>.self), false)
        
        // C
        XCTAssertEqual(isStruct(C.S.self), true)
        XCTAssertEqual(isStruct(C.E.self), false)
        XCTAssertEqual(isStruct(C.C.self), false)
        
        XCTAssertEqual(isStruct(C.SG<Void>.self), true)
        XCTAssertEqual(isStruct(C.EG<Void>.self), false)
        XCTAssertEqual(isStruct(C.CG<Void>.self), false)
        
        // E
        XCTAssertEqual(isStruct(E.S.self), true)
        XCTAssertEqual(isStruct(E.E.self), false)
        XCTAssertEqual(isStruct(E.C.self), false)
        
        XCTAssertEqual(isStruct(E.SG<Void>.self), true)
        XCTAssertEqual(isStruct(E.EG<Void>.self), false)
        XCTAssertEqual(isStruct(E.CG<Void>.self), false)
        
        // SG
        XCTAssertEqual(isStruct(SG<Void>.S.self), true)
        XCTAssertEqual(isStruct(SG<Void>.E.self), false)
        XCTAssertEqual(isStruct(SG<Void>.C.self), false)
        
        XCTAssertEqual(isStruct(SG<Void>.SG<Void>.self), true)
        XCTAssertEqual(isStruct(SG<Void>.EG<Void>.self), false)
        XCTAssertEqual(isStruct(SG<Void>.CG<Void>.self), false)
        
        // CG
        XCTAssertEqual(isStruct(CG<Void>.S.self), true)
        XCTAssertEqual(isStruct(CG<Void>.E.self), false)
        XCTAssertEqual(isStruct(CG<Void>.C.self), false)
        
        XCTAssertEqual(isStruct(CG<Void>.SG<Void>.self), true)
        XCTAssertEqual(isStruct(CG<Void>.EG<Void>.self), false)
        XCTAssertEqual(isStruct(CG<Void>.CG<Void>.self), false)
        
        // EG
        XCTAssertEqual(isStruct(EG<Void>.S.self), true)
        XCTAssertEqual(isStruct(EG<Void>.E.self), false)
        XCTAssertEqual(isStruct(EG<Void>.C.self), false)
        
        XCTAssertEqual(isStruct(EG<Void>.SG<Void>.self), true)
        XCTAssertEqual(isStruct(EG<Void>.EG<Void>.self), false)
        XCTAssertEqual(isStruct(EG<Void>.CG<Void>.self), false)
    }
}
