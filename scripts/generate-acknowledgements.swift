#!/usr/bin/env swift

//
//  generate-acknowledgements.swift
//
//  Regenerates `Ice/Resources/Acknowledgements.rtf` and `.pdf` from the resolved
//  Swift package graph.
//
//  The bundled notices were hand-maintained and drifted: they listed LaunchAtLogin
//  years after it was dropped, and never gained DragonKit. Deriving the package list
//  from `Package.resolved` — and the licence bodies from each checkout's own LICENSE
//  file, copied verbatim — removes the step a human has to remember.
//
//  Only the PDF is copied into the app bundle. The RTF is the readable, diffable
//  source: it is excluded from the Ice target in the project file, and exists so a
//  reviewer can see what changed without opening a binary.
//
//  Usage:
//      scripts/generate-acknowledgements.swift [--checkouts <dir>]
//
//  `--checkouts` points at an SwiftPM checkouts directory. Without it, the newest
//  `~/Library/Developer/Xcode/DerivedData/Ice-*/SourcePackages/checkouts` holding
//  every resolved package is used, so a normal Xcode build is enough preparation.
//

import AppKit
import CoreText
import Foundation

// MARK: - Errors

struct GeneratorError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("error: \(message)\n".utf8))
    exit(1)
}

// MARK: - Locations

let repoRoot = URL(filePath: #filePath)
    .deletingLastPathComponent() // scripts/
    .deletingLastPathComponent() // repository root

let resolvedURL = repoRoot.appending(
    path: "Ice.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
)
let resourcesDir = repoRoot.appending(path: "Ice/Resources")

// MARK: - Resolved package graph

struct ResolvedFile: Decodable {
    struct Pin: Decodable {
        let identity: String
        let location: String
    }

    let pins: [Pin]
}

/// `Package.resolved` records repository names. Only DragonKit is known by a name
/// other than its repository's, so the rest fall through unchanged.
let displayNames = ["dragon-kit": "DragonKit"]

struct Package {
    let displayName: String
    let repoName: String
    let url: String
}

guard let resolvedData = try? Data(contentsOf: resolvedURL) else {
    fail("could not read \(resolvedURL.path)")
}

guard let resolved = try? JSONDecoder().decode(ResolvedFile.self, from: resolvedData) else {
    fail("could not parse \(resolvedURL.lastPathComponent)")
}

let packages: [Package] = resolved.pins
    .map { pin in
        let repoName = URL(string: pin.location)?
            .deletingPathExtension()
            .lastPathComponent ?? pin.identity
        return Package(
            displayName: displayNames[repoName] ?? repoName,
            repoName: repoName,
            url: pin.location
        )
    }
    .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }

guard !packages.isEmpty else {
    fail("\(resolvedURL.lastPathComponent) resolved no packages")
}

// MARK: - Checkouts

func checkoutsDirectory(containing packages: [Package]) -> URL? {
    let arguments = CommandLine.arguments
    if let flag = arguments.firstIndex(of: "--checkouts"), arguments.indices.contains(flag + 1) {
        return URL(filePath: arguments[flag + 1])
    }

    let derivedData = URL.homeDirectory.appending(path: "Library/Developer/Xcode/DerivedData")
    let entries = (try? FileManager.default.contentsOfDirectory(
        at: derivedData,
        includingPropertiesForKeys: [.contentModificationDateKey]
    )) ?? []

    return entries
        .filter { $0.lastPathComponent.hasPrefix("Ice-") }
        .sorted { lhs, rhs in
            let lhsDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let rhsDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return lhsDate > rhsDate
        }
        .map { $0.appending(path: "SourcePackages/checkouts") }
        .first { directory in
            packages.allSatisfy {
                FileManager.default.fileExists(atPath: directory.appending(path: $0.repoName).path)
            }
        }
}

guard let checkouts = checkoutsDirectory(containing: packages) else {
    fail("""
        no SwiftPM checkouts directory holds all \(packages.count) resolved packages. \
        Build the Ice scheme in Xcode once to fetch them, or pass --checkouts <dir>.
        """)
}

/// A package's licence text, copied verbatim. MIT requires the notice be reproduced
/// in full, so nothing here reformats, truncates or summarises the file.
func licenseText(for package: Package) -> String {
    let directory = checkouts.appending(path: package.repoName)
    let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
    let candidates = names
        .filter { $0.lowercased().hasPrefix("license") || $0.lowercased().hasPrefix("licence") }
        .sorted()

    guard let name = candidates.first else {
        fail("\(package.displayName) has no LICENSE file in \(directory.path)")
    }

    guard let text = try? String(contentsOf: directory.appending(path: name), encoding: .utf8) else {
        fail("could not read \(package.displayName)'s \(name)")
    }

    return text.trimmingCharacters(in: .whitespacesAndNewlines)
}

