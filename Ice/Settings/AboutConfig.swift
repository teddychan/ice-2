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
                // Every THIRD-PARTY package Ice 2 links, as `name → licence`, and the one list a
                // reader sees without leaving the app. `AcknowledgementsTests` pins it to
                // `Package.resolved` and to the bundled notices: hand-maintained copies of this
                // list drift, which is how the notices came to name LaunchAtLogin years after it
                // was dropped.
                //
                // DragonKit is deliberately NOT here, though it is a resolved package and does
                // appear in both notice documents. The kit's `Attribution` is documented as "a
                // third-party thing an app bundles", and DragonKit is not third party — it is
                // Dragon App's own shared library, which is why `AboutContent.creditRows` emits
                // an unconditional `Built with → DragonKit vX.Y.Z` row for every app. Listing it
                // here as well printed it twice in Credits and made Ice 2 the only one of the
                // five apps that did: the sample app links DragonKit and DragonKitUpdates and
                // still attributes Sparkle alone, and clipmenu-2, spectacle-2 and
                // yahoo-keykey-2 all match it.
                //
                // The notice documents keep DragonKit, and must: MIT requires the notice to
                // travel with copies, and the Built-with row carries a version, not a licence.
                Attribution(name: "AXSwift", license: "MIT"),
                Attribution(name: "CompactSlider", license: "MIT"),
                Attribution(name: "Ifrit", license: "MIT"),
                Attribution(name: "Semaphore", license: "MIT"),
                Attribution(name: "Sparkle", license: "MIT"),
            ]
        )
    }
}
