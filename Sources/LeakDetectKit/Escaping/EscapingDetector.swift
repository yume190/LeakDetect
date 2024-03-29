//
//  EscapingDetector.swift
//
//
//  Created by Yume on 2022/5/13.
//

import Foundation
import SwiftSyntax
import SwiftParser

public enum EscapingDetector {
    public static func detectWithTypeAlias(code: String) -> Bool {
        let target = "typealias A = \(code)"
        return detect(code: target)
    }

    public static func detect(code: String) -> Bool {
        let target: String = code
        let source: SourceFileSyntax = Parser.parse(source: target)
        let visitor = TypeEscapeVisitor(viewMode: .sourceAccurate)
        visitor.walk(source)
        return visitor.isEscape
    }

    public static func detect(type: TypeSyntax) -> Bool {
        let visitor = TypeEscapeVisitor(viewMode: .sourceAccurate)
        _ = visitor.find(type: type)
        return visitor.isEscape
    }

    private static func _detect(code: String) throws -> FunctionParameterListEscapeVisitor? {
        let target: String = code

        let source: SourceFileSyntax = Parser.parse(source: target)
        let visitor = FunctionParameterListEscapeVisitor(viewMode: .sourceAccurate)
        visitor.walk(source)
        return visitor
    }

    public static func detect(code: String, index: Int) -> Bool {
        return (try? _detect(code: code)?[index]) ?? false
    }
    
    public static func detect(code: String, name: String) -> Bool {
        return (try? _detect(code: code)?[name]) ?? false
    }

    public static func detectLast(code: String) -> Bool {
        return (try? _detect(code: code)?.escape.last) ?? false
    }
}
