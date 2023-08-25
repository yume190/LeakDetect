//
//  File.swift
//
//
//  Created by Yume on 2023/8/24.
//

import Foundation
import PathKit
import Rainbow
import SKClient
import SourceKittenFramework
import SwiftSyntaxParser

fileprivate struct Visitors {
    let assign = AssignClosureVisitor(viewMode: .sourceAccurate)
    let capture = DeclsVisitor(viewMode: .sourceAccurate)
    
    func detect(
        _ client: SKClient,
        _ reporter: Reporter,
        _ isVerbose: Bool
    ) throws -> Int {
        return try
            assign.detectCount(client, reporter, isVerbose) +
            capture.detectCount(client, reporter, isVerbose)
    }
}

fileprivate func summery(_ leakCount: Int) {
    if leakCount == 0 {
        print("Congratulation no leak found".green)
    } else {
        print("Found \(leakCount) leaks".red)
    }
}

public struct SingleFilePipeline {
    public let filePath: String
    public let arguments: [String]
    public init(_ filePath: String, _ arguments: [String]) {
        self.filePath = filePath
        self.arguments = arguments
    }
    
    /// change code
    private func stage1() throws -> SKClient {
        let path = Path(filePath)
        let code = try path.read(.utf8)
        let source = try SyntaxParser.parse(source: code)
        let rewriter = CaptureListRewriter()
        let newSource = rewriter.visit(source)
        let newCode = newSource.description
        
        let client = SKClient(path: filePath, code: newCode, arguments: arguments)
        return client
    }
    
    /// visit all potential leaks
    private func state2(_ client: SKClient) -> Visitors {
        let visitors = Visitors()
        visitors.assign.walk(client.sourceFile)
        visitors.capture.customWalk(client.sourceFile)
        return visitors
    }
    
    public func detect(_ reporter: Reporter, _ isVerbose: Bool) throws {
        let client = try stage1()
        let visitors = state2(client)
        try client.editorOpen()
        let count = try visitors.detect(client, reporter, isVerbose)
        try client.editorClose()
        summery(count)
    }
}

public struct Pipeline {
    public let filePath: String
    public let module: Module
    init(_ filePath: String, _ module: Module) {
        self.filePath = filePath
        self.module = module
    }
    
    /// change code
    private func stage1() throws -> SKClient {
        let path = Path(filePath)
        let code = try path.read(.utf8)
        let source = try SyntaxParser.parse(source: code)
        let rewriter = CaptureListRewriter()
        let newSource = rewriter.visit(source)
        let newCode = newSource.description
        
        let client = SKClient(path: filePath, code: newCode, arguments: module.compilerArguments)
        return client
    }
    
    /// visit all potential leaks
    private func state2(_ client: SKClient) -> Visitors {
        let visitors = Visitors()
        visitors.assign.walk(client.sourceFile)
        visitors.capture.customWalk(client.sourceFile)
        return visitors
    }
    
    private func detect(_ reporter: Reporter, _ isVerbose: Bool) throws -> Int {
        let client = try stage1()
        let visitors = state2(client)
        try client.editorOpen()
        let count = try visitors.detect(client, reporter, isVerbose)
        try client.editorClose()
        return count
    }
    
    public static func detect(
        _ module: Module,
        _ reporter: Reporter,
        _ isVerbose: Bool
    ) throws {
        var leakCount = 0
        defer { summery(leakCount) }
        let all: Int = module.sourceFiles.count
        for (index, filePath) in module.sourceFiles.sorted().enumerated() {
            if isVerbose {
                let title = "[SCAN \(index + 1)/\(all)]:".applyingCodes(Color.yellow, Style.bold)
                print("\(title) \(filePath)")
            }
            let pipeline = Pipeline(filePath, module)
            leakCount += try pipeline.detect(reporter, isVerbose)
        }
    }
    
    
}
