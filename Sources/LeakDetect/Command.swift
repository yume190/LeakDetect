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
        export PROJECT_PATH=LeakDetectorDemo.xcworkspace
        export TARGET_NAME=LeakDetectorDemo
        leakDetect --mode capture

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
    
    @Argument
    var paths: [String] = []
   
    typealias LeakCount = Int
   
    private func prepare() async -> (String, String, [String]) {
        return await withCheckedContinuation { continuation in
            Env.prepare { (projectRoot: String, moduleName: String, args: [String]) in
                continuation.resume(returning: (projectRoot, moduleName, args))
            }
        }
    }
    
    mutating func run() throws {
        try Env.prepare { (_: String, moduleName: String, args: [String]) in
            let module = Module(name: moduleName, compilerArguments: args)
        
            switch mode {
            case .assign:
                try assign(module)
            case .capture:
                let root = (Path.current + (Env.projectPath.value ?? "")).parent()
                let scanFolders = paths.map { path in
                    (root + path).string
                }
                try capture(module, scanFolders)
            }
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

extension Array where Element == String {
    func prefixIn(_ full: String) -> Bool {
        let all = lazy.map {
            full.hasPrefix($0)
        }
        return all.reduce(false) { partialResult, next in
            partialResult || next
        }
    }
}

extension Command {
    private func capture(_ module: Module, _ scanFolder: [String]) throws {
        print("scanFolder: ", scanFolder)
        
        var leakCount: LeakCount = 0
        defer { summery(leakCount) }
        
        let files: [File<DeclsVisitor>] = try module.walk()
        
        let all: Int = module.sourceFiles.count
        for (index, file) in files.sorted().enumerated() {
            guard scanFolder.isEmpty || scanFolder.prefixIn(file.filePath) else {
                continue
            }
            
            print("\("[SCAN FILE]:".applyingCodes(Color.yellow, Style.bold)) [\(index + 1)/\(all)] \(file.filePath)")
            leakCount += try file.detect(reporter, verbose)
        }
    }
}

extension Command {
    private func assign(_ module: Module) throws {
        var leakCount: LeakCount = 0
        defer { summery(leakCount) }
        
        let files: [File<AssignClosureVisitor>] = try module.walk()
        
        let all: Int = module.sourceFiles.count
        for (index, file) in files.sorted().enumerated() {
            print("\("[SCAN FILE]:".applyingCodes(Color.yellow, Style.bold)) [\(index + 1)/\(all)] \(file.filePath)")
            leakCount += try file.detect(reporter, verbose)
        }
    }
}

extension Command {
    enum Mode: String, CaseIterable, ExpressibleByArgument {
        case assign
        case capture
       
        static let all: String = Mode
            .allCases
            .map(\.rawValue)
            .joined(separator: "|")
    }
}

extension Reporter: ExpressibleByArgument {
    static let all: String = Reporter
        .allCases
        .map(\.rawValue)
        .joined(separator: "|")
}
