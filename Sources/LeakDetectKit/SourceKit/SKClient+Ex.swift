//
//  SKClient+Ex.swift
//
//
//  Created by Yume on 2023/8/31.
//

import Foundation
import SKClient
import SwiftSyntax

extension SKClient {
    func functionInfo(_ node: FunctionCallExprSyntax) -> FunctionInfo? {
        guard let functionName = node.calledExpression.tokenSyntax else { return nil }
        guard let cursorInfo = try? self(functionName) else { return nil }

        /// SKIP: SourceKit cursor fail
        if let diagnostic = cursorInfo.raw["key.internal_diagnostic"] as? String, !diagnostic.isEmpty {
            return nil
        }
        
        /// all objc callback is escape function?
        if let lang = cursorInfo.raw["key.decl_lang"] as? String, lang == "source.lang.objc" {
            return .init(client: self, cursorInfo: cursorInfo, isObjcFunction: true)
        }
        
        return .init(client: self, cursorInfo: cursorInfo, isObjcFunction: false)
    }

    struct FunctionInfo {
        let client: SKClient
        let cursorInfo: SourceKitResponse
        let isObjcFunction: Bool

        func isEscapeLast() -> Bool {
            if isObjcFunction { return true }
            
            let def = cursorInfo.annotated_decl_xml_value ?? ""
            let code = cursorInfo.typeusr_demangle ?? ""
            let isEscape =
                EscapingDetector.detectLast(code: code) ||
                EscapingDetector.detectLast(code: def)
            return isEscape
        }

        func isEscape(_ name: String) -> Bool {
            if isObjcFunction { return true }
            
            let def = cursorInfo.annotated_decl_xml_value ?? ""
            let code = cursorInfo.typeusr_demangle ?? ""
            let isEscape =
                EscapingDetector.detect(code: code, name: name) ||
                EscapingDetector.detect(code: def, name: name)
            return isEscape
        }
    }
}

extension SourceKitResponse {
    private var isTargetKind: Bool {
        switch kind {
        /// AAA.xxx()
        /// `xxx`
        case .refFunctionMethodStatic: fallthrough
        /// aaa.xxx()
        /// `xxx`
        case .refFunctionMethodInstance: fallthrough

        /// AAA.xxx
        /// `xxx`
        case .refVarStatic: fallthrough
        /// xxx
        /// `xxx`
        case .refVarGlobal: fallthrough
        /// Struct().xxx/Class().xxx
        case .refVarInstance: fallthrough

        /// let a = Enum.x
        /// `a`
        case .refEnum: fallthrough
        /// let a = Struct()
        /// `a`
        case .refStruct: fallthrough
        /// let a = Class()
        /// `a`
        case .refClass: fallthrough
        /// ???
        /// global function ?
        /// print
        case .refFunctionFree:
            return false
        default:
            return true
        }
    }

    func isLeak(_ startLoc: Int) -> Bool {
        /// is weak var / unowned var
        if isWeak {
            return false
        }
        /// is variable type is closure
        /// is skip type
        if isEscapeClosure || isSkipType {
            return false
        }
        guard isTargetKind else { return false }
        guard let offset = offset else { return false }
        return offset < startLoc
    }
    
    /// skip BuiltinType / Type / Struct
    private var isSkipType: Bool {
        if let type = self.typeusr_demangle {
            let isBuiltinType = builtinTypeList.contains(type)
            let isType = type.hasSuffix(".Type")
            let isStruct = (self.typeusr?.isStruct ?? false)
            let isSkip = isBuiltinType || isType || isStruct
            return isSkip
        }
        return false
    }
    
    private var isEscapeClosure: Bool {
        /// let handler: ErrorHandler?
        /// let action: @escaping (Element) -> Void
        let codeDefine = self.annotated_decl_xml_value ?? ""
        let type = self.typeusr_demangle ?? ""
        let isEscapeClosure =
            EscapingDetector.detect(code: codeDefine) ||
            EscapingDetector.detectWithTypeAlias(code: type)
        return isEscapeClosure
    }
  
    /// "weak var c: C?"
    /// "unowned var c: C"
    private var isWeak: Bool {
        let codeDefine = self.annotated_decl_xml_value ?? ""
        return WeakDetector.detect(code: codeDefine)
    }
}
