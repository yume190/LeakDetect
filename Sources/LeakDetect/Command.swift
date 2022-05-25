//
//  main.swift
//  LeakDetect
//
//  Created by Yume on 2022/05/19.
//

import Foundation
import ArgumentParser
import SourceKittenFramework
import LeakDetectKit
import Cursor
import Rainbow

struct Command: AsyncParsableCommand {
    static var configuration: CommandConfiguration = CommandConfiguration(
        // commandName: "xcode",
        abstract: "A Tool to Detect Potential Leaks",
        discussion: """
        \(Env.discussion)

        Mode:
        * assign: detecting assign instance function `x = self.func` or `y(self.func)`.
        * capture: detecting capture instance in closure.
        """,
        version: "0.0.1"
    )
   
    @Flag(name: [.customLong("verbose", withSingleDash: false), .short], help: "print inpect time")
    var verbose: Bool = false
   
    @Option(name: [.customLong("mode", withSingleDash: false)], help: "[\(Mode.all)]")
    var mode: Mode = .assign
   
    @Option(name: [.customLong("reporter", withSingleDash: false)], help: "[\(Mode.all)]")
    var reporter: Reporter = .vscode
   
    typealias LeakCount = Int
   
    private func prepare() async -> (String, String, [String]) {
        return await withCheckedContinuation { continuation in
            Env.prepare { (projectRoot: String, moduleName: String, args: [String]) in
                continuation.resume(returning: (projectRoot, moduleName, args))
            }
        }
    }
    
    func run() async throws {
//        projectRoot
        let (_, moduleName, args) = await prepare()
        let module: Module = Module(name: moduleName, compilerArguments: args)
       
        switch mode {
        case .assign:
            try await assign(module)
            break
        case .capture:
            try await capture(module)
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
    private func capture(_ module: Module) async throws {
        var leakCount: LeakCount = 0
        defer { summery(leakCount) }
        
        let files: [File<DeclsVisitor>] = try await module.walk()
        
        let all: Int = module.sourceFiles.count
        for (index, file) in files.sorted().enumerated() {
            print("\("[SCAN FILE]:".applyingCodes(Color.yellow, Style.bold)) [\(index + 1)/\(all)] \(file.filePath)")
            leakCount += try file.detect(reporter, verbose)
        }
    }
}

extension Command {
    private func assign(_ module: Module) async throws {
        var leakCount: LeakCount = 0
        defer { summery(leakCount) }
        
        let files: [File<AssignClosureVisitor>] = try await module.walk()
        
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
