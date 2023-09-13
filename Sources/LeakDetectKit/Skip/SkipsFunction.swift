//
//  Skips.swift
//
//
//  Created by Yume on 2022/5/17.
//

import Foundation
import SKClient

public extension Skips {
  struct Module: Decodable {
    let module: String
    let types: [TargetType]?
  }

  struct TargetType: Decodable {
    public let name: String
    public let `static`: [String]?
    public let funcs: [String]?
    init(name: String, static: [String]? = nil, funcs: [String]? = nil) {
      self.name = name
      self.static = `static`
      self.funcs = funcs
    }
  }
}

public extension Skips {
  static let `default`: Skips = .init([
    Module(
      module: "Dispatch",
      types: [
        TargetType(
          name: "DispatchQueue",
          funcs: ["asyncAfter", "async"]
        )
      ]
    ),
    
    Module(
      module: "UIKit.UIView",
      types: [
        TargetType(
          name: "UIView",
          static: ["animate"]
        )
      ]
    )
  ])
}

public final class Skips {
  public let dict: [String: [String: Skips.TargetType]]
  public init(_ skips: [Skips.Module]) {
    let pairs: [(key: String, value: [String: Skips.TargetType])] = skips.map { skip in
      let innerPairs: [(key: String, value: Skips.TargetType)] = skip.types?.map { type in
        (type.name, type)
      } ?? []
      let dict: [String: Skips.TargetType] = .init(innerPairs, uniquingKeysWith: { l, _ in
        l
      })
      return (skip.module, dict)
    }
    self.dict = .init(pairs, uniquingKeysWith: { l, _ in
      l
    })
  }
  
  public final func isSkip(_ res: SourceKitResponse) -> Bool {
    let newRes = handleConstructor(res)
    guard
      let module = res.raw["key.modulename"] as? String,
      let baseType = parseFunctionBaseType(newRes),
      let functionName = parseFunctionName(newRes)
    else {
      return false
    }
    
    switch newRes.kind {
    case .refFunctionFree:
      return handleObjectFunc(module, "", functionName)
    case .refFunctionMethodInstance:
      return handleObjectFunc(module, baseType, functionName)
    case .refFunctionConstructor: fallthrough
    case .refFunctionMethodClass: fallthrough
    case .refFunctionMethodStatic:
      return handleStaticFunc(module, baseType, functionName)
    default:
      return false
    }
  }
  
  private func handleConstructor(_ res: SourceKitResponse) -> SourceKitResponse {
    if let res = res.secondary_symbols, res.kind == .refFunctionConstructor {
      return res
    }
    return res
  }
  
  /// input
  ///   async(group:qos:flags:execute:)
  ///   animate(withDuration:animations:)
  private final func parseFunctionName(_ res: SourceKitResponse) -> String? {
    guard let name = res.name else { return nil }
    return name.components(separatedBy: "(").first
  }
  
  /// input
  ///   obj function:    (DispatchQueue) -> (...) -> ()
  ///   static function: (UIView.Type) -> (Double, @escaping () -> ()) -> ()
  ///   global function: (@escaping () -> ()) -> ()
  ///
  ///   generic: <T> (G<T>.Type) -> () -> ()
  ///            <T, U> (G<T>.GG<U>.Type) -> () -> ()
  ///
  /// DispatchQueue -> DispatchQueue
  /// UIView.Type -> UIView
  /// G<T>.GG<U>.Type -> G.GG
  private final func parseFunctionBaseType(_ res: SourceKitResponse) -> String? {
    guard let name = res.typename else { return nil }
    let parts = name.parseSourkitFunctionTypeName()
    return parts.first?
      .removeGeneric()
      .replacingOccurrences(of: "(", with: "")
      .replacingOccurrences(of: ")", with: "")
      .removeSuffix(".Type")
  }
  
  /// input
  ///   DispatchQueue.main.async
  ///   key.typename -> (DispatchQueue) -> (...) -> ()
  ///   key.name     -> async(group:qos:flags:execute:)
  private final func handleObjectFunc(_ module: String, _ baseType: String, _ functionName: String) -> Bool {
    return dict[module]?[baseType]?.funcs?.contains(functionName) ?? false
  }
  
  /// input
  ///   UIView.animate
  ///   key.typename -> (UIView.Type) -> (Double, @escaping () -> ()) -> ()
  ///   key.name     -> animate(withDuration:animations:)
  private final func handleStaticFunc(_ module: String, _ baseType: String, _ functionName: String) -> Bool {
    return dict[module]?[baseType]?.static?.contains(functionName) ?? false
  }
}
