import Foundation

enum LinkError: LocalizedError {
    case invalidURL
    var errorDescription: String? { "Enter a valid HTTP or HTTPS video or website link." }
}

protocol LinkResolving {
    func resolve(_ input: String) throws -> URL
    func isDirectVideo(_ url: URL) -> Bool
}

struct LinkResolver: LinkResolving {
    func resolve(_ input: String) throws -> URL {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidate = trimmed.contains("://") ? trimmed : "https://" + trimmed
        guard !trimmed.isEmpty, !trimmed.contains(where: { $0.isWhitespace }),
              let url = URL(string: candidate),
              ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
              let host = url.host, !host.isEmpty,
              url.user == nil, url.password == nil else { throw LinkError.invalidURL }
        return url
    }
    func isDirectVideo(_ url: URL) -> Bool {
        ["mp4", "m4v", "mov", "m3u8"].contains(url.pathExtension.lowercased())
    }
}
