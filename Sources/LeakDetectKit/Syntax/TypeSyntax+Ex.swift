//
//  TypeSyntax+Ex.swift
//  
//
//  Created by Yume on 2022/5/13.
//

import Foundation
import SwiftSyntax

/// Int?
extension OptionalTypeSyntax {
    var type: TypeSyntax {
        wrappedType
    }
}

/// origin      "@escaping (@escaping (Int) -> ()) -> ()"
/// 
/// specifier   nil
/// attributes  "@escaping "
/// baseType    "(@escaping (Int) -> ()) -> ()"
extension AttributedTypeSyntax {
    var aaaa: Int {
//        attributes
        return 1
    }
}

///// X?
//if let wrapped: TypeSyntax = type.as(OptionalTypeSyntax.self)?.wrappedType {
//    return find(type: wrapped)
//}
//
///// @escaping Closure
//if let attrs: AttributeListSyntax = type.as(AttributedTypeSyntax.self)?.attributes {
//    self.walk(attrs)
//    return .skipChildren
//}
//
///// (Closure)
//if
//    let elements: TupleTypeElementListSyntax = type.as(TupleTypeSyntax.self)?.elements,
//    let _ = elements.first?.type.as(FunctionTypeSyntax.self),
//    elements.count == 1 {
//    self.isEscape = true
//    return .skipChildren
//}

//public struct ArrayTypeSyntax : SwiftSyntax.TypeSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct AttributedTypeSyntax : SwiftSyntax.TypeSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct ClassRestrictionTypeSyntax : SwiftSyntax.TypeSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct CompositionTypeSyntax : SwiftSyntax.TypeSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct DictionaryTypeSyntax : SwiftSyntax.TypeSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct FunctionTypeSyntax : SwiftSyntax.TypeSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct ImplicitlyUnwrappedOptionalTypeSyntax : SwiftSyntax.TypeSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct MetatypeTypeSyntax : SwiftSyntax.TypeSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct OptionalTypeSyntax : SwiftSyntax.TypeSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct SomeTypeSyntax : SwiftSyntax.TypeSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct TupleTypeSyntax : SwiftSyntax.TypeSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct TypeSyntax : SwiftSyntax.TypeSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct UnknownTypeSyntax : SwiftSyntax.TypeSyntaxProtocol, SwiftSyntax.SyntaxHashable {
