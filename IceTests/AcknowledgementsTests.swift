//
//  AcknowledgementsTests.swift
//  IceTests
//

import Foundation
import PDFKit
import Testing
@testable import Ice_2

/// Pins the third-party notices Ice 2 ships.
///
/// These drifted silently: the bundled document named LaunchAtLogin long after the dependency
/// was dropped, and never gained DragonKit. Nothing in the app reads the document, so no
/// feature broke and nothing looked wrong — which is precisely why the contract is asserted
/// here rather than left to review.
///
/// Three descriptions of one fact have to agree: `Package.resolved` (what the project links),
/// ``AboutConfig`` `.attributions` (what the About pane claims), and the bundled
/// `Acknowledgements.pdf` (what ships to satisfy MIT's "included in all copies"). Regenerate
/// the document with `scripts/generate-acknowledgements.swift` when this fails.
struct AcknowledgementsTests {
    // MARK: Sources of truth

    /// `Package.resolved` names repositories; DragonKit is the only package known by a
    /// different name. Mirrors the map in `scripts/generate-acknowledgements.swift`.
    private static let displayNames = ["dragon-kit": "DragonKit"]

    /// The checkout root, derived from this file's compile-time path. The test bundle cannot
    /// reach `Package.resolved` any other way — it is a project input, not a bundled resource.
    private static let repoRoot = URL(filePath: #filePath)
        .deletingLastPathComponent() // IceTests/
        .deletingLastPathComponent() // repository root

    private struct ResolvedFile: Decodable {
        struct Pin: Decodable {
            let location: String
        }

        let pins: [Pin]
    }

    /// Every package the project resolves, under the name the notices use.
    private func resolvedPackageNames() throws -> Set<String> {
        let url = Self.repoRoot.appending(
            path: "Ice.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
        )
        let data = try Data(contentsOf: url)
        let resolved = try JSONDecoder().decode(ResolvedFile.self, from: data)
        let names = resolved.pins.map { pin -> String in
            let repoName = URL(string: pin.location)?
                .deletingPathExtension()
                .lastPathComponent ?? pin.location
            return Self.displayNames[repoName] ?? repoName
        }
        return Set(names)
    }

    /// The text of the notices document that actually ships inside the app bundle.
    private func bundledNoticesText() throws -> String {
        let url = try #require(
            Bundle.main.url(forResource: "Acknowledgements", withExtension: "pdf"),
            "Acknowledgements.pdf is missing from the app bundle"
        )
        let document = try #require(PDFDocument(url: url), "Acknowledgements.pdf is not readable")
        return try #require(document.string, "Acknowledgements.pdf has no extractable text")
    }

    /// Splits the document at its `Name — https://…` headings into `name: body` pairs.
    private func sections(in text: String) -> [String: String] {
        var sections: [String: String] = [:]
        var current: String?
        var body = ""

        for line in text.components(separatedBy: .newlines) {
            if let separator = line.range(of: " — https://") {
                if let name = current {
                    sections[name] = body
                }
                current = String(line[line.startIndex..<separator.lowerBound])
                    .trimmingCharacters(in: .whitespaces)
                body = ""
            } else {
                body += line + "\n"
            }
        }

        if let name = current {
            sections[name] = body
        }
        return sections
    }

    // MARK: Tests

    @Test func bundledNoticesCoverExactlyTheResolvedPackages() throws {
        let resolved = try resolvedPackageNames()
        let documented = Set(sections(in: try bundledNoticesText()).keys)

        // Set equality both ways, so a package that is linked but undocumented fails just as
        // loudly as one that is documented but no longer linked — the LaunchAtLogin case.
        #expect(documented == resolved, """
            The bundled notices no longer match Package.resolved.
            Missing from the document: \(resolved.subtracting(documented).sorted())
            No longer linked: \(documented.subtracting(resolved).sorted())
            Regenerate with scripts/generate-acknowledgements.swift
            """)
    }

    /// The About pane attributes every resolved package EXCEPT DragonKit.
    ///
    /// The carve-out is not a wart, it is the kit's rule: `Attribution` is documented as "a
    /// third-party thing an app bundles", and DragonKit is Dragon App's own shared library, so
    /// `AboutContent.creditRows` already emits an unconditional `Built with → DragonKit vX.Y.Z`
    /// row for it. Attributing it as well printed DragonKit twice in Credits and made Ice 2 the
    /// only one of the five apps that did — the kit's own sample app links DragonKit and
    /// DragonKitUpdates and still attributes Sparkle alone.
    ///
    /// Subtracted HERE and not in `resolvedPackageNames()`, deliberately: the notice tests share
    /// that helper and DragonKit must stay in their expectation, because the bundled document and
    /// the hosted page are what satisfy MIT's "included in all copies" and the Built-with row
    /// carries a version rather than a licence.
    @Test func aboutPaneAttributionsCoverExactlyTheResolvedPackages() throws {
        let expected = try resolvedPackageNames().subtracting(["DragonKit"])
        let attributed = Set(AboutConfig.content.attributions.map(\.name))

        #expect(attributed == expected, """
            AboutConfig.attributions no longer match Package.resolved (minus DragonKit, which the
            kit credits in its own Built-with row).
            Missing from the About pane: \(expected.subtracting(attributed).sorted())
            No longer linked, or first-party: \(attributed.subtracting(expected).sorted())
            """)
    }

    @Test func everyNoticeReproducesItsLicenceInFull() throws {
        let sections = sections(in: try bundledNoticesText())

        // Asserted before the loop below, which would otherwise pass by iterating nothing.
        // `sections(in:)` recognises the heading format `generate-acknowledgements.swift`
        // writes; a document in any other shape parses as zero sections, and that must fail
        // here rather than read as "every notice checked out".
        #expect(!sections.isEmpty, "no package sections were found — the document format changed")
        #expect(sections.count == (try resolvedPackageNames()).count)

        // A heading alone would satisfy the set comparisons above while shipping none of the
        // text MIT requires be included, so each section is checked for the grant itself.
        for (name, body) in sections {
            #expect(body.contains("Permission is hereby granted"), "\(name)'s notice has no licence grant")
            #expect(body.contains("Copyright"), "\(name)'s notice has no copyright line")
        }
    }

    @Test func noticesDoNotNameDroppedDependencies() throws {
        // The specific regression this suite exists for.
        #expect(!(try bundledNoticesText()).contains("LaunchAtLogin"))
    }

    @Test func aboutPaneLinksTheHostedNotices() {
        // The bundle carries the notices and the About pane links the hosted copy; the kit
        // treats `licensesURL` as optional, so its absence would be silent.
        #expect(AboutConfig.content.licensesURL?.absoluteString == "https://www.dragonapp.com/ice-2/licenses/")
    }

    @Test func onlyThePdfIsBundled() {
        // The RTF is the reviewable source for the PDF and is deliberately excluded from the
        // Ice target, so the app does not ship two copies of the same notices.
        #expect(Bundle.main.url(forResource: "Acknowledgements", withExtension: "rtf") == nil)
    }
}
