//
//  AboutSettingsPane.swift
//  Ice
//

import SwiftUI

struct AboutSettingsPane: View {
    @Environment(\.openURL) private var openURL

    private var acknowledgementsURL: URL {
        // swiftlint:disable:next force_unwrapping
        Bundle.main.url(forResource: "Acknowledgements", withExtension: "pdf")!
    }

    /// Primary link: the app's marketing page on dragonapp.com (SKILL.md §5A).
    private var websiteURL: URL {
        URL(string: "https://www.dragonapp.com/ice-2/")!
    }

    /// Support link goes straight to the GitHub issues page.
    private var issuesURL: URL {
        URL(string: "https://github.com/teddychan/ice-2/issues")!
    }

    var body: some View {
        IceForm {
            IceSection(options: .plain) {
                appIconAndCopyright
            }
            IceSection {
                linkRows
            }
            IceSection {
                creditRows
            }
        }
    }

    @ViewBuilder
    private var appIconAndCopyright: some View {
        VStack(spacing: 6) {
            if let nsImage = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 128, height: 128)
            }

            Text("Ice 2")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text("Version \(Constants.versionString)")
                .font(.callout)
                .foregroundStyle(.secondary)

            Text(Constants.copyrightString)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var linkRows: some View {
        LabeledContent {
            Link("dragonapp.com/ice-2", destination: websiteURL)
        } label: {
            Label("Website", systemImage: "globe")
        }

        LabeledContent {
            Link("teddychan/ice-2", destination: issuesURL)
        } label: {
            Label("Support on GitHub", systemImage: "lifepreserver")
        }

        Button {
            NSWorkspace.shared.open(acknowledgementsURL)
        } label: {
            Label("Acknowledgements", systemImage: "doc.text")
        }
    }

    @ViewBuilder
    private var creditRows: some View {
        LabeledContent("Created by") { Text("Teddy Chan") }
        LabeledContent("Original Ice") { Text("Jordan Baird") }
        LabeledContent("License") { Text("GPL-3.0") }
    }
}
