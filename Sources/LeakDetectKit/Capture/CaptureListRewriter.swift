//
//  CaptureListRewriter.swift
//
//
//  Created by Yume on 2023/5/3.
//

import Foundation
import SwiftSyntax

final public class CaptureListRewriter: SyntaxRewriter {
    struct Info {
        let originSyntax: TokenSyntax
        let expression: Int
    }
  
    subscript(offset: Int) -> TokenSyntax? {
        infos.first { info in
            info.expression == offset
        }?.originSyntax
    }

    private(set) var infos: [Info] = []
    private var offset = 0

    /// specifier name assignToken expression
    /// weak      a    =           a          [weak a = a]
    /// weak                       a          [weak     a]
    public override func visit(_ node: ClosureCaptureItemSyntax) -> ClosureCaptureItemSyntax {
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
            expression: origin + offset + newOffset))

        offset += newOffset

        return node
            .withName(name.withoutTrivia())
            .withAssignToken(TokenSyntax.equalToken(leadingTrivia: .space, trailingTrivia: .space))
    }
}
