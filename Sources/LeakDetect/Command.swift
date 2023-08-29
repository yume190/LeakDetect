//
//  main.swift
//  LeakDetect
//
//  Created by Yume on 2022/05/19.
//

import ArgumentParser
import Foundation
import LeakDetectKit
import SKClient
import SourceKittenFramework

struct Command: AsyncParsableCommand {
    static var configuration: CommandConfiguration = .init(
        abstract: "A Tool to Detect Potential Leaks",
        discussion: """
        # Example:
        git clone https://github.com/antranapp/LeakDetector
        cd LeakDetector

        leakDetect --module LeakDetectorDemo --file LeakDetectorDemo.xcworkspace
        """,
        version: "0.0.4"
    )

    @Flag(name: [.customLong("verbose", withSingleDash: false), .short], help: "verbose")
    var verbose: Bool = false

    @Option(name: [.customLong("reporter", withSingleDash: false)], help: "[\(Reporter.all)]")
    var reporter: Reporter = .vscode

    @Option(name: [.customLong("sdk", withSingleDash: false)], help: "[\(SDK.all)]")
    var sdk: SDK = .iphonesimulator

    @Option(name: [.customLong("targetType", withSingleDash: false)], help: "[\(TargetType.all)]")
    var targetType: TargetType = .auto

    @Option(name: [.customLong("module", withSingleDash: false)], help: "Name of Swift module to document (can't be used with `--targetType singleFile`)")
    var moduleName = ""

    @Option(name: [.customLong("file", withSingleDash: false)], help: "xxx.xcworkspace/xxx.xcodeproj/xxx.swift")
    var file: String
    var path: String {
        URL(fileURLWithPath: file).path
    }
    
    var base: String {
        let _base = path.removeSuffix(file)
        
        if _base.isEmpty {
            return URL(fileURLWithPath: file).deletingLastPathComponent().path
        }  else {
            return _base
        }
    }

    @Argument(help: "Arguments passed to `xcodebuild` or `swift build`")
    var arguments: [String] = []

    private var module: Module? {
        let moduleName = self.moduleName.isEmpty ? nil : self.moduleName
        
        switch targetType.detect(path) {
        case .spm:
            return Module(spmArguments: arguments, spmName: moduleName)
        case .singleFile:
            return nil
        case .xcodeproj:
            let newArgs: [String] = [
                "-project",
                path,
                "-scheme",
                self.moduleName,
            ]
            return Module(xcodeBuildArguments: arguments + newArgs, name: moduleName)
        case .xcworkspace:
            let newArgs: [String] = [
                "-workspace",
                path,
                "-scheme",
                self.moduleName,
            ]
            return Module(xcodeBuildArguments: arguments + newArgs, name: moduleName)
        case .auto:
            return nil
        }
    }
    
    private func newReporter() -> (Reporter, GithubAtionReporter?) {
        switch reporter {
        case .xcode: fallthrough
        case .vscode:
            return (reporter, nil)
        case .custom:
            let githubAction = GithubAtionReporter(base: base)
            let reporter = Reporter.custom { [weak githubAction] location, _ in
                githubAction?.add(location)
            }
            return (reporter, githubAction)
        }
    }
    
    mutating func run() async throws {
        
        let (reporter, githubAction) = newReporter()
        
        if case .singleFile = targetType.detect(path) {
            try SingleFilePipeline(path, arguments + [path] + sdk.pathArgs)
                .detect(reporter, verbose)
            
            try await githubAction?.call()
            return
        }
        
        guard let module = module else {
            print("Can't create module")
            return
        }

        try Pipeline.detect(module, reporter, verbose)
        try await githubAction?.call()
    }
}

extension String {
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
