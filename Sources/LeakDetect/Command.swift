//
//  main.swift
//  LeakDetect
//
//  Created by Yume on 2022/05/19.
//

import ArgumentParser
import Foundation
import LeakDetectKit
import Rainbow
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
    version: "0.0.6"
  )

  @Flag(name: [.customLong("verbose", withSingleDash: false), .short], help: "verbose")
  var verbose: Bool = false

  @Option(name: [.customLong("reporter", withSingleDash: false)], help: "[\(Reporter.all)]")
  var reporter: Reporter = .vscode

  @Flag(name: [.customLong("github", withSingleDash: false), .short], help: "Is use github action")
  var github: Bool = false

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
    } else {
      return _base
    }
  }

  @Argument(help: "Arguments passed to `xcodebuild` or `swift build`")
  var arguments: [String] = []

  private var module: Module? {
    let moduleName = self.moduleName.isEmpty ? nil : self.moduleName

    switch targetType.detect(path) {
    case .spm:
      return Module(spmArguments: arguments, spmName: moduleName, inPath: path)
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
    case .custom where github:
      let githubAction = GithubAtionReporter(base: base)
      let reporter = Reporter.custom { [weak githubAction] location, _ in
        githubAction?.add(location)
      }
      return (reporter, githubAction)
    case .xcode: fallthrough
    case .vscode: fallthrough
    case .custom :
      return (reporter, nil)
    }
  }

  mutating func run() async throws {
    let (reporter, githubAction) = newReporter()

    if case .singleFile = targetType.detect(path) {
      let results = try Pipeline(path, arguments + [path] + sdk.args)
        .detect()
      report(reporter, results)

      try await githubAction?.call()
      summery(results.count)
      return
    }

    guard let module = module else {
      print("Can't create module")
      return
    }

    let results = try Pipeline.parse(module)
    let count = try report(reporter, results)
    try await githubAction?.call()
    summery(count)
  }

  private func report(
    _ reporter: Reporter,
    _ results: [(index: Int, filePath: String, pipeline: Pipeline)]
  ) throws -> Int {
    var leakCount = 0
    let all: Int = results.count
    for (index, filePath, pipeline) in results {
      if verbose {
        let title = "[SCAN \(index + 1)/\(all)]:".applyingCodes(Color.yellow, Style.bold)
        print("\(title) \(filePath)")
      }
      let results = try pipeline.detect()
      report(reporter, results)
      leakCount += results.count
    }

    return leakCount
  }

  private func report(
    _ reporter: Reporter,
    _ results: [LeakResult]
  ) {
    results.forEach { result in
      reporter.report(result)
      if verbose, !result.verbose.isEmpty {
        print(result.verbose)
      }
    }
  }
}

private func summery(_ leakCount: Int) {
  if leakCount == 0 {
    print("Congratulation no leak found".green)
  } else {
    print("Found \(leakCount) leaks".red)
  }
}
