//
//  NewTests.swift
//  
//
//  Created by Yume on 2022/5/13.
//

import Foundation
import XCTest
@testable import SKClient
@testable import LeakDetectKit

final class NewTests: XCTestCase {
    
    private lazy var path: String = resource(file: "Cursor.swift.data")
    private lazy var cursor = try! SKClient(path: path)

    func testNormal() throws {
        let client = try SKClient(path: path)
//        _ = try startDetect(client, Reporter.xcode)
//        let visitor = LeakVisitor()
//        visitor.walk(cursor.sourceFile)
//
//        let all = visitor.subVisitors
//        for v in all where !v.ids.isEmpty {
//            let tokens = try v.detect(cursor)
//                .filter(\.1)
//                .map(\.0)
//            guard !tokens.isEmpty else {continue}
//
//            print("-----start \(v.start?.position.utf8Offset ?? -1)")
//            print(v.start?.description ?? "nil")
//            tokens.forEach { token in
//                let text = token.identifier.text
//                let loc = cursor(location: token)
//                print("\(loc) \(text)")
//            }
//            print("-----end\n")
//        }
    }
}
