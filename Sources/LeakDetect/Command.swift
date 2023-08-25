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

struct Command: ParsableCommand {
    static var configuration: CommandConfiguration = .init(
        abstract: "A Tool to Detect Potential Leaks",
        discussion: """
        # Example:
        git clone https://github.com/antranapp/LeakDetector
        cd LeakDetector

        leakDetect \
            --module LeakDetectorDemo \
            --targetType xcworkspace \
            --file LeakDetectorDemo.xcworkspace
        """,
        version: "0.0.3"
    )

    @Flag(name: [.customLong("verbose", withSingleDash: false), .short], help: "print inpect time")
    var verbose: Bool = false

    @Option(name: [.customLong("reporter", withSingleDash: false)], help: "[\(Reporter.all)]")
    var reporter: Reporter = .vscode

    @Option(name: [.customLong("sdk", withSingleDash: false)], help: "[\(SDK.all)]")
    var sdk: SDK = .iphonesimulator

    @Option(name: [.customLong("targetType", withSingleDash: false)], help: "[\(Reporter.all)]")
    var targetType: TargetType = .auto

    @Option(name: [.customLong("module", withSingleDash: false)], help: "Name of Swift module to document (can't be used with `--single-file`)")
    var moduleName = ""

    @Option(name: [.customLong("file", withSingleDash: false)], help: "xcworkspace/xcproject/xxx.swift")
    var file: String
    var path: String {
        URL(fileURLWithPath: file).path
    }
    

    @Argument(help: "Arguments passed to `xcodebuild` or `swift build`")
    var arguments: [String] = []

    typealias LeakCount = Int

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

    mutating func run() throws {
        if case .singleFile = targetType.detect(path) {
            try SingleFilePipeline(path, arguments + [path] + sdk.pathArgs)
                .detect(reporter, verbose)
            return
        }
        
        guard let module = module else {
            print("Can't create module")
            return
        }

        try Pipeline.detect(module, reporter, verbose)
    }
}
