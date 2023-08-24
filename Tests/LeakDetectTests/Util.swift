//
//  Util.swift
//  TypeFillTests
//
//  Created by Yume on 2021/10/21.
//

import Foundation
import SKClient

private let sourceFile: URL = URL(fileURLWithPath: #file)
    .deletingLastPathComponent()
    .appendingPathComponent("Resource")

func resource(file: String) -> String {
    return sourceFile.appendingPathComponent(file).path
}

@inline(__always)
func prepare(code: String, action: (SKClient) throws -> ()) throws {
    let client = SKClient(code: code)
    try prepare(client: client, action: action)
}

@inline(__always)
func prepare(client: SKClient, action: (SKClient) throws -> ()) throws {
    _ = try client.editorOpen()
    try action(client)
    _ = try client.editorClose()
}
