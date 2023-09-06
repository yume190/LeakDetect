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

struct Visitors {
    let assign: AssignClosureVisitor
    let capture: DeclsVisitor
    
    init(_ client: SKClient, _ rewriter: CaptureListRewriter) {
        self.assign = AssignClosureVisitor(client: client)
        self.capture = DeclsVisitor(client: client, rewriter)
    }
    
    func detect() throws -> [LeakResult] {
        return try
            assign.detect() +
            capture.detect()
    }
}

public struct SingleFilePipeline {
    public let filePath: String
    public let code: String
    public let arguments: [String]
    public init(_ filePath: String, _ arguments: [String])  throws {
        self.filePath = filePath
        self.arguments = arguments
        
        let path = Path(filePath)
        self.code = try path.read(.utf8)
    }
    
    public init(_ filePath: String, _ code: String, _ arguments: [String])  {
        self.filePath = filePath
        self.code = code
        self.arguments = arguments
    }
    
    /// change code
    private func stage1() throws -> (SKClient, CaptureListRewriter) {
        let source = try SyntaxParser.parse(source: code)
        let rewriter = CaptureListRewriter()
        let newSource = rewriter.visit(source)
        let newCode = newSource.description
        let client = SKClient(path: filePath, code: newCode, arguments: arguments)
        return (client, rewriter)
    }
    
    /// visit all potential leaks
    private func state2(_ client: SKClient, _ rewriter: CaptureListRewriter) -> Visitors {
        let visitors = Visitors(client, rewriter)
        visitors.assign.walk(client.sourceFile)
        visitors.capture.customWalk(client.sourceFile)
        return visitors
    }
    
    @discardableResult
    public func detect(
      _ reporter: Reporter,
      _ isVerbose: Bool
    ) throws -> [LeakResult] {
        let (client, rewriter) = try stage1()
        try client.editorOpen()
        
        let visitors = state2(client, rewriter)
        let results = try visitors.detect()
        
        try client.editorClose()
      
        results.forEach { result in
            reporter.report(result)
            if isVerbose, !result.verbose.isEmpty {
                print(result.verbose)
            }
        }
        return results
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
    private func stage1() throws -> (SKClient, CaptureListRewriter) {
        let path = Path(filePath)
        let code = try path.read(.utf8)
        let source = try SyntaxParser.parse(source: code)
        let rewriter = CaptureListRewriter()
        let newSource = rewriter.visit(source)
        let newCode = newSource.description
        
        let client = SKClient(path: filePath, code: newCode, arguments: module.compilerArguments)
        return (client, rewriter)
    }
    
    /// visit all potential leaks
    private func state2(_ client: SKClient, _ rewriter: CaptureListRewriter) -> Visitors {
        let visitors = Visitors(client, rewriter)
        visitors.assign.walk(client.sourceFile)
        visitors.capture.customWalk(client.sourceFile)
        return visitors
    }
    
    private func detect() throws -> [LeakResult] {
        let (client, rewriter) = try stage1()
        try client.editorOpen()
        
        let visitors = state2(client, rewriter)
        let results = try visitors.detect()
        
        try client.editorClose()
        return results
    }
    
    @discardableResult
    public static func detect(
        _ module: Module,
        _ reporter: Reporter,
        _ isVerbose: Bool
    ) throws -> Int {
        var leakCount = 0
        let all: Int = module.sourceFiles.count
        for (index, filePath) in module.sourceFiles.sorted().enumerated() {
            if isVerbose {
                let title = "[SCAN \(index + 1)/\(all)]:".applyingCodes(Color.yellow, Style.bold)
                print("\(title) \(filePath)")
            }
            let pipeline = Pipeline(filePath, module)
            let results = try pipeline.detect()
            results.forEach { result in
                reporter.report(result)
                if isVerbose, !result.verbose.isEmpty {
                    print(result.verbose)
                }
            }
            leakCount += results.count
        }
        return leakCount
    }   
}
