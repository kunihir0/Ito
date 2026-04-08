import Foundation

@MainActor
public class PluginResolver {
    public static let shared = PluginResolver()

    // Static Fallback Bridge: Map Aidoku/Tachiyomi known legacy IDs to updated semantic bases
    private let migrationAliases: [String: String] = [
        "mangasee": "mangasee123",
        "manganato": "manganato",
        "bato": "bato" // Expandable for explicit rebrand mappings
    ]

    private init() {}

    /// Normalizes a foreign extension ID (like "en.mangadex" or "all.mangasee") to Ito's format through a mathematical confidence architecture
    public func resolve(foreignId: String) -> String {
        // Step 1: Component & Language Extraction
        let components = foreignId.split(separator: ".")
        var langTag: String?
        var baseNameRaw = foreignId

        if components.count > 1 {
            // Usually [language].[namespace]
            langTag = String(components.first!).lowercased()
            baseNameRaw = String(components.last!)
        } else if components.count == 1 {
            baseNameRaw = String(components.first!)
        }

        // Strip suffixes like "-v2" or space versions to uncover pure extension semantic
        let cleanedBase = baseNameRaw.replacingOccurrences(of: "-v[0-9]+", with: "", options: .regularExpression)
                                     .lowercased()

        // Proxy through Static Alias Dictionary
        let targetName = migrationAliases[cleanedBase] ?? cleanedBase

        // Step 2: Confidence Scoring Engine
        var bestMatchId: String?
        var highestScore = 0

        for repo in RepoManager.shared.repositories {
            guard let packages = repo.index?.packages else { continue }

            for package in packages {
                var score = 0
                let pkgId = package.id.lowercased()
                let pkgName = package.name.lowercased()

                // -- Mathematical Substring Confidence --
                if pkgId.hasSuffix(".\(targetName)") {
                    score += 50 // Explicit isolation guarantees we don't bleed into .readcomiconline
                }

                if pkgName == targetName {
                    score += 40
                } else if pkgId.contains(targetName) {
                    score += 10 // Safe wildcard fallback
                }

                // -- Linguistic Integration Confidence --
                // Prevent Spanish plugins from stealing English ones by awarding massive spikes to language correlation
                if let tag = langTag, tag != "all" && tag != "any" {
                    if pkgId.hasSuffix(".\(tag)") || pkgId.contains(".\(tag).") {
                        score += 30
                    } else if pkgName.contains("(\(tag))") || pkgName.contains("[\(tag)]") || pkgName.contains("-\(tag)") {
                        score += 30
                    }
                }

                // Persist the highest mathematical evaluation
                if score > highestScore {
                    highestScore = score
                    bestMatchId = package.id
                }
            }
        }

        // Step 3: Target Validation
        if let match = bestMatchId, highestScore > 0 {
            return match
        }

        // Step 4: System Fallback (If repo package isn't installed natively yet)
        return "moe.itoapp.ito.\(targetName)"
    }
}
