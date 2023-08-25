//
//  USR+Struct.swift
//  
//
//  Created by Yume on 2022/5/20.
//

import Foundation

extension String {
    /// https://github.com/apple/swift/blob/main/docs/ABI/Mangling.rst
    /// KNOWN-TYPE-KIND ::= 'V'                    // Swift.UnsafeRawPointer
    /// any-generic-type ::= context decl-name 'V'     // nominal struct type
    var isStruct: Bool {
        var number = ""
        var counter = 0
        var type = ""
        for c in self {
            if counter > 0 {
                /// number spacial case
                /// (maybe type is private)
                ///
                /// 10$10b8e41ccyXZ
                /// 10 $ 10b8e41ccyXZ
                if c == "$" {
                    counter = 0
                    continue
                }
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
                /// reset when met nested type
                /// A(struct).B(struct)
                /// usr: ....1AV2BV...
                /// A -> 1AV
                /// B -> 1BV
                type = ""
                
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
            case "V":
                type = "V"
            default:
                continue
            }
        }
        return type == "V"
    }
}
