//
//  AboutConfig.swift
//  Ice
//

import DragonKit
import Foundation

/// Ice 2's content for DragonKit's shared About pane.
///
/// The kit owns every row title, SF Symbol, ordering and detail string — ``AboutContent``
/// assembles them and ``AboutPane`` renders them. Ice 2 supplies only URLs and proper nouns.
/// This used to pass free-form `links`/`credits` arrays; five apps used them to ship five
/// visibly different panes, so DragonKit 3.0.0 replaced them with fixed slots.
///
/// The version is single-sourced from the bundle via ``DragonAbout/versionString(bundle:)`` —
/// never hardcoded.
enum AboutConfig {
    /// The canonical marketing page. The kit's `websiteMatchesSupportRepo` checks this path
    /// against the support URL's repo name, so it must be `/ice-2/`, not the bare hub.
    private static let websiteURL = URL(string: "https://www.dragonapp.com/ice-2/")!

    /// Support goes straight to the GitHub issues page.
    private static let issuesURL = URL(string: "https://github.com/teddychan/ice-2/issues")!

    static var content: AboutContent {
        AboutContent(
            appName: Constants.displayName,
            versionString: DragonAbout.versionString(),
            // Assembled by the kit so the format matches every other Dragon app. Ice 2 was the
            // app that spelled out "Copyright ©" where the others used the symbol alone; the
            // years and holders are unchanged from `NSHumanReadableCopyright`.
            copyright: DragonAbout.copyright(
                original: (years: "2025", holder: "Jordan Baird"),
                years: "2026",
                holder: "Teddy Chan"
            ),
            websiteURL: websiteURL,
            supportURL: issuesURL,
            license: "GPL-3.0",
            // Third-party notices: the verbatim MIT text for the six packages below. Trailing
            // slash: it is the path Pages serves, so the row does not point at a redirect. This
            // replaces the row that opened `Resources/Acknowledgements.pdf` before DragonKit
            // 3.0.0 removed `acknowledgementsURL` — the slot stayed empty rather than take a
            // `file://` URL, because the kit derives a row's link text from its URL and would
            // have rendered the PDF's absolute filesystem path.
            //
            // The bundle still carries the same notices as a document, generated alongside this
            // list by `scripts/generate-acknowledgements.swift`. The kit's own doc comment calls
            // hosting them on the site *instead* a weaker reading of MIT's "included in all
            // copies"; shipping both settles that, and this row stays because a web page is the
            // more readable copy.
            licensesURL: URL(string: "https://www.dragonapp.com/ice-2/licenses/")!,
            originalWork: OriginalWork(name: "Ice", author: "Jordan Baird"),
            attributions: [
                // Every third-party package Ice 2 links, as `name → licence`, and the one list
                // a reader sees without leaving the app. `AcknowledgementsTests` pins it to
                // `Package.resolved` and to the bundled notices: hand-maintained copies of this
                // list drift, which is how the notices came to name LaunchAtLogin years after
                // it was dropped, and to omit DragonKit entirely.
                Attribution(name: "AXSwift", license: "MIT"),
                Attribution(name: "CompactSlider", license: "MIT"),
                Attribution(name: "DragonKit", license: "MIT"),
                Attribution(name: "Ifrit", license: "MIT"),
                Attribution(name: "Semaphore", license: "MIT"),
                Attribution(name: "Sparkle", license: "MIT"),
            ]
        )
    }
}
