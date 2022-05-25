//
//  File.swift
//  
//
//  Created by Yume on 2022/5/20.
//

import Foundation

extension String {
    /// https://github.com/apple/swift/blob/main/docs/ABI/OldMangling.rst
    /// KNOWN-TYPE-KIND ::= 'V'                    // Swift.UnsafeRawPointer
    /// any-generic-type ::= context decl-name 'V'     // nominal struct type
    var isStruct: Bool {
        var number = ""
        var counter = 0
        var type = ""
        for c in self {
            /// Struct<X>
            if type == "Vy" {
                return true
            }
            
            /// Class<X>
            if type == "Cy" {
                return false
            }
            
            if counter > 0 {
                counter -= 1
                continue
            }
            
            if c.isNumber {
                number.append(c)
                continue
            }
            
            /// not a number
            /// word begin
            if number != "" {
                counter = Int(number) ?? 0
                number = ""
                if counter == 0 {
                    //
                } else {
                    counter -= 1
                    continue
                }
            }
            
            switch c {
            case "V": fallthrough
            case "C":
                type = ""
                fallthrough
            case "y":
                type.append(c)
                fallthrough
            default:
                continue
            }
        }
        return type == "V"
    }
}
