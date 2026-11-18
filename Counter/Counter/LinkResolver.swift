import Foundation

enum VideoInputMode: String, CaseIterable { case link = "Link", embedded = "Embedded video" }

enum LinkError: LocalizedError {
    case invalidURL, invalidEmbed
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Enter a valid HTTP or HTTPS video, website, or embed link."
        case .invalidEmbed: return "Paste iframe or video embed code with an HTTP or HTTPS src, or paste the embed URL directly."
        }
    }
}

protocol LinkResolving {
    func resolve(_ input: String) throws -> URL
    func isDirectVideo(_ url: URL) -> Bool
}

struct LinkResolver: LinkResolving {
    func resolve(_ input: String) throws -> URL {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = trimmed.hasPrefix("<") ? try embeddedSource(in: trimmed) : trimmed
        let candidate = source.hasPrefix("//") ? "https:" + source : (source.contains("://") ? source : "https://" + source)
        guard !source.isEmpty, !source.contains(where: { $0.isWhitespace }),
              let url = URL(string: candidate),
              ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
              let host = url.host, !host.isEmpty,
              url.user == nil, url.password == nil else { throw LinkError.invalidURL }
        return url
    }
    private func embeddedSource(in html: String) throws -> String {
        guard html.utf8.count <= 65536 else { throw LinkError.invalidEmbed }
        // Extract a player URL; never render supplied markup, handlers, or scripts.
        let tags = try NSRegularExpression(pattern: #"(?is)<(?:iframe|video|source|embed)\b((?:"[^"]*"|'[^']*'|[^'">])*)>"#)
        let source = try NSRegularExpression(pattern: #"(?i)(?:^|\s)src\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'=<>`]+))"#)
        for match in tags.matches(in: html, range: NSRange(html.startIndex..., in: html)) {
            guard let attributes = Range(match.range(at: 1), in: html) else { continue }
            let text = String(html[attributes])
            guard let match = source.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                  let value = (1...3).compactMap({ Range(match.range(at: $0), in: text) }).first else { continue }
            return decodeEntities(String(text[value])).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        throw LinkError.invalidEmbed
    }

    private func decodeEntities(_ text: String) -> String {
        let pattern = try! NSRegularExpression(pattern: #"&(#[xX][0-9a-fA-F]+|#[0-9]+|amp|quot|apos|lt|gt);"#)
        var result = text
        for match in pattern.matches(in: text, range: NSRange(text.startIndex..., in: text)).reversed() {
            guard let keyRange = Range(match.range(at: 1), in: text), let range = Range(match.range, in: result) else { continue }
            let key = String(text[keyRange])
            let named = ["amp": "&", "quot": "\"", "apos": "'", "lt": "<", "gt": ">"]
            let number = (key.hasPrefix("#x") || key.hasPrefix("#X")) ? UInt32(key.dropFirst(2), radix: 16) : (key.hasPrefix("#") ? UInt32(key.dropFirst()) : nil)
            if let value = named[key] ?? number.flatMap({ UnicodeScalar($0).map(String.init) }) { result.replaceSubrange(range, with: value) }
        }
        return result
    }

    func isDirectVideo(_ url: URL) -> Bool {
        ["mp4", "m4v", "mov", "m3u8"].contains(url.pathExtension.lowercased())
    }
}
