//
//  ExprSyntax+Ex.swift
//  
//
//  Created by Yume on 2022/5/13.
//

import Foundation
import SwiftSyntax

extension ExprSyntax {
    /// `a.b.c`/`a` -> `a`
    var firstBase: IdentifierExprSyntax? {
        switch self {
        case _ where self.is(MemberAccessExprSyntax.self):
            return self.as(MemberAccessExprSyntax.self)?.base?.firstBase
        case _ where self.is(IdentifierExprSyntax.self):
            return self.as(IdentifierExprSyntax.self)
        default:
            return nil
        }
    }
    
    
    /// `a.b.c`/`c` -> `c`
    var tokenSyntax: TokenSyntax? {
        return
            self.as(MemberAccessExprSyntax.self)?.tokenSyntax ??
            self.as(IdentifierExprSyntax.self)?.tokenSyntax
    }
}

extension MemberAccessExprSyntax {
    var tokenSyntax: TokenSyntax {
        self.name
    }
}

extension IdentifierExprSyntax {
    var tokenSyntax: TokenSyntax {
        self.identifier
    }
}

//public struct ArrayExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct ArrowExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct AsExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct AssignmentExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct AwaitExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct BinaryOperatorExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct BooleanLiteralExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct ClosureExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct DictionaryExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct DiscardAssignmentExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct EditorPlaceholderExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct ExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct FloatLiteralExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct ForcedValueExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct FunctionCallExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct IdentifierExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct InOutExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct IntegerLiteralExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct IsExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct KeyPathBaseExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct KeyPathExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct MemberAccessExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct NilLiteralExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct ObjcKeyPathExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct ObjcSelectorExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct ObjectLiteralExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct OptionalChainingExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct PostfixIfConfigExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct PostfixUnaryExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct PoundColumnExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct PoundDsohandleExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct PoundFileExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct PoundFileIDExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct PoundFilePathExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct PoundFunctionExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct PoundLineExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct PrefixOperatorExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct RegexLiteralExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct SequenceExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct SpecializeExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct StringLiteralExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct SubscriptExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct SuperRefExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct SymbolicReferenceExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct TernaryExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct TryExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct TupleExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct TypeExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct UnknownExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
//public struct UnresolvedPatternExprSyntax : SwiftSyntax.ExprSyntaxProtocol, SwiftSyntax.SyntaxHashable {
