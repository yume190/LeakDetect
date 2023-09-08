//
//  GithubAtionReporter.swift
//
//
//  Created by Yume on 2023/8/28.
//

import Foundation
import PathKit
import LeakDetectKit
import SKClient

/// [Context](https://docs.github.com/en/actions/learn-github-actions/contexts#github-context)
private enum GihubActionEnv: String {
    /// commit
    /// ${{github.event.after}}
    case sha
    /// "repository": "octocat/hello-world",
    case repository

    /// ${{ secrets.GITHUB_TOKEN }}
    case auth

    /// ${{ github.event.number }}
    case issue

    private static let processInfo: ProcessInfo = .init()

    public var value: String? {
        return Self.processInfo.environment[rawValue]
    }
}

class GithubAtionReporter {
    convenience init?(base: String) {
        guard let sha = GihubActionEnv.sha.value else { return nil }
        guard let repo = GihubActionEnv.repository.value else { return nil }
        guard let auth = GihubActionEnv.auth.value else { return nil }
        guard let issue = GihubActionEnv.issue.value else { return nil }

        self.init(base: base, repo: repo, sha: sha, issue: issue, auth: auth)
    }

    init(base: String, repo: String, sha: String, issue: String, auth: String) {
        self.base = base
        self.repo = repo
        self.sha = sha
        self.issue = issue
        self.auth = auth
    }

    let base: String
    private func rPath(_ code: CodeLocation) -> String {
        code.path
            .removePrefix(base)
            .removePrefix("/")
    }

    let repo: String
    let sha: String
    let issue: String

    let auth: String
    private(set) var codes: [LeakResult] = []
    func add(_ result: LeakResult) {
      let location = result.location
      if let line = location.location.line, let col = location.location.column {
          let path = rPath(location)
          print("""
          ::warning file=\(path),line=\(line),col=\(col)::\(result.reportReason)
          """)
        }
        codes.append(result)
    }

    /// base: https://github.com/
    /// repo: yume190/LeakDetect
    ///       blob
    /// sha:  9fb49184787fe2bfbd0802bf87xxxxx
    /// file: Sources/LeakDetect/Command.swift
    /// line: #L10-L20
    private func path(_ result: LeakResult) -> String {
        let code = result.location
        func lines(_ code: CodeLocation) -> String {
            guard let line = code.location.line else {
                return ""
            }

            let min = max(0, line - 2)
            let max = min + 4
            /// #L11-L15
            return "#L\(min)-L\(max)"
        }

        return """
        https://github.com/\(repo)/blob/\(sha)/\(rPath(code))\(lines(code))
        """
    }

    private func comment(_ result: LeakResult) -> String {
        let code = result.location
        return """
        
        \(path(result))

        > [!WARNING]
        > Line: \(code.location.line ?? -1)
        > Column: \(code.location.column ?? -1)
        > Target: \(result.targetName ?? "")
        > Reason: \(result.reason)
        """
    }

    private var comments: String {
        let res = codes.map(comment).joined(separator: "\n")
        return """
        <details>
        <summary>Found \(codes.count) potetial leaks.</summary>
        \(res)
        </details>
        """
    }

    /// https://docs.github.com/en/rest/issues/comments?apiVersion=2022-11-28#create-an-issue-comment
    func call() async throws {
        guard issue != "" else { return }
        
        let url = URL(string: "https://api.github.com/repos/\(repo)/issues/\(issue)/comments")!

        // Create the URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(auth)", forHTTPHeaderField: "Authorization")

        // Create a dictionary for the request body
        let requestBody: [String: Any] = [
            "body": "\(comments)",
        ]

        // Convert the dictionary to JSON data
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            request.httpBody = jsonData
        } catch {
            print("Error creating JSON data: \(error)")
        }


        _ = try await URLSession.shared.data(for: request)
    }
}