// MARK: - Document

// Helvetica rather than the system font: the RTF and PDF are read outside the app,
// and a resolved face travels better than `.AppleSystemUIFont`. Colours are fixed to
// black for the same reason — a dynamic colour would render white in dark mode.
let titleFont = NSFont(name: "Helvetica-Bold", size: 24) ?? .boldSystemFont(ofSize: 24)
let headingFont = NSFont(name: "Helvetica-Bold", size: 13) ?? .boldSystemFont(ofSize: 13)
let introFont = NSFont(name: "Helvetica", size: 11) ?? .systemFont(ofSize: 11)
let bodyFont = NSFont(name: "Helvetica", size: 9.5) ?? .systemFont(ofSize: 9.5)

func paragraphStyle(spacingBefore: CGFloat, spacingAfter: CGFloat) -> NSParagraphStyle {
    let style = NSMutableParagraphStyle()
    style.paragraphSpacingBefore = spacingBefore
    style.paragraphSpacing = spacingAfter
    style.lineHeightMultiple = 1.15
    return style
}

let document = NSMutableAttributedString()

func append(_ text: String, font: NSFont, spacingBefore: CGFloat = 0, spacingAfter: CGFloat = 0) {
    document.append(NSAttributedString(
        string: text + "\n",
        attributes: [
            .font: font,
            .foregroundColor: NSColor.black,
            .paragraphStyle: paragraphStyle(spacingBefore: spacingBefore, spacingAfter: spacingAfter),
        ]
    ))
}

append("Acknowledgements", font: titleFont, spacingAfter: 10)
append(
    """
    Ice 2 uses a number of excellent open source libraries. Their licenses and copyright \
    notices are reproduced in full below.
    """,
    font: introFont,
    spacingAfter: 6
)
append(
    """
    Ice 2 itself is released under the GNU General Public License v3.0, inherited from the \
    original Ice by Jordan Baird.
    """,
    font: introFont
)

for package in packages {
    append("\(package.displayName) — \(package.url)", font: headingFont, spacingBefore: 22, spacingAfter: 6)
    // LICENSE files are hard-wrapped, so every wrapped line is its own paragraph here.
    // Any `spacingAfter` would land between all of them rather than between packages —
    // the gap before the next package comes from the heading's `spacingBefore` instead.
    append(licenseText(for: package), font: bodyFont)
}

// MARK: - Output

let fullRange = NSRange(location: 0, length: document.length)

guard let rtf = document.rtf(from: fullRange, documentAttributes: [
    .documentType: NSAttributedString.DocumentType.rtf,
]) else {
    fail("could not encode the document as RTF")
}

do {
    try rtf.write(to: resourcesDir.appending(path: "Acknowledgements.rtf"))
} catch {
    fail("could not write Acknowledgements.rtf: \(error.localizedDescription)")
}

// US Letter with one-inch margins, paginated by CoreText so the whole document is
// reachable — an NSTextView snapshot would silently stop after the first page.
let pdfData = NSMutableData()
var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
let textRect = mediaBox.insetBy(dx: 72, dy: 72)

guard
    let consumer = CGDataConsumer(data: pdfData),
    let context = CGContext(consumer: consumer, mediaBox: &mediaBox, [
        kCGPDFContextTitle: "Ice 2 Acknowledgements" as CFString,
        kCGPDFContextCreator: "generate-acknowledgements.swift" as CFString,
    ] as CFDictionary)
else {
    fail("could not open a PDF context")
}

let framesetter = CTFramesetterCreateWithAttributedString(document)
var offset = 0
var pages = 0

while offset < document.length {
    context.beginPDFPage(nil)
    context.textMatrix = .identity

    let frame = CTFramesetterCreateFrame(
        framesetter,
        CFRange(location: offset, length: 0),
        CGPath(rect: textRect, transform: nil),
        nil
    )
    CTFrameDraw(frame, context)

    let consumed = CTFrameGetVisibleStringRange(frame).length
    context.endPDFPage()
    pages += 1

    guard consumed > 0 else {
        fail("pagination stalled at character \(offset) — the text box is too small to fit a line")
    }
    offset += consumed
}

context.closePDF()

do {
    try pdfData.write(to: resourcesDir.appending(path: "Acknowledgements.pdf"))
} catch {
    fail("could not write Acknowledgements.pdf: \(error.localizedDescription)")
}

print("Wrote Acknowledgements.rtf and .pdf — \(packages.count) packages, \(pages) pages")
print("  " + packages.map(\.displayName).joined(separator: ", "))
