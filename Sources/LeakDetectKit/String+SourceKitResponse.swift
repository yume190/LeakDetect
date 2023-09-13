//
//  String+SourceKitResponse.swift
//
//
//  Created by Yume on 2023/9/12.
//

import Foundation

extension String {
  /// input
  ///   (x1) -> (x2) -> (x3)
  /// output
  ///   [(x1), (x2), (x3)]
  func parseSourkitFunctionTypeName() -> [String] {
    var charsList: [[Character]] = []
    var chars: [Character] = []
    var counter = 0
    for char in self {
      chars.append(char)
      switch char {
      case "(":
        counter += 1
        if counter == 1 {
          chars = ["("]
        }
      case ")":
        counter -= 1
        if counter == 0 {
          charsList.append(chars)
          chars = []
        }
      default:
        break
      }
    }
    return charsList.map { chars in
      String(chars)
    }
  }

  func removeGeneric() -> String {
    var chars: [Character] = []
    var counter = 0
    for char in self {
      switch char {
      case "<":
        counter += 1
        continue
      case ">":
        counter -= 1
        if counter == 0 {
          continue
        }
        fallthrough
      default:
        if counter > 0 {
          continue
        }
      }
      chars.append(char)
    }
    return String(chars)
  }
}
