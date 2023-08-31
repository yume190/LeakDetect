//
//  String+Remove.swift
//  
//
//  Created by Yume on 2023/8/30.
//

import Foundation

public extension String {
    func removeSuffix(_ text: String) -> String {
        if self.hasSuffix(text) {
            return String(self.dropLast(text.count))
        } else {
            return self
        }
    }
    
    func removePrefix(_ text: String) -> String {
        if self.hasPrefix(text) {
            return String(self.dropFirst(text.count))
        } else {
            return self
        }
    }
}
