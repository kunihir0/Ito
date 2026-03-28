import Foundation

extension String {
    /// Removes HTML tags and resolves common HTML entities to plain text.
    public nonisolated func strippingHTML() -> String {
        var result = self

        // Remove tags
        if let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: []) {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, range: range, withTemplate: "")
        }

        // Resolve basic entities
        let entities: [(String, String)] = [
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&#39;", "'"),
            ("&nbsp;", " "),
            ("<br>", "\n"),
            ("<br/>", "\n"),
            ("<br />", "\n")
        ]

        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
