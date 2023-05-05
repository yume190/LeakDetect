//
//  CaptureRewriter.swift
//
//
//  Created by Yume on 2023/5/3.
//

import Foundation
import SwiftSyntax

final class CaptureRewriter: SyntaxRewriter {
    struct Info {
        let originSyntax: SyntaxProtocol
        let expresion: Int
    }

    private(set) var infos: [Info] = []
    private var offset = 0

    /// specifier name assignToken expression
    /// weak      a    =           a
    ///                            a
    override func visit(_ node: ClosureCaptureItemSyntax) -> ClosureCaptureItemSyntax {
        guard node.name == nil, node.assignToken == nil else {
            return node
        }

        guard let name = node.expression.as(IdentifierExprSyntax.self)?.identifier else {
            return node
        }

        let origin = name.offset
        let nameSize = name.byteSizeAfterTrimmingTrivia
        let newOffset = 3 + nameSize

        infos.append(.init(
            originSyntax: name,
            expresion: origin + offset + newOffset))

        offset += newOffset

        return node
            .withName(name.withoutTrivia())
            .withAssignToken(TokenSyntax.equalToken(leadingTrivia: .space, trailingTrivia: .space))
    }
}
