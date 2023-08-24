//
//  main.swift
//  LeakDetect
//
//  Created by Yume on 2022/05/19.
//

import ArgumentParser
import Foundation
import LeakDetectKit
import PathKit
import Rainbow
import SKClient
import SourceKittenFramework

struct Command: ParsableCommand {
    static var configuration: CommandConfiguration = .init(
        abstract: "A Tool to Detect Potential Leaks",
        discussion: """
        Example:
        git clone https://github.com/antranapp/LeakDetector
        cd LeakDetector
        # Must build once
        xcodebuild -workspace LeakDetectorDemo.xcworkspace -scheme LeakDetectorDemo -sdk iphonesimulator IPHONEOS_DEPLOYMENT_TARGET=13.0 build
        
        leakDetect \
            --mode capture \
            --moduleName LeakDetectorDemo
            --targetType xcworkspace \
            --file LeakDetectorDemo.xcworkspace

        Mode:
        * assign: detecting assign instance function `x = self.func` or `y(self.func)`.
        * capture: detecting capture instance in closure.
        """,
        version: "0.0.3"
    )
    
    @Flag(name: [.customLong("verbose", withSingleDash: false), .short], help: "print inpect time")
    var verbose: Bool = false
   
    @Option(name: [.customLong("mode", withSingleDash: false)], help: "[\(Mode.all)]")
    var mode: Mode = .assign
   
    @Option(name: [.customLong("reporter", withSingleDash: false)], help: "[\(Reporter.all)]")
    var reporter: Reporter = .vscode
    
    @Option(name: [.customLong("sdk", withSingleDash: false)], help: "[\(SDK.all)]")
    var sdk: SDK = .iphonesimulator
    
    @Option(name: [.customLong("targetType", withSingleDash: false)], help: "[\(Reporter.all)]")
    var targetType: TargetType = .xcodeproj
    
    @Option(name: [.customLong("moduleName", withSingleDash: false)], help: "Name of Swift module to document (can't be used with `--single-file`)")
    var moduleName = ""
    
    @Option(name: [.customLong("file", withSingleDash: false)], help: "xcworkspace/xcproject/xxx.swift")
    var file: String
    
    @Argument(help: "Arguments passed to `xcodebuild` or `swift build`")
    var arguments: [String] = []
    
    
   
    typealias LeakCount = Int
   
    private var module: Module? {
        let moduleName = self.moduleName.isEmpty ? nil : self.moduleName

        switch targetType {
        case .spm:
            return Module(spmArguments: arguments, spmName: moduleName)
//        case .singleFile:
//            [targetFile.path] + sdk.pathArgs
//            return nil
        case .xcodeproj:
            let newArgs: [String] = [
                "-project",
                file,
                "-scheme",
                self.moduleName,
            ]
            
//            print(arguments + newArgs)
//            guard let setting = CompilerArguments.byFile(name: self.moduleName, arguments: arguments + newArgs) else {
//                print("no arg")
//                return nil
//            }
//            return Module(name: self.moduleName, compilerArguments: setting.default)
            return Module(xcodeBuildArguments: arguments + newArgs, name: moduleName)
        case .xcodeworkspace:
            let newArgs: [String] = [
                "-workspace",
                file,
                "-scheme",
                self.moduleName,
            ]
            return Module(xcodeBuildArguments: arguments + newArgs, name: moduleName)
        }
    }
    
    mutating func run() throws {
        guard let module = module else {
            print("Can't create module")
            return
        }
        
        switch mode {
        case .assign:
            try assign(module)
        case .capture:
            try capture(module) // , scanFolders)
        }
    }
    
    private func summery(_ leakCount: LeakCount) {
        if leakCount == 0 {
            print("Congratulation no leak found".green)
        } else {
            print("Found \(leakCount) leaks".red)
        }
    }
}

extension Command {
    private func capture(_ module: Module) throws {
        var leakCount: LeakCount = 0
        defer { summery(leakCount) }
        
        let files: [File<DeclsVisitor>] = try module.walkCapture()
        
        let all: Int = module.sourceFiles.count
        for (index, file) in files.sorted().enumerated() {
            print("\("[SCAN FILE]:".applyingCodes(Color.yellow, Style.bold)) [\(index + 1)/\(all)] \(file.filePath)")
            leakCount += try file.detect(reporter, verbose)
        }
    }
}

extension Command {
    private func assign(_ module: Module) throws {
        var leakCount: LeakCount = 0
        defer { summery(leakCount) }
        
        let files: [File<AssignClosureVisitor>] = try module.walkAssign()
        
        let all: Int = module.sourceFiles.count
        for (index, file) in files.sorted().enumerated() {
            print("\("[SCAN FILE]:".applyingCodes(Color.yellow, Style.bold)) [\(index + 1)/\(all)] \(file.filePath)")
            leakCount += try file.detect(reporter, verbose)
        }
    }
}
