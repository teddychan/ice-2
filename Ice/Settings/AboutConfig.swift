//
//  AboutConfig.swift
//  Ice
//

import AppKit
import DragonKit

/// App-owned About content for Ice 2, rendered by DragonKit's ``AboutPane``.
///
/// Only Ice 2's own content lives here — the layout is owned by DragonKit. The version is
/// single-sourced from the bundle (``Constants/versionString``) and the copyright from the
/// bundle's `NSHumanReadableCopyright` (``Constants/copyrightString``).
enum AboutConfig {
    static var content: AboutContent {
        AboutContent(
            appName: Constants.displayName,
            versionString: DragonAbout.versionString(),
            copyright: Constants.copyrightString,
            links: [
                // Primary link: the app's marketing page on dragonapp.com.
                AboutLink(
                    title: "Website",
                    detail: "dragonapp.com/ice-2",
                    systemImage: "globe",
                    url: URL(string: "https://www.dragonapp.com/ice-2/")!
                ),
                // Support goes straight to the GitHub issues page.
                AboutLink(
                    title: "Support on GitHub",
                    detail: "teddychan/ice-2",
                    systemImage: "lifepreserver",
                    url: URL(string: "https://github.com/teddychan/ice-2/issues")!
                ),
            ],
            credits: [
                (label: "Created by", value: "Teddy Chan"),
                (label: "Original Ice", value: "Jordan Baird"),
                (label: "License", value: "GPL-3.0"),
            ],
            // Bundled acknowledgements document (opened via the About pane's button).
            acknowledgementsURL: Bundle.main.url(forResource: "Acknowledgements", withExtension: "pdf")
        )
    }
}
