//
//  Decls+Detect.swift
//  
//
//  Created by Yume on 2022/5/23.
//

import Foundation
import SwiftSyntax
import Rainbow
import SKClient

extension DeclsVisitor {
    public func detect(_ client: SKClient, _ reporter: Reporter, _ isVerbose: Bool) throws -> Int {
        let all = self.leakVisitors
        
        var count = 0
        
        for v in all where !v.ids.isEmpty {
            let tokens = try v.detect(client)
                .filter(\.1)
                .map(\.0)
            guard !tokens.isEmpty else {continue}
            
            try tokens.forEach { token in
                let start = v.start?.withoutTrivia().description ?? "{"
                
                let function = v.function?.withoutTrivia().description ?? "nil"
                let functionOffset = v.function?.positionAfterSkippingLeadingTrivia.utf8Offset ?? -1
                let functionRes: SourceKitResponse? = functionOffset == -1 ? nil : try client(functionOffset)
                
                
                let loc = client(location: token)
                let c = try client(token.positionAfterSkippingLeadingTrivia.utf8Offset)
                reporter.report(loc)
                if isVerbose {
                    print("""
                        \("function:".lightBlue) \(function) \(functionOffset)
                        \("function usr demangle:".lightBlue) \(functionRes?.usr_demangle ?? "nil")
                        \("function typeusr demangle:".lightBlue) \(functionRes?.typeusr_demangle ?? "nil")
                        \("block.start at `\(start)`:".lightBlue) \(v.start?.positionAfterSkippingLeadingTrivia.utf8Offset ?? -1)
                        \("key.offset:".lightBlue) \(c.offset ?? -1)
                        \("token.offset:".lightBlue) \(token.positionAfterSkippingLeadingTrivia.utf8Offset)
                        \("is struct???:".lightBlue) \(c.typeusr?.isStruct ?? false)
                        \("type:".lightBlue) `\(c.typeusr_demangle ?? "")`
                        \("typeusr:".lightBlue) `\(c.typeusr ?? "")`
                        \("kind:".lightBlue) `\(c.kind?.rawValue ?? "")`
                    """)
                }

                count += 1
            }
        }
        return count
    }
}

extension LeakVisitor {
    public func detect(_ client: SKClient) throws -> [(IdentifierExprSyntax, Bool)] {
        guard let start = self.start else { return [] }
        let startLoc = start.positionAfterSkippingLeadingTrivia.utf8Offset
        var dict: [String: Bool] = [:]
        
        if let f = function?.withoutTrivia().description {
            if skipFunctionName.contains(f) {
    //                print("SKIP", f.description)
                return []
            }
        }
        
        if let functionName = function?.tokenSyntax {
            switch closureType {
            case .trailing:
                let _cur = try client(functionName)
                let def = _cur.annotated_decl_xml_value ?? ""
                let code = _cur.typeusr_demangle ?? ""
                let isEscape =
                    EscapingDetector.detectLast(code: code) ||
                    EscapingDetector.detectLast(code: def)
                if !isEscape {
    //                    print("SKIP NONESCAPING", functionName.withoutTrivia().description,  functionName.positionAfterSkippingLeadingTrivia.utf8Offset, isEscape)
                    return []
                }
            default:
                break
            }
        }
        
        var result: [(IdentifierExprSyntax, Bool)] = []
        
        for id in ids {
            if let b = dict[id.identifier.text] {
                result.append((id, b))
            } else {
                let _cur = try client(id.positionAfterSkippingLeadingTrivia.utf8Offset)
                
                let b: Bool
                switch _cur.kind {
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
                    b = false
                default:
                    guard let offset = _cur.offset else {
                        //print("\(id.identifier.text) 怪")
                        b = false
                        break
                    }
                    
                    b = offset < startLoc
                }
            
                
                /// let handler: ErrorHandler?
                /// let action: @escaping (Element) -> Void
                let codeDefine = _cur.annotated_decl_xml_value ?? ""
                let type = _cur.typeusr_demangle ?? ""
                let isEscapeClosure =
                    EscapingDetector.detect(code: codeDefine) ||
                    EscapingDetector.detectWithTypeAlias(code: type)
                if isEscapeClosure {
                    dict[id.identifier.text] = false
                    result.append((id, false))
                    continue
                }
                
                if let type = _cur.typeusr_demangle {
                    let isBuiltinType = builtinTypeList.contains(type)
                    let isType = type.hasSuffix(".Type")
                    let isStruct = (_cur.typeusr?.isStruct ?? false)
                    let isSkip = isBuiltinType || isType || isStruct
                    
                    if isSkip {
                        dict[id.identifier.text] = false
                        result.append((id, false))
                        continue
                    }
                }
                
    //                let r =
    //                    isEscapeClosure ||
    //                    b
                
                dict[id.identifier.text] = b
                result.append((id, b))
            }
        }
        
        return result
    }
}
