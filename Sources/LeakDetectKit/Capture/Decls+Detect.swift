//
//  Decls+Detect.swift
//
//
//  Created by Yume on 2022/5/23.
//

import Foundation
import Rainbow
import SKClient
import SwiftSyntax

public extension DeclsVisitor {
    func detectCount(_ client: SKClient, _ reporter: Reporter, _ isVerbose: Bool) throws -> Int {
        try detect(client, reporter, isVerbose).count
    }
    
    func detect(_ client: SKClient, _ reporter: Reporter, _ isVerbose: Bool) throws -> [IdentifierExprSyntax] {
        let all = leakVisitors

        var ids: [IdentifierExprSyntax] = []

        for visitor in all where !visitor.closureCaptureIDs.isEmpty {
            for id in visitor.closureCaptureIDs {
                let isLeak = try visitor.detectSingle(client, isVerbose, id)
                
                if isLeak {
                    ids.append(id)
                }
            }
        }

        for visitor in all where !visitor.ids.isEmpty {
            let tokens = try visitor.detect(client, isVerbose)
                .filter(\.isLeak)
                .map(\.id)
            guard !tokens.isEmpty else { continue }

            try tokens.forEach { token in
                let start = visitor.start?.withoutTrivia().description ?? "{"

                let function = visitor.function?.withoutTrivia().description ?? "nil"
                let functionOffset = visitor.function?.offset ?? -1
                let functionRes: SourceKitResponse? = functionOffset == -1 ? nil : try client(functionOffset)

                let loc = client(location: token)
                let c = try client(token.offset)
                reporter.report(loc)
                if isVerbose {
                    print("""
                        \("function:".lightBlue) \(function) \(functionOffset)
                        \("function usr demangle:".lightBlue) \(functionRes?.usr_demangle ?? "nil")
                        \("function typeusr demangle:".lightBlue) \(functionRes?.typeusr_demangle ?? "nil")
                        \("block.start at `\(start)`:".lightBlue) \(visitor.start?.offset ?? -1)
                        \("key.offset:".lightBlue) \(c.offset ?? -1)
                        \("token.offset:".lightBlue) \(token.offset)
                        \("is struct???:".lightBlue) \(c.typeusr?.isStruct ?? false)
                        \("type:".lightBlue) `\(c.typeusr_demangle ?? "")`
                        \("typeusr:".lightBlue) `\(c.typeusr ?? "")`
                        \("kind:".lightBlue) `\(c.kind?.rawValue ?? "")`
                    """)
                }

                ids.append(token)
            }
        }
        return ids
    }
}

extension LeakVisitor {
    private func skipFunction(_ isVerbose: Bool) -> Bool {
        guard
            let functionName = function?.withoutTrivia().description,
            skipFunctionName.contains(functionName)
        else {
            return true
        }

        if isVerbose { print("SKIP Function: ", functionName) }
        return false
    }

    private func skipNonEscaping(_ client: SKClient, _ isVerbose: Bool) throws -> Bool {
        if let functionName = function?.tokenSyntax {
            switch closureType {
            case .trailing:
                let cursorInfo = try client(functionName)

                /// all objc callback is escape function?
                if let lang = cursorInfo.raw["key.decl_lang"] as? String, lang == "source.lang.objc" {
                    break
                }

                /// SKIP: SourceKit cursor fail
                if let diagnostic = cursorInfo.raw["key.internal_diagnostic"] as? String, !diagnostic.isEmpty {
                    break
                }

                let def = cursorInfo.annotated_decl_xml_value ?? ""
                let code = cursorInfo.typeusr_demangle ?? ""
                let isEscape =
                    EscapingDetector.detectLast(code: code) ||
                    EscapingDetector.detectLast(code: def)
                if !isEscape {
                    if isVerbose { print("SKIP Non Escape: ", functionName.withoutTrivia().description) }
                    return false
                }
            default:
                break
            }
        }
        return true
    }

    private func isLeak(_ cursorInfo: SourceKitResponse, _ isUseCurrentStart: Bool = true) -> Bool {
        let targetStart = isUseCurrentStart ? start : parentVisitor?.start
        guard let start = targetStart else { return false }
        let startLoc = start.offset

        switch cursorInfo.kind {
        /// AAA.xxx()
        case .refFunctionMethodStatic: fallthrough
        /// aaa.xxx()
        case .refFunctionMethodInstance: fallthrough

        /// AAA.xxx
        case .refVarStatic: fallthrough
        /// xxx
        case .refVarGlobal: fallthrough
        /// Struct().xxx/Class().xxx
        case .refVarInstance: fallthrough

        /// Enum()
        case .refEnum: fallthrough
        /// Struct()
        case .refStruct: fallthrough
        /// Class()
        case .refClass: fallthrough
        /// ???
        /// print
        case .refFunctionFree:
            return false
        default:
            guard let offset = cursorInfo.offset else {
                // print("\(id.identifier.text) 怪")
                return false
            }

            return offset < startLoc
        }
    }

    private func isEscapeClosure(_ cursorInfo: SourceKitResponse) -> Bool {
        /// let handler: ErrorHandler?
        /// let action: @escaping (Element) -> Void
        let codeDefine = cursorInfo.annotated_decl_xml_value ?? ""
        let type = cursorInfo.typeusr_demangle ?? ""
        let isEscapeClosure =
            EscapingDetector.detect(code: codeDefine) ||
            EscapingDetector.detectWithTypeAlias(code: type)
        return isEscapeClosure
    }

    /// skip BuiltinType / Type / Struct
    private func isSkipType(_ cursorInfo: SourceKitResponse) -> Bool {
        if let type = cursorInfo.typeusr_demangle {
            let isBuiltinType = builtinTypeList.contains(type)
            let isType = type.hasSuffix(".Type")
            let isStruct = (cursorInfo.typeusr?.isStruct ?? false)
            let isSkip = isBuiltinType || isType || isStruct
            return isSkip
        }
        return false
    }

    public func detect(_ client: SKClient, _ isVerbose: Bool) throws -> [(id: IdentifierExprSyntax, isLeak: Bool)] {
        guard skipFunction(isVerbose) else { return [] }
        guard try skipNonEscaping(client, isVerbose) else { return [] }

        var dict: [String: Bool] = [:]
        var result: [(IdentifierExprSyntax, Bool)] = []

        for id in ids {
            if let isLeak = dict[id.identifier.text] {
                result.append((id, isLeak))
            } else {
                let cursorInfo = try client(id.offset)

                if isEscapeClosure(cursorInfo) || isSkipType(cursorInfo) {
                    dict[id.identifier.text] = false
                    result.append((id, false))
                    continue
                }

                let isLeak = isLeak(cursorInfo)
                dict[id.identifier.text] = isLeak
                result.append((id, isLeak))
            }
        }

        return result
    }

    public func detectSingle(_ client: SKClient, _ isVerbose: Bool, _ id: IdentifierExprSyntax) throws -> Bool {
        guard skipFunction(isVerbose) else { return false }
        guard try skipNonEscaping(client, isVerbose) else { return false }

        let cursorInfo = try client(id.offset)

        if isEscapeClosure(cursorInfo) || isSkipType(cursorInfo) {
            return false
        }

        return isLeak(cursorInfo, false)
    }
}
